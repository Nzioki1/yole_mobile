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

  async getCustomerLimits(customerId: string) {
    // Mock limits based on KYC tier (for now, return tier 1 limits)
    // In production, would check customer.kycStatus and return appropriate tier
    
    // For demo: return mock daily/monthly limits with some mock usage
    const dailyUsedMinor = 25000n; // $250 used today
    const monthlyUsedMinor = 150000n; // $1500 used this month

    return {
      kycTier: 'TIER_1',
      limits: [
        {
          currency: 'USD',
          dailyLimitMinor: '100000', // $1000
          dailyUsedMinor: dailyUsedMinor.toString(),
          dailyRemainingMinor: (100000n - dailyUsedMinor).toString(),
          monthlyLimitMinor: '1000000', // $10000
          monthlyUsedMinor: monthlyUsedMinor.toString(),
          monthlyRemainingMinor: (1000000n - monthlyUsedMinor).toString(),
        },
        {
          currency: 'CDF',
          dailyLimitMinor: '25000000', // 250k CDF
          dailyUsedMinor: '5000000', // 50k CDF used
          dailyRemainingMinor: '20000000',
          monthlyLimitMinor: '250000000', // 2.5M CDF
          monthlyUsedMinor: '30000000', // 300k CDF used
          monthlyRemainingMinor: '220000000',
        },
      ],
    };
  }
}
