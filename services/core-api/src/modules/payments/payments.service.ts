import { Injectable } from '@nestjs/common';
import { InMemoryPaymentStore, PaymentType } from '../../common/stores/payment.store';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';
import { CurrencyCode } from '../../common/stores/types';
import { LedgerService } from '../ledger/ledger.service';
import { MockMnoAdapter, MockBankAdapter, MockBillsAdapter } from './payment-adapter.port';

interface QuoteInput {
  customerId: string;
  type: PaymentType;
  currency: CurrencyCode;
  amountMinor: bigint;
  metadata?: Record<string, any>;
}

interface ConfirmInput {
  paymentId: string;
  customerId: string;
}

@Injectable()
export class PaymentsService {
  private mnoAdapter = new MockMnoAdapter();
  private bankAdapter = new MockBankAdapter();
  private billsAdapter = new MockBillsAdapter();

  constructor(
    private paymentStore: InMemoryPaymentStore,
    private walletStore: InMemoryWalletStore,
    private ledgerService: LedgerService,
  ) {}

  async quote(input: QuoteInput) {
    // Calculate fee (simple flat fee for mock)
    const feeMinor = this.calculateFee(input.type, input.amountMinor);
    const totalMinor = input.amountMinor + feeMinor;

    // For W2W, find source and destination pockets
    let fromWalletPocketId: string | undefined;
    let toWalletPocketId: string | undefined;

    // Handle inbound payments (MNO_IN, BANK_IN) - credit customer wallet
    if (input.type === 'MNO_IN' || input.type === 'BANK_IN') {
      const customerWallets = await this.walletStore.findWalletsByCustomerId(input.customerId);
      if (customerWallets.length === 0) {
        throw new Error('Customer has no wallet');
      }
      const customerPockets = await this.walletStore.findPocketsByWalletId(customerWallets[0].id);
      const customerPocket = customerPockets.find((p) => p.currency === input.currency);
      if (!customerPocket) {
        throw new Error(`Customer has no ${input.currency} pocket`);
      }
      toWalletPocketId = customerPocket.id;
      // Inbound payments have no fromWalletPocketId (external source)
    } else if (input.type === 'W2W') {
      const toCustomerId = input.metadata?.toCustomerId;
      if (!toCustomerId) {
        throw new Error('W2W requires toCustomerId in metadata');
      }

      // Find sender's pocket
      const senderWallets = await this.walletStore.findWalletsByCustomerId(input.customerId);
      if (senderWallets.length === 0) {
        throw new Error('Sender has no wallet');
      }
      const senderPockets = await this.walletStore.findPocketsByWalletId(senderWallets[0].id);
      const senderPocket = senderPockets.find((p) => p.currency === input.currency);
      if (!senderPocket) {
        throw new Error(`Sender has no ${input.currency} pocket`);
      }
      fromWalletPocketId = senderPocket.id;

      // Find receiver's pocket
      const receiverWallets = await this.walletStore.findWalletsByCustomerId(toCustomerId);
      if (receiverWallets.length === 0) {
        throw new Error('Receiver has no wallet');
      }
      const receiverPockets = await this.walletStore.findPocketsByWalletId(receiverWallets[0].id);
      const receiverPocket = receiverPockets.find((p) => p.currency === input.currency);
      if (!receiverPocket) {
        throw new Error(`Receiver has no ${input.currency} pocket`);
      }
      toWalletPocketId = receiverPocket.id;
    } else {
      // For other payment types, only need sender pocket
      const senderWallets = await this.walletStore.findWalletsByCustomerId(input.customerId);
      if (senderWallets.length === 0) {
        throw new Error('Customer has no wallet');
      }
      const senderPockets = await this.walletStore.findPocketsByWalletId(senderWallets[0].id);
      const senderPocket = senderPockets.find((p) => p.currency === input.currency);
      if (!senderPocket) {
        throw new Error(`Customer has no ${input.currency} pocket`);
      }
      fromWalletPocketId = senderPocket.id;
    }

    const payment = await this.paymentStore.create({
      customerId: input.customerId,
      type: input.type,
      currency: input.currency,
      amountMinor: input.amountMinor,
      feeMinor,
      totalMinor,
      status: 'QUOTED',
      fromWalletPocketId,
      toWalletPocketId,
      metadata: input.metadata || {},
    });

    return {
      paymentId: payment.id,
      amountMinor: payment.amountMinor.toString(),
      feeMinor: payment.feeMinor.toString(),
      totalMinor: payment.totalMinor.toString(),
      currency: payment.currency,
      status: payment.status,
    };
  }

