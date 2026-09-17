import { StaffRole } from './auth';

export type ModuleRoute =
  | '/dashboard'
  | '/dashboard/customer360'
  | '/dashboard/kyc'
  | '/dashboard/agents'
  | '/dashboard/payments'
  | '/dashboard/cards'
  | '/dashboard/payroll'
  | '/dashboard/config'
  | '/dashboard/recon'
  | '/dashboard/cases';

export const ROLE_PERMISSIONS: Record<StaffRole, ModuleRoute[]> = {
  [StaffRole.ADMIN]: [
    '/dashboard',
    '/dashboard/customer360',
    '/dashboard/kyc',
    '/dashboard/agents',
    '/dashboard/payments',
    '/dashboard/cards',
    '/dashboard/payroll',
    '/dashboard/config',
    '/dashboard/recon',
    '/dashboard/cases',
  ],
  [StaffRole.OPS]: [
    '/dashboard',
    '/dashboard/kyc',
    '/dashboard/agents',
    '/dashboard/payments',
    '/dashboard/recon',
    '/dashboard/cases',
  ],
  [StaffRole.SUPPORT]: [
    '/dashboard',
    '/dashboard/customer360',
    '/dashboard/cases',
  ],
  [StaffRole.FINANCE]: [
    '/dashboard',
    '/dashboard/payments',
    '/dashboard/cards',
    '/dashboard/payroll',
    '/dashboard/config',
    '/dashboard/recon',
  ],
};

export function canAccessRoute(role: StaffRole, route: string): boolean {
  const allowedRoutes = ROLE_PERMISSIONS[role];
  return allowedRoutes.some(r => route === r || route.startsWith(r + '/'));
}

export function getAuthorizedRoutes(role: StaffRole): ModuleRoute[] {
  return ROLE_PERMISSIONS[role];
}
