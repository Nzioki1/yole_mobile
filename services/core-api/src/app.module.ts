import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';
import { IdentityModule } from './modules/identity/identity.module';
import { CustomersModule } from './modules/customers/customers.module';

@Module({
  imports: [IdentityModule, CustomersModule],
  controllers: [HealthController],
  providers: [],
})
export class AppModule {}
