import { Module } from '@nestjs/common';
import { KycService } from './kyc.service';
import { KycController, AdminKycController } from './kyc.controller';
import { LocalFileSystemStorage } from './kyc-storage.port';
import { StubScreeningService } from './screening.port';

@Module({
  controllers: [KycController, AdminKycController],
  providers: [
    KycService,
    {
      provide: 'KYC_STORAGE',
      useValue: new LocalFileSystemStorage('./services/core-api/.data/kyc'),
    },
    {
      provide: LocalFileSystemStorage,
      useValue: new LocalFileSystemStorage('./services/core-api/.data/kyc'),
    },
    {
      provide: 'SCREENING',
      useClass: StubScreeningService,
    },
    {
      provide: StubScreeningService,
      useClass: StubScreeningService,
    },
  ],
  exports: [KycService],
})
export class KycModule {}
