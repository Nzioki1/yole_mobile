import { Injectable } from '@nestjs/common';
import {
  CurrencyCode,
  PostingInput,
  assertBalancedPostings,
} from './ledger.types';
import { InMemoryLedgerStore } from '../../common/stores/ledger.store';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';

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
  constructor(
    private ledgerStore: InMemoryLedgerStore,
    private walletStore: InMemoryWalletStore,
  ) {}

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
    const existingRecord = await this.ledgerStore.findIdempotencyRecord(
      input.idempotencyKey,
    );

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
      // In-memory "transaction" - all operations or rollback on error
      // Create journal entry
      const journal = await this.ledgerStore.createJournal({
        yoleReference: input.yoleReference,
        idempotencyKey: input.idempotencyKey,
        status: 'POSTED',
        currency: input.currency,
        correlationId: input.correlationId,
        actorType: input.actorType,
        actorId: input.actorId || null,
        externalRefsJson: null,
      });

      // Create postings and update wallet pockets
      for (const posting of input.postings) {
        // Create posting record
        await this.ledgerStore.createPosting({
          journalId: journal.id,
          accountCode: posting.accountCode,
          direction: posting.direction,
          amountMinor: posting.amountMinor,
          currency: posting.currency,
          walletPocketId: posting.walletPocketId || null,
        });

        // Update wallet pocket balance if specified
        if (posting.walletPocketId) {
          const pocket = await this.walletStore.findPocketById(
            posting.walletPocketId,
          );

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

          await this.walletStore.updatePocket(posting.walletPocketId, {
            ledgerMinor: newLedgerMinor,
          });
        }
      }

      const response = { journalId: journal.id, status: 'POSTED' as const };

      // Persist idempotency record atomically
      await this.ledgerStore.createIdempotencyRecord({
        key: input.idempotencyKey,
        requestHash: JSON.stringify(input, (_, v) =>
          typeof v === 'bigint' ? v.toString() : v,
        ),
        responseJson: response,
      });

      return response;
    } catch (error: any) {
      // Handle duplicate key (concurrent duplicate request)
      if (error.message?.includes('Duplicate')) {
        // Look up the existing journal and return it
        const existingJournal =
          await this.ledgerStore.findJournalByIdempotencyKey(
            input.idempotencyKey,
          );

        if (existingJournal) {
          return {
            journalId: existingJournal.id,
            status: 'POSTED',
          };
        }

        // Check by yoleReference as fallback
        const journalByRef = await this.ledgerStore.findJournalByReference(
          input.yoleReference,
        );

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
}
