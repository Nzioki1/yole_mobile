import { Injectable } from '@nestjs/common';
import { LedgerService } from '../ledger/ledger.service';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';
import { CurrencyCode } from '../../common/stores/types';

interface Remittance {
  id: string;
  type: 'INBOUND' | 'OUTBOUND';
  customerId: string;
  amountMinor: bigint;
  currency: CurrencyCode;
  status: 'PENDING' | 'SCREENED' | 'APPROVED' | 'REJECTED' | 'COMPLETED';
  screeningHit: boolean;
  createdAt: Date;
}

@Injectable()
export class RemittanceService {
  private remittances = new Map<string, Remittance>();
  private idCounter = 1;

  constructor(
    private ledgerService: LedgerService,
    private walletStore: InMemoryWalletStore,
  ) {}

  async quoteInbound(input: { customerId: string; amountMinor: bigint; currency: CurrencyCode }) {
    // Mock screening (stub - always no hit)
    const screeningHit = false;

    const remittance: Remittance = {
      id: `remit_${this.idCounter++}`,
      type: 'INBOUND',
      customerId: input.customerId,
      amountMinor: input.amountMinor,
      currency: input.currency,
      status: 'SCREENED',
      screeningHit,
      createdAt: new Date(),
    };
    this.remittances.set(remittance.id, remittance);

    return {
      remittanceId: remittance.id,
      amountMinor: remittance.amountMinor.toString(),
      status: remittance.status,
      screeningHit,
    };
  }

  async confirmInbound(remittanceId: string) {
    const remittance = this.remittances.get(remittanceId);
    if (!remittance || remittance.type !== 'INBOUND') {
      throw new Error('Inbound remittance not found');
    }

    // Get customer wallet
    const wallets = await this.walletStore.findWalletsByCustomerId(remittance.customerId);
    if (wallets.length === 0) {
      throw new Error('Customer has no wallet');
    }

    const pockets = await this.walletStore.findPocketsByWalletId(wallets[0].id);
    const pocket = pockets.find((p) => p.currency === remittance.currency);
    if (!pocket) {
      throw new Error(`Customer has no ${remittance.currency} pocket`);
    }

    // Post to wallet
    const result = await this.ledgerService.postJournal({
      idempotencyKey: `remit-${remittanceId}`,
      yoleReference: `REMIT-${remittanceId}`,
      correlationId: remittanceId,
      actorType: 'system',
      actorId: 'remittance',
      currency: remittance.currency,
      postings: [
        {
          accountCode: 'REMITTANCE_SUSPENSE',
          direction: 'debit',
          amountMinor: remittance.amountMinor,
          currency: remittance.currency,
        },
        {
          accountCode: 'CUST_WALLET',
          direction: 'credit',
          amountMinor: remittance.amountMinor,
          currency: remittance.currency,
          walletPocketId: pocket.id,
        },
      ],
    });

    remittance.status = 'COMPLETED';
    this.remittances.set(remittanceId, remittance);

    return { remittanceId, status: remittance.status, journalId: result.journalId };
  }

  async quoteOutbound(input: { customerId: string; amountMinor: bigint; currency: CurrencyCode }) {
    const remittance: Remittance = {
      id: `remit_${this.idCounter++}`,
      type: 'OUTBOUND',
      customerId: input.customerId,
      amountMinor: input.amountMinor,
      currency: input.currency,
      status: 'PENDING',
      screeningHit: false,
      createdAt: new Date(),
    };
    this.remittances.set(remittance.id, remittance);

    return {
      remittanceId: remittance.id,
      amountMinor: remittance.amountMinor.toString(),
      status: remittance.status,
    };
  }

  async listRemittances(customerId: string) {
    return Array.from(this.remittances.values())
      .filter((r) => r.customerId === customerId)
      .map((r) => ({
        ...r,
        amountMinor: r.amountMinor.toString(),
      }));
  }
}
