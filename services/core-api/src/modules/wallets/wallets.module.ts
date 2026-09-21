import { Module } from '@nestjs/common';
import { WalletsService } from './wallets.service';
import { WalletsController, MeController } from './wallets.controller';

@Module({
  controllers: [WalletsController, MeController],
  providers: [WalletsService],
  exports: [WalletsService],
})
export class WalletsModule {}
