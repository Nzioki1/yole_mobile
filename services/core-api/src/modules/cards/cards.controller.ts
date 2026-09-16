import { Controller, Post, Get, Put, Body, Param, UseGuards, Req } from '@nestjs/common';
import { CardsService } from './cards.service';
import { JwtAuthGuard } from '../identity/jwt-auth.guard';

@Controller('v1/cards')
@UseGuards(JwtAuthGuard)
export class CardsController {
  constructor(private cardsService: CardsService) {}

  @Post()
  async issueCard(
    @Req() req: any,
    @Body()
    body: {
      walletPocketId: string;
      currency: string;
      dailyLimitMinor: string;
      monthlyLimitMinor: string;
    },
  ) {
    const customerId = req.user.sub;
    return this.cardsService.issueCard({
      customerId,
      walletPocketId: body.walletPocketId,
      currency: body.currency as any,
      dailyLimitMinor: BigInt(body.dailyLimitMinor),
      monthlyLimitMinor: BigInt(body.monthlyLimitMinor),
    });
  }

  @Put(':id/freeze')
  async freezeCard(@Req() req: any, @Param('id') id: string) {
    const customerId = req.user.sub;
    return this.cardsService.freezeCard(id, customerId);
  }

  @Put(':id/activate')
  async activateCard(@Req() req: any, @Param('id') id: string) {
    const customerId = req.user.sub;
    return this.cardsService.activateCard(id, customerId);
  }

  @Put(':id/block')
  async blockCard(@Req() req: any, @Param('id') id: string) {
    const customerId = req.user.sub;
    return this.cardsService.blockCard(id, customerId);
  }

  @Put(':id/limits')
  async setLimits(
    @Req() req: any,
    @Param('id') id: string,
    @Body() body: { dailyLimitMinor: string; monthlyLimitMinor: string },
  ) {
    const customerId = req.user.sub;
    return this.cardsService.setLimits(id, customerId, {
      dailyLimitMinor: BigInt(body.dailyLimitMinor),
      monthlyLimitMinor: BigInt(body.monthlyLimitMinor),
    });
  }

  @Get()
  async listCards(@Req() req: any) {
    const customerId = req.user.sub;
    return this.cardsService.listCards(customerId);
  }

  @Get(':id/transactions')
  async listTransactions(@Req() req: any, @Param('id') id: string) {
    const customerId = req.user.sub;
    return this.cardsService.listTransactions(id, customerId);
  }

  @Post(':id/mock-auth')
  async mockAuthorization(
    @Param('id') id: string,
    @Body() body: { amountMinor: string; merchantName: string },
  ) {
    return this.cardsService.mockAuthorization(id, BigInt(body.amountMinor), body.merchantName);
  }
}
