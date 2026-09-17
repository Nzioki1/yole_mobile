export enum StaffRole {
  ADMIN = 'ADMIN',
  OPS = 'OPS',
  SUPPORT = 'SUPPORT',
  FINANCE = 'FINANCE',
}

export interface StaffUser {
  id: string;
  email: string;
  passwordHash: string;
  role: StaffRole;
  firstName: string;
  lastName: string;
}
