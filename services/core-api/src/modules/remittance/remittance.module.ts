import { Module } from '@nestjs/common';
import { RemittanceService } from './remittance.service';
import { RemittanceController } from './remittance.controller';
import { LedgerModule } from '../ledger/ledger.module';

@Module({
  imports: [LedgerModule],
  controllers: [RemittanceController],
  providers: [RemittanceService],
  exports: [RemittanceService],
})
export class RemittanceModule {}
