import { Injectable } from '@nestjs/common';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';

@Injectable()
export class WalletsService {
  constructor(private walletStore: InMemoryWalletStore) {}

  async getCustomerWallets(customerId: string) {
    const wallets = await this.walletStore.findWalletsByCustomerId(customerId);
    
    const walletsWithPockets = await Promise.all(
      wallets.map(async (wallet) => {
        const pockets = await this.walletStore.findPocketsByWalletId(wallet.id);
        return {
          id: wallet.id,
          customerId: wallet.customerId,
          pockets: pockets.map((p) => ({
            id: p.id,
            currency: p.currency,
            ledgerMinor: p.ledgerMinor.toString(),
            blockedMinor: p.blockedMinor.toString(),
            pendingOutMinor: p.pendingOutMinor.toString(),
            pendingInMinor: p.pendingInMinor.toString(),
            availableMinor: (p.ledgerMinor - p.blockedMinor - p.pendingOutMinor).toString(),
          })),
        };
      }),
    );

    return { wallets: walletsWithPockets };
  }
}
