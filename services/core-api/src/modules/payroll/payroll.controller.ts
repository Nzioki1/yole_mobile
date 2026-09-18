import { Controller, Post, Get, Body, Param, UseGuards, Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { PayrollService } from './payroll.service';

@Injectable()
class AdminApiKeyGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    return request.headers['x-admin-api-key'] === 'dev-admin-key';
  }
}

@Controller('v1/admin/payroll')
@UseGuards(AdminApiKeyGuard)
export class PayrollController {
  constructor(private payrollService: PayrollService) {}

  @Post('employers')
  async createEmployer(@Body() body: { name: string; taxId: string }) {
    return this.payrollService.createEmployer(body);
  }

  @Get('employers')
  async listEmployers() {
    return this.payrollService.listEmployers();
  }

  @Post('employers/:id/employees/import')
  async importEmployees(
    @Param('id') id: string,
    @Body() body: { employees: Array<{ customerId: string; salaryMinor: string; currency: string }> },
  ) {
    return this.payrollService.importEmployees(id, body.employees);
  }

  @Post('employers/:id/salary/credit')
  async creditSalary(@Param('id') id: string, @Body() body: { employeeIds: string[] }) {
    return this.payrollService.creditSalary(id, body.employeeIds);
  }
}
