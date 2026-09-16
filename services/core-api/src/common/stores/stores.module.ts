import { Global, Module } from '@nestjs/common';
import { InMemoryCustomerStore } from './customer.store';
import { InMemoryWalletStore } from './wallet.store';
import { InMemoryLedgerStore } from './ledger.store';
import { InMemoryKycStore } from './kyc.store';

@Global()
@Module({
  providers: [
    InMemoryCustomerStore,
    InMemoryWalletStore,
    InMemoryLedgerStore,
    InMemoryKycStore,
  ],
  exports: [
    InMemoryCustomerStore,
    InMemoryWalletStore,
    InMemoryLedgerStore,
    InMemoryKycStore,
  ],
})
export class StoresModule {}
