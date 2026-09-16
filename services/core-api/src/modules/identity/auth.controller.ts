import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { IdentityService, RegisterInput, LoginInput } from './identity.service';

@Controller('v1/auth')
export class AuthController {
  constructor(private identityService: IdentityService) {}

  @Post('register')
  async register(@Body() input: RegisterInput) {
    return await this.identityService.register(input);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() input: LoginInput) {
    return await this.identityService.login(input);
  }
}
