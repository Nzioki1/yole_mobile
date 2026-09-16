import { Injectable } from '@nestjs/common';
import { CurrencyCode } from './types';

export type PaymentType = 'W2W' | 'MNO_IN' | 'MNO_OUT' | 'BANK_IN' | 'BANK_OUT' | 'BILL' | 'AIRTIME';
export type PaymentStatus = 'QUOTED' | 'CONFIRMED' | 'PENDING' | 'POSTED' | 'FAILED';

export interface Payment {
  id: string;
  customerId: string;
  type: PaymentType;
  currency: CurrencyCode;
  amountMinor: bigint;
  feeMinor: bigint;
  totalMinor: bigint;
  status: PaymentStatus;
  fromWalletPocketId?: string;
  toWalletPocketId?: string;
  externalRef?: string;
  journalId?: string;
  metadata: Record<string, any>;
  createdAt: Date;
  updatedAt: Date;
}

export interface PaymentStore {
  create(data: Omit<Payment, 'id' | 'createdAt' | 'updatedAt'>): Promise<Payment>;
  findById(id: string): Promise<Payment | null>;
  findByCustomerId(customerId: string): Promise<Payment[]>;
  update(id: string, data: Partial<Payment>): Promise<Payment>;
  list(filters?: { status?: PaymentStatus; type?: PaymentType }): Promise<Payment[]>;
}

@Injectable()
export class InMemoryPaymentStore implements PaymentStore {
  private payments = new Map<string, Payment>();
  private idCounter = 1;

  async create(data: Omit<Payment, 'id' | 'createdAt' | 'updatedAt'>): Promise<Payment> {
    const payment: Payment = {
      ...data,
      id: `pay_${this.idCounter++}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.payments.set(payment.id, payment);
    return payment;
  }

  async findById(id: string): Promise<Payment | null> {
    return this.payments.get(id) || null;
  }

  async findByCustomerId(customerId: string): Promise<Payment[]> {
    return Array.from(this.payments.values()).filter((p) => p.customerId === customerId);
  }

  async update(id: string, data: Partial<Payment>): Promise<Payment> {
    const payment = this.payments.get(id);
    if (!payment) {
      throw new Error(`Payment ${id} not found`);
    }
    const updated = { ...payment, ...data, updatedAt: new Date() };
    this.payments.set(id, updated);
    return updated;
  }

  async list(filters?: { status?: PaymentStatus; type?: PaymentType }): Promise<Payment[]> {
    let results = Array.from(this.payments.values());
    if (filters?.status) {
      results = results.filter((p) => p.status === filters.status);
    }
    if (filters?.type) {
      results = results.filter((p) => p.type === filters.type);
    }
    return results;
  }

  clear(): void {
    this.payments.clear();
    this.idCounter = 1;
  }
}
