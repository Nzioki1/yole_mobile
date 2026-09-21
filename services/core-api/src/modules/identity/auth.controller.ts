import { Controller, Post, Get, Body, HttpCode, HttpStatus, UseGuards, Req } from '@nestjs/common';
import { IdentityService, RegisterInput, LoginInput } from './identity.service';
import { OtpService } from './otp.service';
import { JwtAuthGuard } from './jwt-auth.guard';

@Controller('v1/auth')
export class AuthController {
  constructor(
    private identityService: IdentityService,
    private otpService: OtpService,
  ) {}

  @Post('register')
  async register(@Body() input: RegisterInput) {
    return await this.identityService.register(input);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() input: LoginInput) {
    return await this.identityService.login(input);
  }

  @Post('otp/request')
  @HttpCode(HttpStatus.OK)
  async requestOtp(@Body() body: { phoneE164: string }) {
    await this.otpService.requestOtp(body.phoneE164);
    return { message: 'OTP sent' };
  }

  @Post('otp/verify')
  @HttpCode(HttpStatus.OK)
  async verifyOtp(@Body() body: { phoneE164: string; code: string }) {
    const isValid = await this.otpService.verifyOtp(body.phoneE164, body.code);
    if (!isValid) {
      return { verified: false };
    }
    return { verified: true };
  }

  @Post('pin/set')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async setPin(@Req() req: any, @Body() body: { pin: string }) {
    const customerId = req.user.sub;
    return this.identityService.setPin(customerId, body.pin);
  }

  @Post('pin/verify')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async verifyPin(@Req() req: any, @Body() body: { pin: string }) {
    const customerId = req.user.sub;
    return this.identityService.verifyPin(customerId, body.pin);
  }

  @Get('pin/has')
  @UseGuards(JwtAuthGuard)
  async hasPin(@Req() req: any) {
    const customerId = req.user.sub;
    return this.identityService.hasPin(customerId);
  }
}
