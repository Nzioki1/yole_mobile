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
   */
  async postJournal(input: PostJournalInput): Promise<PostJournalResult> {
    // Check for existing idempotency record
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

    // Use transaction for atomicity
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

      return { journalId: journal.id, status: 'POSTED' as const };
    });

    // Persist idempotency record
    await this.prisma.idempotencyRecord.create({
      data: {
        key: input.idempotencyKey,
        requestHash: JSON.stringify(input),
        responseJson: result,
      },
    });

    return result;
  }

  async onModuleDestroy() {
    await this.prisma.$disconnect();
  }
}