  async confirm(input: ConfirmInput) {
    const payment = await this.paymentStore.findById(input.paymentId);
    if (!payment) {
      throw new Error('Payment not found');
    }

    if (payment.customerId !== input.customerId) {
      throw new Error('Payment does not belong to customer');
    }

    if (payment.status !== 'QUOTED') {
      throw new Error(`Payment cannot be confirmed from status ${payment.status}`);
    }

    // Move to CONFIRMED
    await this.paymentStore.update(payment.id, { status: 'CONFIRMED' });

    // Move to PENDING
    await this.paymentStore.update(payment.id, { status: 'PENDING' });

    // Execute payment
    try {
      let externalRef: string | undefined;

      switch (payment.type) {
        case 'MNO_IN':
          // Mock MNO inbound - instant success
          externalRef = `MNO_IN_${Date.now()}`;
          await this.ledgerService.postJournal({
            idempotencyKey: `payment-${payment.id}`,
            yoleReference: `PAY-${payment.id}`,
            correlationId: payment.id,
            actorType: 'customer',
            actorId: payment.customerId,
            currency: payment.currency,
            postings: [
              {
                accountCode: 'MNO_SETTLEMENT',
                direction: 'debit',
                amountMinor: payment.amountMinor,
                currency: payment.currency,
              },
              {
                accountCode: 'CUST_WALLET',
                direction: 'credit',
                amountMinor: payment.amountMinor,
                currency: payment.currency,
                walletPocketId: payment.toWalletPocketId!,
              },
              {
                accountCode: 'CUST_WALLET',
                direction: 'debit',
                amountMinor: payment.feeMinor,
                currency: payment.currency,
                walletPocketId: payment.toWalletPocketId!,
              },
              {
                accountCode: 'FEE_REVENUE',
                direction: 'credit',
                amountMinor: payment.feeMinor,
                currency: payment.currency,
              },
            ],
          });
          await this.paymentStore.update(payment.id, {
            status: 'POSTED',
            externalRef,
          });
          break;

        case 'BANK_IN':
          // Mock bank inbound - instant success
          externalRef = `BANK_IN_${Date.now()}`;
          await this.ledgerService.postJournal({
            idempotencyKey: `payment-${payment.id}`,
            yoleReference: `PAY-${payment.id}`,
            correlationId: payment.id,
            actorType: 'customer',
            actorId: payment.customerId,
            currency: payment.currency,
            postings: [
              {
                accountCode: 'BANK_SETTLEMENT',
                direction: 'debit',
                amountMinor: payment.amountMinor,
                currency: payment.currency,
              },
              {
                accountCode: 'CUST_WALLET',
                direction: 'credit',
                amountMinor: payment.amountMinor,
                currency: payment.currency,
                walletPocketId: payment.toWalletPocketId!,
              },
              {
                accountCode: 'CUST_WALLET',
                direction: 'debit',
                amountMinor: payment.feeMinor,
                currency: payment.currency,
                walletPocketId: payment.toWalletPocketId!,
              },
              {
                accountCode: 'FEE_REVENUE',
                direction: 'credit',
                amountMinor: payment.feeMinor,
                currency: payment.currency,
              },
            ],
          });
          await this.paymentStore.update(payment.id, {
            status: 'POSTED',
            externalRef,
          });
          break;

        case 'W2W':
          // Post journal for W2W
          const w2wResult = await this.ledgerService.postJournal({
            idempotencyKey: `payment-${payment.id}`,
            yoleReference: `PAY-${payment.id}`,
            correlationId: payment.id,
            actorType: 'customer',
            actorId: payment.customerId,
            currency: payment.currency,
            postings: [
              {
                accountCode: 'CUST_WALLET',
                direction: 'debit',
                amountMinor: payment.totalMinor,
                currency: payment.currency,
                walletPocketId: payment.fromWalletPocketId!,
              },
              {
                accountCode: 'CUST_WALLET',
                direction: 'credit',
                amountMinor: payment.amountMinor,
                currency: payment.currency,
                walletPocketId: payment.toWalletPocketId!,
              },
              {
                accountCode: 'FEE_REVENUE',
                direction: 'credit',
                amountMinor: payment.feeMinor,
                currency: payment.currency,
              },
            ],
          });
          await this.paymentStore.update(payment.id, {
            status: 'POSTED',
            journalId: w2wResult.journalId,
          });
          break;

        case 'MNO_OUT':
          const mnoOut = await this.mnoAdapter.sendMoney(
            payment.metadata.phoneE164,
            payment.amountMinor,
            payment.currency,
          );
          if (mnoOut.success) {
            externalRef = mnoOut.externalRef;
            // Debit wallet
            await this.ledgerService.postJournal({
              idempotencyKey: `payment-${payment.id}`,
              yoleReference: `PAY-${payment.id}`,
              correlationId: payment.id,
              actorType: 'customer',
              actorId: payment.customerId,
              currency: payment.currency,
              postings: [
                {
                  accountCode: 'CUST_WALLET',
                  direction: 'debit',
                  amountMinor: payment.totalMinor,
                  currency: payment.currency,
                  walletPocketId: payment.fromWalletPocketId!,
                },
                {
                  accountCode: 'MNO_SETTLEMENT',
                  direction: 'credit',
                  amountMinor: payment.amountMinor,
                  currency: payment.currency,
                },
                {
                  accountCode: 'FEE_REVENUE',
                  direction: 'credit',
                  amountMinor: payment.feeMinor,
                  currency: payment.currency,
                },
              ],
            });
            await this.paymentStore.update(payment.id, {
              status: 'POSTED',
              externalRef,
            });
          } else {
            throw new Error(mnoOut.errorMessage || 'MNO payment failed');
          }
          break;

        case 'BILL':
          const billResult = await this.billsAdapter.payBill(
            payment.metadata.billerId,
            payment.metadata.accountNumber,
            payment.amountMinor,
            payment.currency,
          );
          if (billResult.success) {
            externalRef = billResult.externalRef;
            await this.ledgerService.postJournal({
              idempotencyKey: `payment-${payment.id}`,
              yoleReference: `PAY-${payment.id}`,
              correlationId: payment.id,
              actorType: 'customer',
              actorId: payment.customerId,
              currency: payment.currency,
              postings: [
                {
                  accountCode: 'CUST_WALLET',
                  direction: 'debit',
                  amountMinor: payment.totalMinor,
                  currency: payment.currency,
                  walletPocketId: payment.fromWalletPocketId!,
                },
                {
                  accountCode: 'BILLER_SETTLEMENT',
                  direction: 'credit',
                  amountMinor: payment.amountMinor,
                  currency: payment.currency,
                },
                {
                  accountCode: 'FEE_REVENUE',
                  direction: 'credit',
                  amountMinor: payment.feeMinor,
                  currency: payment.currency,
                },
              ],
            });
            await this.paymentStore.update(payment.id, {
              status: 'POSTED',
              externalRef,
            });
          } else {
            throw new Error(billResult.errorMessage || 'Bill payment failed');
          }
          break;

        default:
          throw new Error(`Payment type ${payment.type} not yet implemented`);
      }

      const updated = await this.paymentStore.findById(payment.id);
      return {
        paymentId: updated!.id,
        status: updated!.status,
        externalRef: updated!.externalRef,
      };
    } catch (error: any) {
      await this.paymentStore.update(payment.id, { status: 'FAILED' });
      throw error;
    }
  }

  async getPayment(paymentId: string, customerId: string) {
    const payment = await this.paymentStore.findById(paymentId);
    if (!payment) {
      throw new Error('Payment not found');
    }
    if (payment.customerId !== customerId) {
      throw new Error('Payment does not belong to customer');
    }
    return this.serializePayment(payment);
  }

  async listPayments(customerId: string) {
    const payments = await this.paymentStore.findByCustomerId(customerId);
    return payments.map((p) => this.serializePayment(p));
  }

  private serializePayment(payment: any) {
    return {
      ...payment,
      amountMinor: payment.amountMinor.toString(),
      feeMinor: payment.feeMinor.toString(),
      totalMinor: payment.totalMinor.toString(),
    };
  }

  private calculateFee(type: PaymentType, amountMinor: bigint): bigint {
    // Mock fee calculation: 1% or 100 minor units, whichever is greater
    const percentFee = amountMinor / 100n;
    const minFee = 100n;
    return percentFee > minFee ? percentFee : minFee;
  }
}
