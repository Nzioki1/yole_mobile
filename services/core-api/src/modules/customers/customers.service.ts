import { Injectable } from '@nestjs/common';
import { PrismaClient, Customer, Wallet } from '@prisma/client';

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
  private prisma: PrismaClient;

  constructor() {
    this.prisma = new PrismaClient();
  }

  /**
   * Create a new customer with an empty wallet containing CDF and USD pockets at 0.
   */
  async createCustomer(
    input: CreateCustomerInput,
  ): Promise<Customer & { wallet: Wallet }> {
    return await this.prisma.$transaction(async (tx) => {
      // Create customer
      const customer = await tx.customer.create({
        data: {
          email: input.email,
          phoneE164: input.phoneE164,
          firstName: input.firstName,
          lastName: input.lastName,
          passwordHash: input.passwordHash,
          segment: 'OPEN_MARKET',
          status: 'ACTIVE',
          enrolledByAgentId: input.enrolledByAgentId,
        },
      });

      // Create wallet
      const wallet = await tx.wallet.create({
        data: {
          customerId: customer.id,
        },
      });

      // Create CDF and USD pockets at 0
      await tx.walletPocket.create({
        data: {
          walletId: wallet.id,
          currency: 'CDF',
          ledgerMinor: 0n,
          blockedMinor: 0n,
          pendingOutMinor: 0n,
          pendingInMinor: 0n,
        },
      });

      await tx.walletPocket.create({
        data: {
          walletId: wallet.id,
          currency: 'USD',
          ledgerMinor: 0n,
          blockedMinor: 0n,
          pendingOutMinor: 0n,
          pendingInMinor: 0n,
        },
      });

      return { ...customer, wallet };
    });
  }

  async findByEmail(email: string): Promise<Customer | null> {
    return await this.prisma.customer.findUnique({
      where: { email },
    });
  }

  async findById(id: string): Promise<Customer | null> {
    return await this.prisma.customer.findUnique({
      where: { id },
    });
  }

  async onModuleDestroy() {
    await this.prisma.$disconnect();
  }
}
