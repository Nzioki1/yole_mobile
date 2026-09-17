import { Injectable } from '@nestjs/common';
import { InMemoryAgentStore } from '../../common/stores/agent.store';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';
import { InMemoryCustomerStore } from '../../common/stores/customer.store';
import { LedgerService } from '../ledger/ledger.service';
import { CurrencyCode } from '../../common/stores/types';
import * as bcrypt from 'bcrypt';

@Injectable()
export class AgentsService {
  constructor(
    private agentStore: InMemoryAgentStore,
    private walletStore: InMemoryWalletStore,
    private customerStore: InMemoryCustomerStore,
    private ledgerService: LedgerService,
  ) {}

  /**
   * Admin enrolls a new agent with a float wallet
   */
  async enrollAgent(input: {
    firstName: string;
    lastName: string;
    phoneE164: string;
    email?: string;
  }) {
    // Check if agent already exists
    const existing = await this.agentStore.findByPhone(input.phoneE164);
    if (existing) {
      throw new Error('Agent with this phone already exists');
    }

    // Create float wallet with CDF and USD pockets
    const floatWallet = await this.walletStore.createWallet('FLOAT');
    await this.walletStore.createPocket({
      walletId: floatWallet.id,
      currency: 'CDF',
      ledgerMinor: 50000000n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });
    await this.walletStore.createPocket({
      walletId: floatWallet.id,
      currency: 'USD',
      ledgerMinor: 10000000n,
      blockedMinor: 0n,
      pendingOutMinor: 0n,
      pendingInMinor: 0n,
    });

    const agent = await this.agentStore.create({
      firstName: input.firstName,
      lastName: input.lastName,
      phoneE164: input.phoneE164,
      email: input.email || null,
      status: 'ACTIVE',
      floatWalletId: floatWallet.id,
    });

    return {
      agentId: agent.id,
      phoneE164: agent.phoneE164,
      floatWalletId: agent.floatWalletId,
    };
  }

  /**
   * Agent enrolls a new customer
   */
  async enrollCustomer(agentId: string, input: {
    firstName: string;
    lastName: string;
    phoneE164?: string;
    email?: string;
    password: string;
  }) {
    const agent = await this.agentStore.findById(agentId);
    if (!agent) {
      throw new Error('Agent not found');
    }

    // Check if customer already exists
    if (input.email) {
      const existingEmail = await this.customerStore.findByEmail(input.email);
      if (existingEmail) {
        throw new Error('Customer with this email already exists');
      }
    }

    // Hash password
    const passwordHash = await bcrypt.hash(input.password, 10);

    // Create customer
    const customer = await this.customerStore.create({
      firstName: input.firstName,
      lastName: input.lastName,
      phoneE164: input.phoneE164 || null,
      email: input.email || null,
      passwordHash,
      segment: 'AGENT_ENROLLED',
      status: 'ACTIVE',
      enrolledByAgentId: agentId,
    });

    // Create wallet with CDF and USD pockets
    const wallet = await this.walletStore.createWallet(customer.id);
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

    return {
      customerId: customer.id,
      walletId: wallet.id,
    };
  }

  /**
   * Agent cash-in: customer gives cash to agent, agent credits customer wallet from float
   */
  async cashIn(agentId: string, input: {
    customerId: string;
    amountMinor: bigint;
    currency: CurrencyCode;
  }) {
    const agent = await this.agentStore.findById(agentId);
    if (!agent) {
      throw new Error('Agent not found');
    }

    // Get agent's float pocket
    const floatPockets = await this.walletStore.findPocketsByWalletId(agent.floatWalletId);
    const floatPocket = floatPockets.find((p) => p.currency === input.currency);
    if (!floatPocket) {
      throw new Error(`Agent has no ${input.currency} float pocket`);
    }

    // Get customer's pocket
    const customerWallets = await this.walletStore.findWalletsByCustomerId(input.customerId);
    if (customerWallets.length === 0) {
      throw new Error('Customer has no wallet');
    }
    const customerPockets = await this.walletStore.findPocketsByWalletId(customerWallets[0].id);
    const customerPocket = customerPockets.find((p) => p.currency === input.currency);
    if (!customerPocket) {
      throw new Error(`Customer has no ${input.currency} pocket`);
    }

    // Post journal: debit float, credit customer
    const result = await this.ledgerService.postJournal({
      idempotencyKey: `cash-in-${agentId}-${Date.now()}`,
      yoleReference: `CASHIN-${Date.now()}`,
      correlationId: `agent-${agentId}`,
      actorType: 'agent',
      actorId: agentId,
      currency: input.currency,
      postings: [
        {
          accountCode: 'AGENT_FLOAT',
          direction: 'debit',
          amountMinor: input.amountMinor,
          currency: input.currency,
          walletPocketId: floatPocket.id,
        },
        {
          accountCode: 'CUST_WALLET',
          direction: 'credit',
          amountMinor: input.amountMinor,
          currency: input.currency,
          walletPocketId: customerPocket.id,
        },
      ],
    });

    return {
      journalId: result.journalId,
      status: result.status,
    };
  }

  /**
   * Agent cash-out: customer withdraws from wallet, agent gives cash, debits customer wallet to float
   */
  async cashOut(agentId: string, input: {
    customerId: string;
    amountMinor: bigint;
    currency: CurrencyCode;
  }) {
    const agent = await this.agentStore.findById(agentId);
    if (!agent) {
      throw new Error('Agent not found');
    }

    // Get agent's float pocket
    const floatPockets = await this.walletStore.findPocketsByWalletId(agent.floatWalletId);
    const floatPocket = floatPockets.find((p) => p.currency === input.currency);
    if (!floatPocket) {
      throw new Error(`Agent has no ${input.currency} float pocket`);
    }

    // Get customer's pocket
    const customerWallets = await this.walletStore.findWalletsByCustomerId(input.customerId);
    if (customerWallets.length === 0) {
      throw new Error('Customer has no wallet');
    }
    const customerPockets = await this.walletStore.findPocketsByWalletId(customerWallets[0].id);
    const customerPocket = customerPockets.find((p) => p.currency === input.currency);
    if (!customerPocket) {
      throw new Error(`Customer has no ${input.currency} pocket`);
    }

    // Post journal: debit customer, credit float
    const result = await this.ledgerService.postJournal({
      idempotencyKey: `cash-out-${agentId}-${Date.now()}`,
      yoleReference: `CASHOUT-${Date.now()}`,
      correlationId: `agent-${agentId}`,
      actorType: 'agent',
      actorId: agentId,
      currency: input.currency,
      postings: [
        {
          accountCode: 'CUST_WALLET',
          direction: 'debit',
          amountMinor: input.amountMinor,
          currency: input.currency,
          walletPocketId: customerPocket.id,
        },
        {
          accountCode: 'AGENT_FLOAT',
          direction: 'credit',
          amountMinor: input.amountMinor,
          currency: input.currency,
          walletPocketId: floatPocket.id,
        },
      ],
    });

    return {
      journalId: result.journalId,
      status: result.status,
    };
  }

  async listAgents() {
    return this.agentStore.list();
  }

  async getAgent(agentId: string) {
    return this.agentStore.findById(agentId);
  }
}
