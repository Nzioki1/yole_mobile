import { Controller, Get, UseGuards, Req } from '@nestjs/common';
import { WalletsService } from './wallets.service';
import { JwtAuthGuard } from '../identity/jwt-auth.guard';

@Controller('v1/wallets')
@UseGuards(JwtAuthGuard)
export class WalletsController {
  constructor(private walletsService: WalletsService) {}

  @Get('me')
  async getMyWallets(@Req() req: any) {
    const customerId = req.user.sub;
    return this.walletsService.getCustomerWallets(customerId);
  }
}

// Add limits endpoint to v1 root
@Controller('v1/me')
@UseGuards(JwtAuthGuard)
export class MeController {
  constructor(private walletsService: WalletsService) {}

  @Get('limits')
  async getMyLimits(@Req() req: any) {
    const customerId = req.user.sub;
    return this.walletsService.getCustomerLimits(customerId);
  }
}
