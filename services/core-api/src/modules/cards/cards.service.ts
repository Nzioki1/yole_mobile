import { Injectable } from '@nestjs/common';
import { CurrencyCode } from '../../common/stores/types';

interface Card {
  id: string;
  customerId: string;
  walletPocketId: string;
  cardNumber: string;
  type: 'VIRTUAL_DEBIT';
  status: 'ACTIVE' | 'FROZEN' | 'BLOCKED';
  dailyLimitMinor: bigint;
  monthlyLimitMinor: bigint;
  currency: CurrencyCode;
  createdAt: Date;
}

interface CardTransaction {
  id: string;
  cardId: string;
  amountMinor: bigint;
  currency: CurrencyCode;
  merchantName: string;
  status: 'APPROVED' | 'DECLINED';
  createdAt: Date;
}

@Injectable()
export class CardsService {
  private cards = new Map<string, Card>();
  private transactions = new Map<string, CardTransaction>();
  private cardIdCounter = 1;
  private txnIdCounter = 1;

  async issueCard(input: {
    customerId: string;
    walletPocketId: string;
    currency: CurrencyCode;
    dailyLimitMinor: bigint;
    monthlyLimitMinor: bigint;
  }) {
    const card: Card = {
      id: `card_${this.cardIdCounter++}`,
      customerId: input.customerId,
      walletPocketId: input.walletPocketId,
      cardNumber: `4111111111${String(this.cardIdCounter).padStart(6, '0')}`,
      type: 'VIRTUAL_DEBIT',
      status: 'ACTIVE',
      dailyLimitMinor: input.dailyLimitMinor,
      monthlyLimitMinor: input.monthlyLimitMinor,
      currency: input.currency,
      createdAt: new Date(),
    };
    this.cards.set(card.id, card);
    return {
      ...card,
      dailyLimitMinor: card.dailyLimitMinor.toString(),
      monthlyLimitMinor: card.monthlyLimitMinor.toString(),
    };
  }

  async freezeCard(cardId: string, customerId: string) {
    const card = this.cards.get(cardId);
    if (!card || card.customerId !== customerId) {
      throw new Error('Card not found');
    }
    card.status = 'FROZEN';
    this.cards.set(cardId, card);
    return { cardId, status: card.status };
  }

  async activateCard(cardId: string, customerId: string) {
    const card = this.cards.get(cardId);
    if (!card || card.customerId !== customerId) {
      throw new Error('Card not found');
    }
    card.status = 'ACTIVE';
    this.cards.set(cardId, card);
    return { cardId, status: card.status };
  }

  async blockCard(cardId: string, customerId: string) {
    const card = this.cards.get(cardId);
    if (!card || card.customerId !== customerId) {
      throw new Error('Card not found');
    }
    card.status = 'BLOCKED';
    this.cards.set(cardId, card);
    return { cardId, status: card.status };
  }

  async setLimits(cardId: string, customerId: string, limits: {
    dailyLimitMinor: bigint;
    monthlyLimitMinor: bigint;
  }) {
    const card = this.cards.get(cardId);
    if (!card || card.customerId !== customerId) {
      throw new Error('Card not found');
    }
    card.dailyLimitMinor = limits.dailyLimitMinor;
    card.monthlyLimitMinor = limits.monthlyLimitMinor;
    this.cards.set(cardId, card);
    return {
      cardId,
      dailyLimitMinor: card.dailyLimitMinor.toString(),
      monthlyLimitMinor: card.monthlyLimitMinor.toString(),
    };
  }

  // Mock authorization (stub)
  async mockAuthorization(cardId: string, amountMinor: bigint, merchantName: string) {
    const card = this.cards.get(cardId);
    if (!card) {
      return { approved: false, reason: 'Card not found' };
    }

    if (card.status !== 'ACTIVE') {
      return { approved: false, reason: `Card is ${card.status}` };
    }

    const txn: CardTransaction = {
      id: `txn_${this.txnIdCounter++}`,
      cardId,
      amountMinor,
      currency: card.currency,
      merchantName,
      status: 'APPROVED',
      createdAt: new Date(),
    };
    this.transactions.set(txn.id, txn);

    return { approved: true, transactionId: txn.id };
  }

  async listCards(customerId: string) {
    return Array.from(this.cards.values())
      .filter((c) => c.customerId === customerId)
      .map((c) => ({
        ...c,
        dailyLimitMinor: c.dailyLimitMinor.toString(),
        monthlyLimitMinor: c.monthlyLimitMinor.toString(),
      }));
  }

  async listAllCards(customerId?: string) {
    let cards = Array.from(this.cards.values());
    if (customerId) {
      cards = cards.filter((c) => c.customerId === customerId);
    }
    return cards.map((c) => ({
      ...c,
      last4: c.cardNumber.substring(c.cardNumber.length - 4),
      dailyLimitMinor: c.dailyLimitMinor.toString(),
      monthlyLimitMinor: c.monthlyLimitMinor.toString(),
    }));
  }

  async listTransactions(cardId: string, customerId: string) {
    const card = this.cards.get(cardId);
    if (!card || card.customerId !== customerId) {
      throw new Error('Card not found');
    }

    return Array.from(this.transactions.values())
      .filter((t) => t.cardId === cardId)
      .map((t) => ({
        ...t,
        amountMinor: t.amountMinor.toString(),
      }));
  }
}
