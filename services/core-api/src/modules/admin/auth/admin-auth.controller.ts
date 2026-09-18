import { Controller, Post, Get, Body, HttpCode, HttpStatus, UseGuards, Req } from '@nestjs/common';
import { AdminAuthService, AdminLoginInput } from './admin-auth.service';
import { AdminJwtAuthGuard } from './admin-jwt-auth.guard';

@Controller('v1/admin/auth')
export class AdminAuthController {
  constructor(private adminAuthService: AdminAuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() input: AdminLoginInput) {
    return await this.adminAuthService.login(input);
  }

  @Get('me')
  @UseGuards(AdminJwtAuthGuard)
  async getMe(@Req() req: any) {
    const userId = req.user.userId;
    const user = await this.adminAuthService.validateStaffUser(userId);
    
    if (!user) {
      return { error: 'User not found' };
    }

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
    };
  }
}
