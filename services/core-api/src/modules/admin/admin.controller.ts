import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Injectable,
  CanActivate,
  ExecutionContext,
} from '@nestjs/common';
import { AdminService } from './admin.service';

// Simple admin API key guard
@Injectable()
export class AdminApiKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const apiKey = request.headers['x-admin-api-key'];
    return apiKey === 'dev-admin-key';
  }
}

@Controller('v1/admin')
@UseGuards(AdminApiKeyGuard)
export class AdminController {
  constructor(private adminService: AdminService) {}

  @Get('customers/:id/360')
  async getCustomer360(@Param('id') id: string) {
    return this.adminService.getCustomer360(id);
  }

  @Get('payments/search')
  async searchPayments(
    @Query('customerId') customerId?: string,
    @Query('status') status?: string,
    @Query('type') type?: string,
  ) {
    return this.adminService.searchPayments({ customerId, status, type });
  }

  @Get('config/fees')
  async listFeeConfigs() {
    return this.adminService.listFeeConfigs();
  }

  @Post('config/fees')
  async createFeeConfig(
    @Body()
    body: {
      paymentType: string;
      feePercent: number;
      minFeeMinor: string;
      maxFeeMinor: string;
    },
  ) {
    return this.adminService.createFeeConfig(body);
  }

  @Get('config/limits')
  async listLimitConfigs() {
    return this.adminService.listLimitConfigs();
  }

  @Post('config/limits')
  async createLimitConfig(
    @Body()
    body: {
      limitType: string;
      currency: string;
      dailyLimitMinor: string;
      monthlyLimitMinor: string;
    },
  ) {
    return this.adminService.createLimitConfig(body);
  }

  @Get('recon/daily')
  async getDailySummary(@Query('date') date: string) {
    return this.adminService.getDailySummary(date);
  }

  @Post('cases')
  async createCase(
    @Body() body: { type: string; description: string; customerId?: string },
  ) {
    return this.adminService.createCase(body);
  }

  @Get('cases')
  async listCases(@Query('status') status?: string) {
    return this.adminService.listCases(status);
  }

  @Post('cases/:id/decision')
  async updateCase(@Param('id') id: string, @Body() body: { decision: string }) {
    return this.adminService.updateCase(id, body.decision);
  }
}
