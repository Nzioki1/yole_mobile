import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { StoresModule } from './common/stores/stores.module';
import { IdentityModule } from './modules/identity/identity.module';
import { CustomersModule } from './modules/customers/customers.module';
import { LedgerModule } from './modules/ledger/ledger.module';
import { KycModule } from './modules/kyc/kyc.module';
import { PaymentsModule } from './modules/payments/payments.module';
import { AgentsModule } from './modules/agents/agents.module';
import { AdminModule } from './modules/admin/admin.module';
import { PayrollModule } from './modules/payroll/payroll.module';
import { CreditModule } from './modules/credit/credit.module';
import { CardsModule } from './modules/cards/cards.module';
import { RemittanceModule } from './modules/remittance/remittance.module';
import { FxModule } from './modules/fx/fx.module';

@Module({
  imports: [
    StoresModule,
    IdentityModule,
    CustomersModule,
    LedgerModule,
    KycModule,
    PaymentsModule,
    AgentsModule,
    AdminModule,
    PayrollModule,
    CreditModule,
    CardsModule,
    RemittanceModule,
    FxModule,
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
