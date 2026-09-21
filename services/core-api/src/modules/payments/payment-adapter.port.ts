// Payment adapter interfaces for external providers

export interface PaymentAdapterResult {
  success: boolean;
  externalRef?: string;
  errorMessage?: string;
}

export interface MnoAdapter {
  sendMoney(phoneE164: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult>;
  receiveMoney(phoneE164: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult>;
}

export interface BankAdapter {
  sendToBank(accountNumber: string, bankCode: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult>;
  receiveFromBank(accountNumber: string, bankCode: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult>;
}

export interface BillsAdapter {
  payBill(billerId: string, accountNumber: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult>;
  buyAirtime(phoneE164: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult>;
}

// Mock implementations for Phase 1

export class MockMnoAdapter implements MnoAdapter {
  async sendMoney(phoneE164: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult> {
    // Mock: instant success
    return { success: true, externalRef: `MNO-OUT-${Date.now()}` };
  }

  async receiveMoney(phoneE164: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult> {
    // Mock: instant success
    return { success: true, externalRef: `MNO-IN-${Date.now()}` };
  }
}

export class MockBankAdapter implements BankAdapter {
  async sendToBank(accountNumber: string, bankCode: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult> {
    // Mock: instant success
    return { success: true, externalRef: `BANK-OUT-${Date.now()}` };
  }

  async receiveFromBank(accountNumber: string, bankCode: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult> {
    // Mock: instant success
    return { success: true, externalRef: `BANK-IN-${Date.now()}` };
  }
}

export class MockBillsAdapter implements BillsAdapter {
  async payBill(billerId: string, accountNumber: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult> {
    // Mock: instant success
    return { success: true, externalRef: `BILL-${Date.now()}` };
  }

  async buyAirtime(phoneE164: string, amountMinor: bigint, currency: string): Promise<PaymentAdapterResult> {
    // Mock: instant success
    return { success: true, externalRef: `AIRTIME-${Date.now()}` };
  }
}
