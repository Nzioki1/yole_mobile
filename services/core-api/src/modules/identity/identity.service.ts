import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { CustomersService } from '../customers/customers.service';

export interface RegisterInput {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  phoneE164?: string;
}

export interface LoginInput {
  email: string;
  password: string;
}

export interface AuthResult {
  customerId: string;
  accessToken: string;
}

@Injectable()
export class IdentityService {
  constructor(
    private customersService: CustomersService,
    private jwtService: JwtService,
  ) {}

  async register(input: RegisterInput): Promise<AuthResult> {
    // Check if email already exists
    const existing = await this.customersService.findByEmail(input.email);
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    // Hash password
    const passwordHash = await bcrypt.hash(input.password, 10);

    // Create customer with wallet and pockets
    const customer = await this.customersService.createCustomer({
      email: input.email,
      phoneE164: input.phoneE164,
      firstName: input.firstName,
      lastName: input.lastName,
      passwordHash,
    });

    // Generate JWT
    const accessToken = this.jwtService.sign({
      sub: customer.id,
      email: customer.email,
    });

    return {
      customerId: customer.id,
      accessToken,
    };
  }

  async login(input: LoginInput): Promise<AuthResult> {
    // Find customer by email
    const customer = await this.customersService.findByEmail(input.email);
    if (!customer || !customer.passwordHash) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Verify password
    const passwordValid = await bcrypt.compare(
      input.password,
      customer.passwordHash,
    );
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate JWT
    const accessToken = this.jwtService.sign({
      sub: customer.id,
      email: customer.email,
    });

    return {
      customerId: customer.id,
      accessToken,
    };
  }

  async validateCustomer(customerId: string) {
    return await this.customersService.findById(customerId);
  }
}
