import { Injectable } from '@nestjs/common';
import { InMemoryCustomerStore } from '../../common/stores/customer.store';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';
import { InMemoryPaymentStore } from '../../common/stores/payment.store';
import { InMemoryLedgerStore } from '../../common/stores/ledger.store';

// Simple in-memory config store for fees/limits
interface FeeConfig {
  id: string;
  paymentType: string;
  feePercent: number;
  minFeeMinor: bigint;
  maxFeeMinor: bigint;
}

interface LimitConfig {
  id: string;
  limitType: string;
  currency: string;
  dailyLimitMinor: bigint;
  monthlyLimitMinor: bigint;
}

@Injectable()
export class AdminService {
  private feeConfigs: Map<string, FeeConfig> = new Map();
  private limitConfigs: Map<string, LimitConfig> = new Map();
  private feeIdCounter = 1;
  private limitIdCounter = 1;

  constructor(
    private customerStore: InMemoryCustomerStore,
    private walletStore: InMemoryWalletStore,
    private paymentStore: InMemoryPaymentStore,
    private ledgerStore: InMemoryLedgerStore,
  ) {
    // Seed some default configs
    this.seedDefaultConfigs();
  }

  private seedDefaultConfigs() {
    // Default fees
    this.feeConfigs.set('fee_1', {
      id: 'fee_1',
      paymentType: 'W2W',
      feePercent: 1,
      minFeeMinor: 100n,
      maxFeeMinor: 10000n,
    });
    this.feeConfigs.set('fee_2', {
      id: 'fee_2',
      paymentType: 'MNO_OUT',
      feePercent: 2,
      minFeeMinor: 200n,
      maxFeeMinor: 20000n,
    });

    // Default limits
    this.limitConfigs.set('limit_1', {
      id: 'limit_1',
      limitType: 'CUSTOMER_DAILY',
      currency: 'USD',
      dailyLimitMinor: 100000n,
      monthlyLimitMinor: 1000000n,
    });
  }

  /**
   * Customer 360 view
   */
  async getCustomer360(customerId: string) {
    const customer = await this.customerStore.findById(customerId);
    if (!customer) {
      throw new Error('Customer not found');
    }

    // Get wallets and pockets
    const wallets = await this.walletStore.findWalletsByCustomerId(customerId);
    const walletsWithPockets = await Promise.all(
      wallets.map(async (wallet) => {
        const pockets = await this.walletStore.findPocketsByWalletId(wallet.id);
        return {
          ...wallet,
          pockets: pockets.map((p) => ({
            ...p,
            ledgerMinor: p.ledgerMinor.toString(),
            blockedMinor: p.blockedMinor.toString(),
            pendingOutMinor: p.pendingOutMinor.toString(),
            pendingInMinor: p.pendingInMinor.toString(),
          })),
        };
      }),
    );

    // Get recent payments
    const payments = await this.paymentStore.findByCustomerId(customerId);
    const recentPayments = payments.slice(-10).map((p) => ({
      ...p,
      amountMinor: p.amountMinor.toString(),
      feeMinor: p.feeMinor.toString(),
      totalMinor: p.totalMinor.toString(),
    }));

    return {
      customer,
      wallets: walletsWithPockets,
      recentPayments,
    };
  }

  /**
   * Search payments across all customers
   */
  async searchPayments(filters?: {
    customerId?: string;
    status?: string;
    type?: string;
  }) {
    const allPayments = await this.paymentStore.list({
      status: filters?.status as any,
      type: filters?.type as any,
    });

    let results = allPayments;
    if (filters?.customerId) {
      results = results.filter((p) => p.customerId === filters.customerId);
    }

    return results.map((p) => ({
      ...p,
      amountMinor: p.amountMinor.toString(),
      feeMinor: p.feeMinor.toString(),
      totalMinor: p.totalMinor.toString(),
    }));
  }

  /**
   * Fee configuration CRUD
   */
  async listFeeConfigs() {
    return Array.from(this.feeConfigs.values()).map((f) => ({
      ...f,
      minFeeMinor: f.minFeeMinor.toString(),
      maxFeeMinor: f.maxFeeMinor.toString(),
    }));
  }

  async createFeeConfig(input: {
    paymentType: string;
    feePercent: number;
    minFeeMinor: string;
    maxFeeMinor: string;
  }) {
    const id = `fee_${this.feeIdCounter++}`;
    const config: FeeConfig = {
      id,
      paymentType: input.paymentType,
      feePercent: input.feePercent,
      minFeeMinor: BigInt(input.minFeeMinor),
      maxFeeMinor: BigInt(input.maxFeeMinor),
    };
    this.feeConfigs.set(id, config);
    return {
      ...config,
      minFeeMinor: config.minFeeMinor.toString(),
      maxFeeMinor: config.maxFeeMinor.toString(),
    };
  }

  /**
   * Limit configuration CRUD
   */
  async listLimitConfigs() {
    return Array.from(this.limitConfigs.values()).map((l) => ({
      ...l,
      dailyLimitMinor: l.dailyLimitMinor.toString(),
      monthlyLimitMinor: l.monthlyLimitMinor.toString(),
    }));
  }

  async createLimitConfig(input: {
    limitType: string;
    currency: string;
    dailyLimitMinor: string;
    monthlyLimitMinor: string;
  }) {
    const id = `limit_${this.limitIdCounter++}`;
    const config: LimitConfig = {
      id,
      limitType: input.limitType,
      currency: input.currency,
      dailyLimitMinor: BigInt(input.dailyLimitMinor),
      monthlyLimitMinor: BigInt(input.monthlyLimitMinor),
    };
    this.limitConfigs.set(id, config);
    return {
      ...config,
      dailyLimitMinor: config.dailyLimitMinor.toString(),
      monthlyLimitMinor: config.monthlyLimitMinor.toString(),
    };
  }

  /**
   * Recon: daily summary from journals
   */
  async getDailySummary(date: string) {
    const journals = await this.ledgerStore.listJournals();
    const dayStart = new Date(date);
    const dayEnd = new Date(date);
    dayEnd.setDate(dayEnd.getDate() + 1);

    const dayJournals = journals.filter((j) => {
      const jDate = new Date(j.createdAt);
      return jDate >= dayStart && jDate < dayEnd;
    });

    return {
      date,
      totalJournals: dayJournals.length,
      postedJournals: dayJournals.filter((j) => j.status === 'POSTED').length,
    };
  }

  /**
   * Case management stub
   */
  private cases = new Map();
  private caseIdCounter = 1;

  async createCase(input: { type: string; description: string; customerId?: string }) {
    const caseId = `case_${this.caseIdCounter++}`;
    const caseData = {
      id: caseId,
      type: input.type,
      description: input.description,
      customerId: input.customerId,
      status: 'OPEN',
      createdAt: new Date(),
    };
    this.cases.set(caseId, caseData);
    return caseData;
  }

  async updateCase(caseId: string, decision: string) {
    const caseData = this.cases.get(caseId);
    if (!caseData) {
      throw new Error('Case not found');
    }
    caseData.status = decision;
    caseData.decidedAt = new Date();
    this.cases.set(caseId, caseData);
    return caseData;
  }

  async listCases(status?: string) {
    const allCases = Array.from(this.cases.values());
    if (status) {
      return allCases.filter((c) => c.status === status);
    }
    return allCases;
  }
}
