import { Injectable } from '@nestjs/common';
import { LedgerService } from '../ledger/ledger.service';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';

export interface FxRate {
  id: string;
  fromCurrency: string;
  toCurrency: string;
  rate: number;
  effectiveDate: Date;
}

@Injectable()
export class FxService {
  private rates = new Map<string, FxRate>();
  private idCounter = 1;

  constructor(
    private ledgerService: LedgerService,
    private walletStore: InMemoryWalletStore,
  ) {
    // Seed default rates
    this.seedRates();
  }

  private seedRates() {
    const cdfUsd: FxRate = {
      id: `rate_${this.idCounter++}`,
      fromCurrency: 'CDF',
      toCurrency: 'USD',
      rate: 0.0004,
      effectiveDate: new Date(),
    };
    this.rates.set('CDF-USD', cdfUsd);

    const usdCdf: FxRate = {
      id: `rate_${this.idCounter++}`,
      fromCurrency: 'USD',
      toCurrency: 'CDF',
      rate: 2500,
      effectiveDate: new Date(),
    };
    this.rates.set('USD-CDF', usdCdf);
  }

  async getRates() {
    return Array.from(this.rates.values());
  }

  async getRate(fromCurrency: string, toCurrency: string) {
    const key = `${fromCurrency}-${toCurrency}`;
    return this.rates.get(key);
  }

  async convert(input: {
    customerId: string;
    fromCurrency: string;
    toCurrency: string;
    fromAmountMinor: bigint;
  }) {
    const rate = await this.getRate(input.fromCurrency, input.toCurrency);
    if (!rate) {
      throw new Error(`No rate found for ${input.fromCurrency} to ${input.toCurrency}`);
    }

    // Calculate to amount
    const toAmountMinor = BigInt(Math.floor(Number(input.fromAmountMinor) * rate.rate));

    // Get customer wallets
    const wallets = await this.walletStore.findWalletsByCustomerId(input.customerId);
    if (wallets.length === 0) {
      throw new Error('Customer has no wallet');
    }

    const pockets = await this.walletStore.findPocketsByWalletId(wallets[0].id);
    const fromPocket = pockets.find((p) => p.currency === input.fromCurrency);
    const toPocket = pockets.find((p) => p.currency === input.toCurrency);

    if (!fromPocket || !toPocket) {
      throw new Error('Customer missing required currency pockets');
    }

    // Post both legs via ledger
    const result = await this.ledgerService.postJournal({
      idempotencyKey: `fx-${input.customerId}-${Date.now()}`,
      yoleReference: `FX-${Date.now()}`,
      correlationId: input.customerId,
      actorType: 'customer',
      actorId: input.customerId,
      currency: input.fromCurrency as any,
      postings: [
        {
          accountCode: 'CUST_WALLET',
          direction: 'debit',
          amountMinor: input.fromAmountMinor,
          currency: input.fromCurrency as any,
          walletPocketId: fromPocket.id,
        },
        {
          accountCode: 'FX_SETTLEMENT',
          direction: 'credit',
          amountMinor: input.fromAmountMinor,
          currency: input.fromCurrency as any,
        },
      ],
    });

    // Post second leg
    await this.ledgerService.postJournal({
      idempotencyKey: `fx-${input.customerId}-${Date.now()}-leg2`,
      yoleReference: `FX-${Date.now()}-LEG2`,
      correlationId: input.customerId,
      actorType: 'customer',
      actorId: input.customerId,
      currency: input.toCurrency as any,
      postings: [
        {
          accountCode: 'FX_SETTLEMENT',
          direction: 'debit',
          amountMinor: toAmountMinor,
          currency: input.toCurrency as any,
        },
        {
          accountCode: 'CUST_WALLET',
          direction: 'credit',
          amountMinor: toAmountMinor,
          currency: input.toCurrency as any,
          walletPocketId: toPocket.id,
        },
      ],
    });

    return {
      fromAmountMinor: input.fromAmountMinor.toString(),
      toAmountMinor: toAmountMinor.toString(),
      rate: rate.rate,
      journalId: result.journalId,
    };
  }
}
