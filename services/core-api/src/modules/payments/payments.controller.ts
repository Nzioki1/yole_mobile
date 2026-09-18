import { Controller, Post, Get, Body, Param, UseGuards, Req, HttpCode, HttpStatus } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../identity/jwt-auth.guard';

@Controller('v1/payments')
@UseGuards(JwtAuthGuard)
export class PaymentsController {
  constructor(private paymentsService: PaymentsService) {}

  @Post('quote')
  @HttpCode(HttpStatus.OK)
  async quote(
    @Req() req: any,
    @Body()
    body: {
      type: string;
      currency: string;
      amountMinor: string;
      metadata?: Record<string, any>;
    },
  ) {
    const customerId = req.user.sub;
    return this.paymentsService.quote({
      customerId,
      type: body.type as any,
      currency: body.currency as any,
      amountMinor: BigInt(body.amountMinor),
      metadata: body.metadata,
    });
  }

  @Post('confirm')
  @HttpCode(HttpStatus.OK)
  async confirm(@Req() req: any, @Body() body: { paymentId: string }) {
    const customerId = req.user.sub;
    return this.paymentsService.confirm({
      paymentId: body.paymentId,
      customerId,
    });
  }

  @Get(':id')
  async getPayment(@Req() req: any, @Param('id') id: string) {
    const customerId = req.user.sub;
    return this.paymentsService.getPayment(id, customerId);
  }

  @Get()
  async listPayments(@Req() req: any) {
    const customerId = req.user.sub;
    return this.paymentsService.listPayments(customerId);
  }
}
