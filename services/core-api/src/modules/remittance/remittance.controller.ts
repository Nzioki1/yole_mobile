import { Controller, Post, Get, Body, Param, UseGuards, Req } from '@nestjs/common';
import { RemittanceService } from './remittance.service';
import { JwtAuthGuard } from '../identity/jwt-auth.guard';

@Controller('v1/remittance')
@UseGuards(JwtAuthGuard)
export class RemittanceController {
  constructor(private remittanceService: RemittanceService) {}

  @Post('inbound/quote')
  async quoteInbound(@Req() req: any, @Body() body: { amountMinor: string; currency: string }) {
    const customerId = req.user.sub;
    return this.remittanceService.quoteInbound({
      customerId,
      amountMinor: BigInt(body.amountMinor),
      currency: body.currency as any,
    });
  }

  @Post('inbound/:id/confirm')
  async confirmInbound(@Param('id') id: string) {
    return this.remittanceService.confirmInbound(id);
  }

  @Post('outbound/quote')
  async quoteOutbound(@Req() req: any, @Body() body: { amountMinor: string; currency: string }) {
    const customerId = req.user.sub;
    return this.remittanceService.quoteOutbound({
      customerId,
      amountMinor: BigInt(body.amountMinor),
      currency: body.currency as any,
    });
  }

  @Get()
  async listRemittances(@Req() req: any) {
    const customerId = req.user.sub;
    return this.remittanceService.listRemittances(customerId);
  }
}
