import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { IdentityService } from './identity.service';
import { AuthController } from './auth.controller';
import { JwtStrategy } from './jwt.strategy';
import { CustomersModule } from '../customers/customers.module';

@Module({
  imports: [
    CustomersModule,
    PassportModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'dev-secret-change-in-production',
      signOptions: { expiresIn: '7d' },
    }),
  ],
  controllers: [AuthController],
  providers: [IdentityService, JwtStrategy],
  exports: [IdentityService],
})
export class IdentityModule {}
