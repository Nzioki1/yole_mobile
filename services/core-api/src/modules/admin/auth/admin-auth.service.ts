import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { StaffRole, StaffUser } from './staff-roles.enum';

export interface AdminLoginInput {
  email: string;
  password: string;
}

export interface AdminAuthResult {
  accessToken: string;
  user: {
    id: string;
    email: string;
    role: StaffRole;
    firstName: string;
    lastName: string;
  };
}

@Injectable()
export class AdminAuthService {
  private staffUsers: Map<string, StaffUser> = new Map();

  constructor(private jwtService: JwtService) {
    this.seedStaffUsers();
  }

  private async seedStaffUsers() {
    const password = 'Password1!';
    const passwordHash = await bcrypt.hash(password, 10);

    const users: Omit<StaffUser, 'passwordHash'>[] = [
      {
        id: 'admin-001',
        email: 'admin@yole.com',
        role: StaffRole.ADMIN,
        firstName: 'Admin',
        lastName: 'User',
      },
      {
        id: 'ops-001',
        email: 'ops@yole.com',
        role: StaffRole.OPS,
        firstName: 'Operations',
        lastName: 'User',
      },
      {
        id: 'support-001',
        email: 'support@yole.com',
        role: StaffRole.SUPPORT,
        firstName: 'Support',
        lastName: 'User',
      },
      {
        id: 'finance-001',
        email: 'finance@yole.com',
        role: StaffRole.FINANCE,
        firstName: 'Finance',
        lastName: 'User',
      },
    ];

    for (const user of users) {
      this.staffUsers.set(user.email.toLowerCase(), {
        ...user,
        passwordHash,
      });
    }
  }

  async login(input: AdminLoginInput): Promise<AdminAuthResult> {
    const user = this.staffUsers.get(input.email.toLowerCase());
    
    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordValid = await bcrypt.compare(input.password, user.passwordHash);
    
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const accessToken = this.jwtService.sign({
      sub: user.id,
      email: user.email,
      role: user.role,
    });

    return {
      accessToken,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        firstName: user.firstName,
        lastName: user.lastName,
      },
    };
  }

  async validateStaffUser(userId: string): Promise<StaffUser | null> {
    for (const user of this.staffUsers.values()) {
      if (user.id === userId) {
        return user;
      }
    }
    return null;
  }

  getUserByEmail(email: string): StaffUser | undefined {
    return this.staffUsers.get(email.toLowerCase());
  }
}
