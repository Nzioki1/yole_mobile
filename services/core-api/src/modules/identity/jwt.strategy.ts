import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { IdentityService } from './identity.service';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(private identityService: IdentityService) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET || 'dev-secret-change-in-production',
    });
  }

  async validate(payload: any) {
    const customer = await this.identityService.validateCustomer(payload.sub);
    if (!customer) {
      return null;
    }
    // Return sub for most controllers + customerId for KYC compatibility
    return { 
      sub: customer.id, 
      customerId: customer.id, 
      email: customer.email 
    };
  }
}
