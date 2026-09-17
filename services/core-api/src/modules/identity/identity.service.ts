import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { CustomersService } from '../customers/customers.service';
import { NotificationsService } from '../notifications/notifications.service';

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
  customer?: any; // Full customer object for client convenience
}

@Injectable()
export class IdentityService {
  private pinStore = new Map<string, string>(); // customerId -> hashed PIN

  constructor(
    private customersService: CustomersService,
    private jwtService: JwtService,
    private notificationsService: NotificationsService,
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

    // Send welcome notification
    await this.notificationsService.seedWelcomeNotification(customer.id);

    // Generate JWT
    const accessToken = this.jwtService.sign({
      sub: customer.id,
      email: customer.email,
    });

    return {
      customerId: customer.id,
      accessToken,
      customer: {
        id: customer.id,
        email: customer.email,
        firstName: customer.firstName,
        lastName: customer.lastName,
        phoneE164: customer.phoneE164,
        status: customer.status,
      },
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
      customer: {
        id: customer.id,
        email: customer.email,
        firstName: customer.firstName,
        lastName: customer.lastName,
        phoneE164: customer.phoneE164,
        status: customer.status,
      },
    };
  }

  async validateCustomer(customerId: string) {
    return await this.customersService.findById(customerId);
  }

  async setPin(customerId: string, pin: string) {
    if (!/^\d{4,6}$/.test(pin)) {
      throw new Error('PIN must be 4-6 digits');
    }
    const hashedPin = await bcrypt.hash(pin, 10);
    this.pinStore.set(customerId, hashedPin);
    return { success: true };
  }

  async verifyPin(customerId: string, pin: string) {
    const hashedPin = this.pinStore.get(customerId);
    if (!hashedPin) {
      throw new Error('No PIN set for this customer');
    }
    const isValid = await bcrypt.compare(pin, hashedPin);
    if (!isValid) {
      throw new Error('Invalid PIN');
    }
    return { success: true };
  }

  async hasPin(customerId: string) {
    return { hasPin: this.pinStore.has(customerId) };
  }
}
