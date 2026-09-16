import { Injectable } from '@nestjs/common';
import { InMemoryCustomerStore } from '../../common/stores/customer.store';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';
import { Customer, Wallet } from '../../common/stores/types';

export interface CreateCustomerInput {
  email?: string;
  phoneE164?: string;
  firstName: string;
  lastName: string;
  passwordHash: string;
  enrolledByAgentId?: string;
}

@Injectable()
export class CustomersService {
  constructor(
    private customerStore: InMemoryCustomerStore,
    private walletStore: InMemoryWalletStore,
  ) {}

  /**
   * Create a new customer with an empty wallet containing CDF and USD pockets at 0.
   */
  async createCustomer(
    input: CreateCustomerInput,
  ): Promise<Customer & { wallet: Wallet }> {
    // Create customer
    const customer = await this.customerStore.create({
      email: input.email || null,
      phoneE164: input.phoneE164 || null,
      firstName: input.firstName,
      lastName: input.lastName,
      passwordHash: input.passwordHash,
      segment: 'OPEN_MARKET',
      status: 'ACTIVE',
      enrolledByAgentId: input.enrolledByAgentId || null,
    });

    // Create wallet
    const wallet = await this.walletStore.createWallet(customer.id);

    // Create CDF and USD pockets at 0
    await this.walletStore.createPocket({
      walletId: wallet.id,
      currency: 'CDF',
      ledgerMinor: 0n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });

    await this.walletStore.createPocket({
      walletId: wallet.id,
      currency: 'USD',
      ledgerMinor: 0n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });

    return { ...customer, wallet };
  }

  async findByEmail(email: string): Promise<Customer | null> {
    return await this.customerStore.findByEmail(email);
  }

  async findById(id: string): Promise<Customer | null> {
    return await this.customerStore.findById(id);
  }
}
