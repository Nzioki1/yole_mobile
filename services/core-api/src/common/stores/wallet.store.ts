import { Injectable } from '@nestjs/common';
import { Wallet, WalletPocket, CurrencyCode } from './types';

export interface WalletStore {
  createWallet(customerId: string): Promise<Wallet>;
  createPocket(data: Omit<WalletPocket, 'id'>): Promise<WalletPocket>;
  findWalletsByCustomerId(customerId: string): Promise<Wallet[]>;
  findPocketsByWalletId(walletId: string): Promise<WalletPocket[]>;
  findPocketById(id: string): Promise<WalletPocket | null>;
  updatePocket(id: string, data: Partial<WalletPocket>): Promise<WalletPocket>;
}

@Injectable()
export class InMemoryWalletStore implements WalletStore {
  private wallets = new Map<string, Wallet>();
  private pockets = new Map<string, WalletPocket>();
  private walletIdCounter = 1;
  private pocketIdCounter = 1;

  async createWallet(customerId: string): Promise<Wallet> {
    const wallet: Wallet = {
      id: `wallet_${this.walletIdCounter++}`,
      customerId,
    };
    this.wallets.set(wallet.id, wallet);
    return wallet;
  }

  async createPocket(data: Omit<WalletPocket, 'id'>): Promise<WalletPocket> {
    const pocket: WalletPocket = {
      ...data,
      id: `pocket_${this.pocketIdCounter++}`,
    };
    this.pockets.set(pocket.id, pocket);
    return pocket;
  }

  async findWalletsByCustomerId(customerId: string): Promise<Wallet[]> {
    return Array.from(this.wallets.values()).filter(
      (w) => w.customerId === customerId,
    );
  }

  async findPocketsByWalletId(walletId: string): Promise<WalletPocket[]> {
    return Array.from(this.pockets.values()).filter(
      (p) => p.walletId === walletId,
    );
  }

  async findPocketById(id: string): Promise<WalletPocket | null> {
    return this.pockets.get(id) || null;
  }

  async updatePocket(
    id: string,
    data: Partial<WalletPocket>,
  ): Promise<WalletPocket> {
    const pocket = this.pockets.get(id);
    if (!pocket) {
      throw new Error(`Pocket ${id} not found`);
    }
    const updated = { ...pocket, ...data };
    this.pockets.set(id, updated);
    return updated;
  }

  // Test helper
  clear() {
    this.wallets.clear();
    this.pockets.clear();
  }
}
