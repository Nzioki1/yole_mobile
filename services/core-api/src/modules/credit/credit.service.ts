import { Injectable } from '@nestjs/common';
import { LedgerService } from '../ledger/ledger.service';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';
import { CurrencyCode } from '../../common/stores/types';

interface Loan {
  id: string;
  customerId: string;
  type: 'SALARY_ADVANCE' | 'CONSUMER_LOAN';
  principalMinor: bigint;
  interestRatePercent: number;
  termMonths: number;
  currency: CurrencyCode;
  status: string;
  disbursedAt?: Date;
  createdAt: Date;
}

@Injectable()
export class CreditService {
  private loans = new Map<string, Loan>();
  private loanIdCounter = 1;

  constructor(
    private ledgerService: LedgerService,
    private walletStore: InMemoryWalletStore,
  ) {}

  /**
   * Check eligibility (stub - always returns eligible)
   */
  async checkEligibility(customerId: string, type: 'SALARY_ADVANCE' | 'CONSUMER_LOAN') {
    return {
      eligible: true,
      maxAmountMinor: '50000',
      reason: 'Mock eligibility check',
    };
  }

  /**
   * Request loan with immediate wallet credit
   */
  async requestLoan(input: {
    customerId: string;
    type: 'SALARY_ADVANCE' | 'CONSUMER_LOAN';
    principalMinor: bigint;
    currency: CurrencyCode;
    termMonths: number;
  }) {
    // Create loan record
    const loan: Loan = {
      id: `loan_${this.loanIdCounter++}`,
      customerId: input.customerId,
      type: input.type,
      principalMinor: input.principalMinor,
      interestRatePercent: input.type === 'SALARY_ADVANCE' ? 5 : 10,
      termMonths: input.termMonths,
      currency: input.currency,
      status: 'APPROVED',
      createdAt: new Date(),
    };
    this.loans.set(loan.id, loan);

    // Get customer wallet
    const wallets = await this.walletStore.findWalletsByCustomerId(input.customerId);
    if (wallets.length === 0) {
      throw new Error('Customer has no wallet');
    }

    const pockets = await this.walletStore.findPocketsByWalletId(wallets[0].id);
    const pocket = pockets.find((p) => p.currency === input.currency);
    if (!pocket) {
      throw new Error(`Customer has no ${input.currency} pocket`);
    }

    // Post immediate credit to wallet
    const result = await this.ledgerService.postJournal({
      idempotencyKey: `loan-${loan.id}`,
      yoleReference: `LOAN-${loan.id}`,
      correlationId: loan.id,
      actorType: 'system',
      actorId: 'credit-system',
      currency: input.currency,
      postings: [
        {
          accountCode: 'LOAN_DISBURSEMENT',
          direction: 'debit',
          amountMinor: input.principalMinor,
          currency: input.currency,
        },
        {
          accountCode: 'CUST_WALLET',
          direction: 'credit',
          amountMinor: input.principalMinor,
          currency: input.currency,
          walletPocketId: pocket.id,
        },
      ],
    });

    loan.disbursedAt = new Date();
    loan.status = 'DISBURSED';
    this.loans.set(loan.id, loan);

    return {
      loanId: loan.id,
      principalMinor: loan.principalMinor.toString(),
      journalId: result.journalId,
      status: loan.status,
    };
  }

  async getLoan(loanId: string) {
    const loan = this.loans.get(loanId);
    if (!loan) {
      throw new Error('Loan not found');
    }
    return {
      ...loan,
      principalMinor: loan.principalMinor.toString(),
    };
  }

  async listLoans(customerId: string) {
    return Array.from(this.loans.values())
      .filter((l) => l.customerId === customerId)
      .map((l) => ({
        ...l,
        principalMinor: l.principalMinor.toString(),
      }));
  }
}
