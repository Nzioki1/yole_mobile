import { Global, Module } from '@nestjs/common';
import { InMemoryCustomerStore } from './customer.store';
import { InMemoryWalletStore } from './wallet.store';
import { InMemoryLedgerStore } from './ledger.store';
import { InMemoryKycStore } from './kyc.store';
import { InMemoryPaymentStore } from './payment.store';

@Global()
@Module({
  providers: [
    InMemoryCustomerStore,
    InMemoryWalletStore,
    InMemoryLedgerStore,
    InMemoryKycStore,
    InMemoryPaymentStore,
  ],
  exports: [
    InMemoryCustomerStore,
    InMemoryWalletStore,
    InMemoryLedgerStore,
    InMemoryKycStore,
    InMemoryPaymentStore,
  ],
})
export class StoresModule {}
