import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { StoresModule } from './common/stores/stores.module';
import { IdentityModule } from './modules/identity/identity.module';
import { CustomersModule } from './modules/customers/customers.module';
import { LedgerModule } from './modules/ledger/ledger.module';
import { KycModule } from './modules/kyc/kyc.module';
import { PaymentsModule } from './modules/payments/payments.module';

@Module({
  imports: [
    StoresModule,
    IdentityModule,
    CustomersModule,
    LedgerModule,
    KycModule,
    PaymentsModule,
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
