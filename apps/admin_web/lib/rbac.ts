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
  | '/dashboard/cases'
  | '/dashboard/products'
  | '/dashboard/approvals'
  | '/dashboard/credit-exceptions'
  | '/dashboard/idempotency'
  | '/dashboard/remittance'
  | '/dashboard/resilience'
  | '/dashboard/export'
  | '/dashboard/users'
  | '/dashboard/aml-ban-list'
  | '/dashboard/customers';

const ALL_ADMIN: ModuleRoute[] = [
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
  '/dashboard/products',
  '/dashboard/approvals',
  '/dashboard/credit-exceptions',
  '/dashboard/idempotency',
  '/dashboard/remittance',
  '/dashboard/resilience',
  '/dashboard/export',
  '/dashboard/users',
  '/dashboard/aml-ban-list',
  '/dashboard/customers',
];

export const ROLE_PERMISSIONS: Record<StaffRole, ModuleRoute[]> = {
  [StaffRole.ADMIN]: ALL_ADMIN,
  [StaffRole.OPS]: [
    '/dashboard',
    '/dashboard/customer360',
    '/dashboard/kyc',
    '/dashboard/agents',
    '/dashboard/payments',
    '/dashboard/recon',
    '/dashboard/cases',
    '/dashboard/approvals',
    '/dashboard/credit-exceptions',
    '/dashboard/idempotency',
    '/dashboard/remittance',
    '/dashboard/products',
    '/dashboard/users',
    '/dashboard/aml-ban-list',
    '/dashboard/customers',
  ],
  [StaffRole.SUPPORT]: [
    '/dashboard',
    '/dashboard/customer360',
    '/dashboard/cases',
    '/dashboard/kyc',
    '/dashboard/agents',
    '/dashboard/remittance',
    '/dashboard/users',
    '/dashboard/aml-ban-list',
    '/dashboard/customers',
  ],
  [StaffRole.FINANCE]: [
    '/dashboard',
    '/dashboard/customer360',
    '/dashboard/payments',
    '/dashboard/cards',
    '/dashboard/payroll',
    '/dashboard/config',
    '/dashboard/recon',
    '/dashboard/products',
    '/dashboard/approvals',
    '/dashboard/credit-exceptions',
    '/dashboard/remittance',
    '/dashboard/export',
    '/dashboard/resilience',
    '/dashboard/idempotency',
    '/dashboard/users',
    '/dashboard/aml-ban-list',
    '/dashboard/customers',
  ],
};

export function canAccessRoute(role: StaffRole, route: string): boolean {
  const allowedRoutes = ROLE_PERMISSIONS[role];
  return allowedRoutes.some((r) => route === r || route.startsWith(r + '/'));
}

export function getAuthorizedRoutes(role: StaffRole): ModuleRoute[] {
  return ROLE_PERMISSIONS[role];
}
