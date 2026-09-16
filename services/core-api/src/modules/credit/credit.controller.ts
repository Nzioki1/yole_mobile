import { Controller, Post, Get, Body, Param, UseGuards, Req } from '@nestjs/common';
import { CreditService } from './credit.service';
import { JwtAuthGuard } from '../identity/jwt-auth.guard';

@Controller('v1/credit')
@UseGuards(JwtAuthGuard)
export class CreditController {
  constructor(private creditService: CreditService) {}

  @Get('eligibility/:type')
  async checkEligibility(@Req() req: any, @Param('type') type: string) {
    const customerId = req.user.sub;
    return this.creditService.checkEligibility(customerId, type as any);
  }

  @Post('loans')
  async requestLoan(
    @Req() req: any,
    @Body()
    body: {
      type: string;
      principalMinor: string;
      currency: string;
      termMonths: number;
    },
  ) {
    const customerId = req.user.sub;
    return this.creditService.requestLoan({
      customerId,
      type: body.type as any,
      principalMinor: BigInt(body.principalMinor),
      currency: body.currency as any,
      termMonths: body.termMonths,
    });
  }

  @Get('loans')
  async listLoans(@Req() req: any) {
    const customerId = req.user.sub;
    return this.creditService.listLoans(customerId);
  }

  @Get('loans/:id')
  async getLoan(@Param('id') id: string) {
    return this.creditService.getLoan(id);
  }
}
