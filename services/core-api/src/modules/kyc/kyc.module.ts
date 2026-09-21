import { Module } from '@nestjs/common';
import { KycService } from './kyc.service';
import { KycController, AdminKycController } from './kyc.controller';

@Module({
  controllers: [KycController, AdminKycController],
  providers: [KycService],
  exports: [KycService],
})
export class KycModule {}
