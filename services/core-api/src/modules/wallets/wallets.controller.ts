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
