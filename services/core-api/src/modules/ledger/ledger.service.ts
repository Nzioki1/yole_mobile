import { Injectable } from '@nestjs/common';
import { PrismaClient, JournalStatus } from '@prisma/client';
import {
  CurrencyCode,
  PostingInput,
  assertBalancedPostings,
} from './ledger.types';

export interface PostJournalInput {
  idempotencyKey: string;
  yoleReference: string;
  correlationId: string;
  actorType: 'customer' | 'agent' | 'admin' | 'system';
  actorId?: string;
  currency: CurrencyCode;
  postings: Array<PostingInput & { walletPocketId?: string }>;
}

export interface PostJournalResult {
  journalId: string;
  status: 'POSTED';
}

@Injectable()
export class LedgerService {
  private prisma: PrismaClient;

  constructor() {
    this.prisma = new PrismaClient();
  }

  /**
   * Post a journal entry with balanced postings to the ledger.
   * 
   * Convention: Customer-facing positive funds use liability accounting semantics:
   * - Credit to CUST_WALLET_* increases WalletPocket.ledgerMinor (customer sees more funds)
   * - Debit from CUST_WALLET_* decreases WalletPocket.ledgerMinor (customer sees less funds)
   * 
   * Available funds = ledgerMinor - blockedMinor - pendingOutMinor
   * Debits are rejected if they would make available funds negative.
   * 
   * Idempotent: Duplicate idempotencyKey returns the original journal without re-posting.
   * On concurrent/retry unique constraint, returns the existing journal.
   */
  async postJournal(input: PostJournalInput): Promise<PostJournalResult> {
    // Check for existing idempotency record (fast path)
    const existingRecord = await this.prisma.idempotencyRecord.findUnique({
      where: { key: input.idempotencyKey },
    });

    if (existingRecord) {
      const response = existingRecord.responseJson as any;
      return {
        journalId: response.journalId,
        status: 'POSTED',
      };
    }

    // Validate balanced postings
    assertBalancedPostings(input.postings);

    try {
      // Use transaction for atomicity (includes idempotency record)
      const result = await this.prisma.$transaction(async (tx) => {
        // Create journal entry
        const journal = await tx.journalEntry.create({
          data: {
            yoleReference: input.yoleReference,
            idempotencyKey: input.idempotencyKey,
            status: JournalStatus.POSTED,
            currency: input.currency,
            correlationId: input.correlationId,
            actorType: input.actorType,
            actorId: input.actorId,
            externalRefsJson: null,
          },
        });

        // Create postings and update wallet pockets
        for (const posting of input.postings) {
          // Create posting record
          await tx.posting.create({
            data: {
              journalId: journal.id,
              accountCode: posting.accountCode,
              direction: posting.direction,
              amountMinor: posting.amountMinor,
              currency: posting.currency,
              walletPocketId: posting.walletPocketId,
            },
          });

          // Update wallet pocket balance if specified
          if (posting.walletPocketId) {
            const pocket = await tx.walletPocket.findUnique({
              where: { id: posting.walletPocketId },
            });

            if (!pocket) {
              throw new Error(
                `Wallet pocket ${posting.walletPocketId} not found`,
              );
            }

            // Validate posting currency matches pocket currency
            if (posting.currency !== pocket.currency) {
              throw new Error(
                `Posting currency ${posting.currency} does not match pocket currency ${pocket.currency}`,
              );
            }

            let newLedgerMinor: bigint;

            if (posting.direction === 'debit') {
              // Debit decreases ledgerMinor (customer sends money out)
              newLedgerMinor = pocket.ledgerMinor - posting.amountMinor;

              // Check available funds: available = ledgerMinor - blockedMinor - pendingOutMinor
              const availableFunds =
                pocket.ledgerMinor -
                pocket.blockedMinor -
                pocket.pendingOutMinor;

              if (posting.amountMinor > availableFunds) {
                throw new Error(
                  `Insufficient available funds in pocket ${posting.walletPocketId}. ` +
                    `Available: ${availableFunds}, Required: ${posting.amountMinor}`,
                );
              }
            } else {
              // Credit increases ledgerMinor (customer receives money)
              newLedgerMinor = pocket.ledgerMinor + posting.amountMinor;
            }

            await tx.walletPocket.update({
              where: { id: posting.walletPocketId },
              data: { ledgerMinor: newLedgerMinor },
            });
          }
        }

        const response = { journalId: journal.id, status: 'POSTED' as const };

        // Persist idempotency record INSIDE transaction
        await tx.idempotencyRecord.create({
          data: {
            key: input.idempotencyKey,
            requestHash: JSON.stringify(input),
            responseJson: response,
          },
        });

        return response;
      });

      return result;
    } catch (error: any) {
      // Handle unique constraint violation (concurrent duplicate request)
      if (error.code === 'P2002') {
        // Prisma unique constraint error
        // Look up the existing journal and return it
        const existingJournal = await this.prisma.journalEntry.findUnique({
          where: { idempotencyKey: input.idempotencyKey },
        });

        if (existingJournal) {
          return {
            journalId: existingJournal.id,
            status: 'POSTED',
          };
        }

        // Check by yoleReference as fallback
        const journalByRef = await this.prisma.journalEntry.findUnique({
          where: { yoleReference: input.yoleReference },
        });

        if (journalByRef) {
          return {
            journalId: journalByRef.id,
            status: 'POSTED',
          };
        }
      }

      // Re-throw other errors
      throw error;
    }
  }

  async onModuleDestroy() {
    await this.prisma.$disconnect();
  }
}
