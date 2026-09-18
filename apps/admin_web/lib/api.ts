const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

import { OFFLINE_DEMO } from './offline/flags';
import { getOfflineStore } from './offline/store';
import {
  DEMO_SEED_ENABLED,
  DEMO_AGENTS,
  DEMO_EMPLOYERS,
  DEMO_FEES,
  DEMO_LIMITS,
  filterDemoPayments,
  filterDemoCases,
  filterDemoCards,
  filterDemoKyc,
  getDemoCustomer360,
  getDemoDashboardSummary,
  getDemoRecon,
} from './demo-seed';

export class AdminApiClient {
  private apiKey: string;

  constructor(apiKey: string = 'dev-admin-key') {
    this.apiKey = apiKey;
  }

  private async request(endpoint: string, options: RequestInit = {}) {
    if (OFFLINE_DEMO) {
      throw new Error('OFFLINE_DEMO: fetch disabled — use OfflineDemoStore path');
    }
    const headers = {
      'Content-Type': 'application/json',
      'X-Admin-API-Key': this.apiKey,
      ...options.headers,
    };

    const response = await fetch(`${API_BASE_URL}${endpoint}`, {
      ...options,
      headers,
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.statusText}`);
    }

    return response.json();
  }

  private preferSeed() {
    return !OFFLINE_DEMO && DEMO_SEED_ENABLED;
  }

  private store() {
    return getOfflineStore();
  }

  async getDashboardCounts() {
    if (OFFLINE_DEMO) return this.store().getDashboardCounts();
    if (this.preferSeed()) {
      const s = getDemoDashboardSummary();
      return {
        customers: 4,
        payments: s.kpis.paymentsToday,
        pendingKyc: s.kpis.pendingKyc,
        agents: s.kpis.activeAgents,
      };
    }
    return { customers: 0, payments: 0, pendingKyc: 0, agents: 0 };
  }

  async getDashboardSummary() {
    if (OFFLINE_DEMO) return this.store().getDashboardSummary();
    if (this.preferSeed()) return getDemoDashboardSummary();
    try {
      return await this.request('/v1/admin/dashboard/summary');
    } catch {
      return getDemoDashboardSummary();
    }
  }

  async getCustomer360(customerId: string) {
    if (OFFLINE_DEMO) return this.store().getCustomer360(customerId);
    if (this.preferSeed()) return getDemoCustomer360(customerId);
    try {
      return await this.request(`/v1/admin/customers/${customerId}/360`);
    } catch {
      return getDemoCustomer360(customerId);
    }
  }

  async listKycSubmissions(status?: string) {
    if (OFFLINE_DEMO) return this.store().listKycSubmissions(status);
    if (this.preferSeed()) return filterDemoKyc(status);
    try {
      const query = status ? `?status=${status}` : '';
      const data = await this.request(`/v1/admin/kyc/submissions${query}`);
      const list = Array.isArray(data) ? data : data.submissions || [];
      return list.length ? list : filterDemoKyc(status);
    } catch {
      return filterDemoKyc(status);
    }
  }

  async makeKycDecision(submissionId: string, decision: string, reason?: string) {
    if (OFFLINE_DEMO) return this.store().makeKycDecision(submissionId, decision, reason);
    if (this.preferSeed()) {
      return {
        id: submissionId,
        decision,
        reason: reason || 'Demo decision',
        status: decision === 'APPROVE' ? 'APPROVED' : 'REJECTED',
      };
    }
    return this.request(`/v1/admin/kyc/submissions/${submissionId}/decision`, {
      method: 'POST',
      body: JSON.stringify({ decision, reason }),
    });
  }

  async listAgents() {
    if (OFFLINE_DEMO) return this.store().listAgents();
    if (this.preferSeed()) return DEMO_AGENTS;
    try {
      const data = await this.request('/v1/admin/agents');
      const list = Array.isArray(data) ? data : data.agents || [];
      return list.length ? list : DEMO_AGENTS;
    } catch {
      return DEMO_AGENTS;
    }
  }

  async enrollAgent(data: {
    firstName: string;
    lastName: string;
    phoneE164: string;
    email?: string;
  }) {
    if (OFFLINE_DEMO) return this.store().enrollAgent(data);
    if (this.preferSeed()) {
      return {
        id: `agent_demo_${Date.now()}`,
        ...data,
        email: data.email || null,
        status: 'ACTIVE',
        floatWalletId: `wal_demo_${Date.now()}`,
        createdAt: new Date().toISOString(),
      };
    }
    return this.request('/v1/admin/agents', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async listStaff() {
    if (OFFLINE_DEMO) return this.store().listStaff();
    throw new Error('listStaff is only available in offline demo');
  }

  async createStaff(data: {
    firstName: string;
    lastName: string;
    email: string;
    password: string;
    role: string;
  }) {
    if (OFFLINE_DEMO) return this.store().createStaff(data);
    throw new Error('createStaff is only available in offline demo');
  }

  async updateStaffRole(staffId: string, role: string) {
    if (OFFLINE_DEMO) return this.store().updateStaffRole(staffId, role);
    throw new Error('updateStaffRole is only available in offline demo');
  }

  async searchPayments(filters?: { customerId?: string; status?: string; type?: string }) {
    if (OFFLINE_DEMO) return this.store().searchPayments(filters);
    if (this.preferSeed()) return filterDemoPayments(filters);
    try {
      const params = new URLSearchParams(filters as Record<string, string>);
      const data = await this.request(`/v1/admin/payments/search?${params}`);
      const list = Array.isArray(data) ? data : data.payments || [];
      return list.length ? list : filterDemoPayments(filters);
    } catch {
      return filterDemoPayments(filters);
    }
  }

  async listFeeConfigs() {
    if (OFFLINE_DEMO) return this.store().listFeeConfigs();
    if (this.preferSeed()) return DEMO_FEES;
    try {
      const data = await this.request('/v1/admin/config/fees');
      const list = Array.isArray(data) ? data : data.fees || [];
      return list.length ? list : DEMO_FEES;
    } catch {
      return DEMO_FEES;
    }
  }

  async createFeeConfig(data: any) {
    if (OFFLINE_DEMO) return this.store().createFeeConfig(data);
    if (this.preferSeed()) {
      return {
        id: `fee_demo_${Date.now()}`,
        ...data,
        feeType: 'PERCENT',
        value: `${data.feePercent || 0}%`,
        currency: 'USD',
      };
    }
    return this.request('/v1/admin/config/fees', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async proposeFeeRule(data: {
    paymentType: string;
    feePercent: number;
    minFeeMinor: number;
    maxFeeMinor: number;
    currency?: string;
    effectiveFrom?: string;
    summary?: string;
    makerStaffId?: string;
    supersedesId?: string;
  }) {
    if (OFFLINE_DEMO) return this.store().proposeFeeRule(data);
    throw new Error('proposeFeeRule is only available in offline demo');
  }

  async proposeLimitRule(data: {
    limitType: string;
    currency: string;
    dailyLimitMinor: number;
    monthlyLimitMinor: number;
    effectiveFrom?: string;
    summary?: string;
    makerStaffId?: string;
    supersedesId?: string;
  }) {
    if (OFFLINE_DEMO) return this.store().proposeLimitRule(data);
    throw new Error('proposeLimitRule is only available in offline demo');
  }

  async listLimitConfigs() {
    if (OFFLINE_DEMO) return this.store().listLimitConfigs();
    if (this.preferSeed()) return DEMO_LIMITS;
    try {
      const data = await this.request('/v1/admin/config/limits');
      const list = Array.isArray(data) ? data : data.limits || [];
      return list.length ? list : DEMO_LIMITS;
    } catch {
      return DEMO_LIMITS;
    }
  }

  async listCards(customerId?: string) {
    if (OFFLINE_DEMO) return this.store().listCards(customerId);
    if (this.preferSeed()) return filterDemoCards(customerId);
    try {
      const query = customerId ? `?customerId=${customerId}` : '';
      const data = await this.request(`/v1/admin/cards${query}`);
      const list = Array.isArray(data) ? data : data.cards || [];
      return list.length ? list : filterDemoCards(customerId);
    } catch {
      return filterDemoCards(customerId);
    }
  }

  async listEmployers() {
    if (OFFLINE_DEMO) return this.store().listEmployers();
    if (this.preferSeed()) return DEMO_EMPLOYERS;
    try {
      const data = await this.request('/v1/admin/payroll/employers');
      const list = Array.isArray(data) ? data : data.employers || [];
      return list.length ? list : DEMO_EMPLOYERS;
    } catch {
      return DEMO_EMPLOYERS;
    }
  }

  async createEmployer(data: { name: string; taxId: string }) {
    if (OFFLINE_DEMO) return this.store().createEmployer(data);
    if (this.preferSeed()) {
      return { id: `emp_demo_${Date.now()}`, ...data, employeeCount: 0, employees: [] };
    }
    return this.request('/v1/admin/payroll/employers', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async importEmployees(
    employerId: string,
    employees: { customerId: string; salaryMinor: string; currency: string }[],
  ) {
    if (OFFLINE_DEMO) return this.store().importEmployees(employerId, employees);
    if (this.preferSeed()) {
      return { employerId, imported: employees.length, employees };
    }
    return this.request(`/v1/admin/payroll/employers/${employerId}/employees/import`, {
      method: 'POST',
      body: JSON.stringify({ employees }),
    });
  }

  async creditSalaries(employerId: string) {
    if (OFFLINE_DEMO) return this.store().creditSalaries(employerId);
    if (this.preferSeed()) {
      return {
        employerId,
        credited: true,
        count: 3,
        totalMinor: '195000',
        message: 'Demo salary credit posted',
      };
    }
    return this.request(`/v1/admin/payroll/employers/${employerId}/salary/credit`, {
      method: 'POST',
    });
  }

  async listSalaryHistory(employerId: string) {
    if (OFFLINE_DEMO) return this.store().listSalaryHistory(employerId);
    throw new Error('listSalaryHistory is only available in offline demo');
  }

  async getDailySummary(date: string) {
    if (OFFLINE_DEMO) return this.store().getDailySummary(date);
    if (this.preferSeed()) return getDemoRecon(date);
    try {
      return await this.request(`/v1/admin/recon/daily?date=${date}`);
    } catch {
      return getDemoRecon(date);
    }
  }

  async listCases(status?: string) {
    if (OFFLINE_DEMO) return this.store().listCases(status);
    if (this.preferSeed()) return filterDemoCases(status);
    try {
      const query = status ? `?status=${status}` : '';
      const data = await this.request(`/v1/admin/cases${query}`);
      const list = Array.isArray(data) ? data : data.cases || [];
      return list.length ? list : filterDemoCases(status);
    } catch {
      return filterDemoCases(status);
    }
  }

  async createCase(data: { type: string; description: string; customerId?: string }) {
    if (OFFLINE_DEMO) return this.store().createCase(data);
    if (this.preferSeed()) {
      return {
        id: `case_demo_${Date.now()}`,
        ...data,
        status: 'PENDING',
        createdAt: new Date().toISOString(),
      };
    }
    return this.request('/v1/admin/cases', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateCase(caseId: string, status: string) {
    if (OFFLINE_DEMO) return this.store().updateCase(caseId, status);
    if (this.preferSeed()) {
      return { id: caseId, status };
    }
    return this.request(`/v1/admin/cases/${caseId}/status`, {
      method: 'PUT',
      body: JSON.stringify({ status }),
    });
  }

  async listProducts() {
    if (OFFLINE_DEMO) return this.store().listProducts();
    return [];
  }

  async listPendingApprovals(status?: string) {
    if (OFFLINE_DEMO) return this.store().listPendingApprovals(status);
    return [];
  }

  async approvePending(approvalId: string, decision: string, approverStaffId?: string) {
    if (OFFLINE_DEMO) return this.store().approvePending(approvalId, decision, approverStaffId);
    throw new Error('approvePending requires OFFLINE_DEMO');
  }

  async listCreditExceptions() {
    if (OFFLINE_DEMO) return this.store().listCreditExceptions();
    return [];
  }

  async decideCreditException(loanId: string, decision: string) {
    if (OFFLINE_DEMO) return this.store().decideCreditException(loanId, decision);
    throw new Error('decideCreditException requires OFFLINE_DEMO');
  }

  async getLoanSchedule(scheduleId: string) {
    if (OFFLINE_DEMO) return this.store().getLoanSchedule(scheduleId);
    return null;
  }

  async listLoans(customerId?: string) {
    if (OFFLINE_DEMO) return this.store().listLoans(customerId);
    return [];
  }

  async compensatePayment(paymentId: string) {
    if (OFFLINE_DEMO) return this.store().compensatePayment(paymentId);
    throw new Error('compensatePayment requires OFFLINE_DEMO');
  }

  async replayIdempotentConfirm(idempotencyKey: string, payload?: Record<string, unknown>) {
    if (OFFLINE_DEMO) return this.store().replayIdempotentConfirm(idempotencyKey, payload);
    throw new Error('replayIdempotentConfirm requires OFFLINE_DEMO');
  }

  async listRemittances(status?: string) {
    if (OFFLINE_DEMO) return this.store().listRemittances(status);
    return [];
  }

  async remittanceAction(remittanceId: string, action: string) {
    if (OFFLINE_DEMO) return this.store().remittanceAction(remittanceId, action);
    throw new Error('remittanceAction requires OFFLINE_DEMO');
  }

  async advanceAmlCase(caseId: string, action: string, opts?: { approverRole?: string; recommendation?: string }) {
    if (OFFLINE_DEMO) return this.store().advanceAmlCase(caseId, action, opts);
    throw new Error('advanceAmlCase requires OFFLINE_DEMO');
  }

  async listJournals(filters?: { customerId?: string; refId?: string; walletId?: string }) {
    if (OFFLINE_DEMO) return this.store().listJournals(filters);
    return [];
  }

  async listNotifications(filters?: { customerId?: string }) {
    if (OFFLINE_DEMO) return this.store().listNotifications(filters);
    return [];
  }

  async listCardAuths(cardId?: string) {
    if (OFFLINE_DEMO) return this.store().listCardAuths(cardId);
    return [];
  }

  async runEod(businessDate?: string) {
    if (OFFLINE_DEMO) return this.store().runEod(businessDate);
    throw new Error('runEod requires OFFLINE_DEMO');
  }

  async buildExportPack() {
    if (OFFLINE_DEMO) return this.store().buildExportPack();
    throw new Error('buildExportPack requires OFFLINE_DEMO');
  }

  async getHonesty() {
    if (OFFLINE_DEMO) return this.store().getHonesty();
    return {
      globalBadge: 'Offline demo — no live API',
      cardsBadge: 'MOCK — not Visa/Mastercard certified',
      resilienceBadge: 'DEMO STORYBOARD — not a live HA failover',
    };
  }

  async listAmlBanList() {
    if (OFFLINE_DEMO) return this.store().listAmlBanList();
    throw new Error('listAmlBanList is only available in offline demo');
  }

  async addAmlBanEntry(data: Parameters<ReturnType<typeof getOfflineStore>['addAmlBanEntry']>[0]) {
    if (OFFLINE_DEMO) return this.store().addAmlBanEntry(data);
    throw new Error('addAmlBanEntry is only available in offline demo');
  }

  async liftAmlBanEntry(id: string) {
    if (OFFLINE_DEMO) return this.store().liftAmlBanEntry(id);
    throw new Error('liftAmlBanEntry is only available in offline demo');
  }

  async listCustomers() {
    if (OFFLINE_DEMO) return this.store().listCustomers();
    throw new Error('listCustomers is only available in offline demo');
  }

}

export const api = new AdminApiClient();
