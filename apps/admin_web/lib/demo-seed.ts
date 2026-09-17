/**
 * Compatibility shim — NOT a second source of truth.
 * Seed data lives in packages/demo_universe (loadUniverse / OfflineDemoStore).
 * Kept so existing imports (login helpers, charts) keep compiling during migration.
 */
import { loadUniverse } from 'demo_universe';
import { OFFLINE_DEMO } from './offline/flags';
import { getOfflineStore } from './offline/store';

/** Prefer hard offline flag; retain DEMO_SEED env for transitional Mac Color Admin work. */
export const DEMO_SEED_ENABLED =
  OFFLINE_DEMO ||
  (typeof process !== 'undefined' ? process.env.NEXT_PUBLIC_DEMO_SEED !== 'false' : true);

const universeSnapshot = () => loadUniverse();

export const DEMO_STAFF = universeSnapshot().staff.map((s) => ({
  id: s.id,
  email: s.email,
  password: s.password,
  role: s.role,
  firstName: s.firstName || s.role,
  lastName: s.lastName || 'User',
}));

export const DEMO_CUSTOMERS = universeSnapshot().customers;
export const DEMO_PAYMENTS = getOfflineStore().searchPayments();
export const DEMO_KYC = getOfflineStore().listKycSubmissions();
export const DEMO_AGENTS = getOfflineStore().listAgents();
export const DEMO_CASES = getOfflineStore().listCases();
export const DEMO_CARDS = getOfflineStore().listCards();
export const DEMO_EMPLOYERS = getOfflineStore().listEmployers();
export const DEMO_FEES = getOfflineStore().listFeeConfigs();
export const DEMO_LIMITS = getOfflineStore().listLimitConfigs();

export function getDemoDashboardSummary() {
  return getOfflineStore().getDashboardSummary();
}

export function getDemoCustomer360(customerId: string) {
  return getOfflineStore().getCustomer360(customerId);
}

export function getDemoRecon(date: string) {
  return getOfflineStore().getDailySummary(date);
}

export function filterDemoPayments(filters?: {
  customerId?: string;
  status?: string;
  type?: string;
}) {
  return getOfflineStore().searchPayments(filters);
}

export function filterDemoCases(status?: string) {
  return getOfflineStore().listCases(status);
}

export function filterDemoCards(customerId?: string) {
  return getOfflineStore().listCards(customerId);
}

export function filterDemoKyc(status?: string) {
  return getOfflineStore().listKycSubmissions(status);
}

/** Build an unsigned JWT the browser can decode (demo only — not verified server-side). */
export function mintDemoStaffToken(staff: { id: string; email: string; role: string }): string {
  const header = btoa(JSON.stringify({ alg: 'none', typ: 'JWT' }))
    .replace(/=+$/, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  const exp = Math.floor(Date.now() / 1000) + 7 * 24 * 3600;
  const payload = btoa(
    JSON.stringify({
      sub: staff.id,
      email: staff.email,
      role: staff.role,
      iat: Math.floor(Date.now() / 1000),
      exp,
    }),
  )
    .replace(/=+$/, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  return `${header}.${payload}.demo`;
}
