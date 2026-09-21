import { Controller, Post, Get, Body, Query, UseGuards, Req } from '@nestjs/common';
import { FxService } from './fx.service';
import { JwtAuthGuard } from '../identity/jwt-auth.guard';

@Controller('v1/fx')
@UseGuards(JwtAuthGuard)
export class FxController {
  constructor(private fxService: FxService) {}

  @Get('rates')
  async getRates() {
    return this.fxService.getRates();
  }

  @Get('rate')
  async getRate(@Query('from') from: string, @Query('to') to: string) {
    return this.fxService.getRate(from, to);
  }

  @Post('convert')
  async convert(
    @Req() req: any,
    @Body()
    body: {
      fromCurrency: string;
      toCurrency: string;
      fromAmountMinor: string;
    },
  ) {
    const customerId = req.user.sub;
    return this.fxService.convert({
      customerId,
      fromCurrency: body.fromCurrency,
      toCurrency: body.toCurrency,
      fromAmountMinor: BigInt(body.fromAmountMinor),
    });
  }
}
