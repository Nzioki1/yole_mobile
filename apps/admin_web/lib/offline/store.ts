import { loadUniverse } from 'demo_universe';
import type {
  Universe,
  Staff,
  Customer,
  Wallet,
  Payment,
  Loan,
  Card,
  Case,
  KycSubmission,
  Agent,
  Employer,
  Employee,
  FeeLimit,
  ReconDay,
} from 'demo_universe';

function strMinor(n: number | string | undefined | null): string {
  if (n === undefined || n === null) return '0';
  return String(n);
}

function paymentForAdmin(p: Payment) {
  return {
    ...p,
    amountMinor: strMinor(p.amountMinor),
    feeMinor: strMinor(p.feeMinor),
    totalMinor: strMinor(p.totalMinor),
    updatedAt: p.createdAt,
  };
}

function cardForAdmin(c: Card) {
  return {
    ...c,
    dailyLimitMinor: strMinor(c.dailyLimitMinor),
    monthlyLimitMinor: strMinor(c.monthlyLimitMinor),
  };
}

function walletForAdmin(w: Wallet) {
  return {
    ...w,
    availableMinor: strMinor(w.availableMinor),
    ledgerMinor: strMinor(w.ledgerMinor),
    blockedMinor: strMinor(w.blockedMinor),
    pendingMinor: strMinor(w.pendingMinor),
    // Compat for pocket-based Color Admin / legacy 360 UI
    pockets: [
      {
        id: `${w.id}_pocket`,
        currency: w.currency,
        availableMinor: strMinor(w.availableMinor),
        ledgerMinor: strMinor(w.ledgerMinor),
        blockedMinor: strMinor(w.blockedMinor),
        pendingOutMinor: strMinor(w.pendingMinor),
        pendingInMinor: '0',
      },
    ],
  };
}

function feeForAdmin(f: FeeLimit) {
  const feePercent = f.feePercent ?? 0;
  const feeType = feePercent > 0 ? 'PERCENT' : 'FLAT';
  return {
    id: f.id,
    paymentType: f.paymentType,
    feeType,
    value: feePercent > 0 ? `${feePercent}%` : strMinor(f.minFeeMinor),
    currency: f.currency || 'USD',
    feePercent,
    minFeeMinor: strMinor(f.minFeeMinor),
    maxFeeMinor: strMinor(f.maxFeeMinor),
    status: f.status,
    effectiveFrom: f.effectiveFrom,
  };
}

function limitForAdmin(f: FeeLimit) {
  const currency = f.currency || 'USD';
  const daily = f.dailyLimitMinor ?? 0;
  const monthly = f.monthlyLimitMinor ?? 0;
  const fmt = (n: number) =>
    currency === 'CDF' ? `FC ${n.toLocaleString()}` : `$${(n / 100).toFixed(2)}`;
  return {
    id: f.id,
    limitType: f.limitType,
    kycTier: 'TIER_1',
    currency,
    dailyLimitMinor: strMinor(daily),
    monthlyLimitMinor: strMinor(monthly),
    dailyLimit: fmt(daily),
    monthlyLimit: fmt(monthly),
    value: `${fmt(daily)} / ${fmt(monthly)}`,
    status: f.status,
    effectiveFrom: f.effectiveFrom,
  };
}

export type Customer360 = {
  customer: Customer;
  wallets: ReturnType<typeof walletForAdmin>[];
  recentPayments: ReturnType<typeof paymentForAdmin>[];
  loans: Loan[];
  cards: ReturnType<typeof cardForAdmin>[];
  cases: Case[];
};

/**
 * In-memory admin offline store backed by shared demo_universe seed.
 * Session mutations stay local; call reset() to reload from universe.
 */
export class OfflineDemoStore {
  private u: Universe;

  private constructor(universe: Universe) {
    this.u = universe;
  }

  static createFresh(): OfflineDemoStore {
    return new OfflineDemoStore(loadUniverse());
  }

  /** Reload seed graph (discards session mutations). */
  reset(): void {
    this.u = loadUniverse();
  }

  listStaff(): Staff[] {
    return this.u.staff.slice();
  }

  authenticateStaff(email: string, password: string): Staff | null {
    const normalized = email.trim().toLowerCase();
    const staff = this.u.staff.find(
      (s) => s.email.toLowerCase() === normalized && s.password === password,
    );
    return staff ?? null;
  }

  getDashboardCounts() {
    const s = this.getDashboardSummary();
    return {
      customers: this.u.customers.length,
      payments: s.kpis.paymentsToday,
      pendingKyc: s.kpis.pendingKyc,
      agents: s.kpis.activeAgents,
    };
  }

  getDashboardSummary() {
    const paymentsByStatus: Record<string, number> = {};
    const paymentsByType: Record<string, number> = {};
    for (const p of this.u.payments) {
      paymentsByStatus[p.status] = (paymentsByStatus[p.status] || 0) + 1;
      paymentsByType[p.type] = (paymentsByType[p.type] || 0) + 1;
    }
    const today = new Date().toISOString().slice(0, 10);
    return {
      kpis: {
        pendingKyc: this.u.kyc.filter((k) =>
          ['PENDING_REVIEW', 'PENDING', 'SUBMITTED'].includes(k.status),
        ).length,
        openCases: this.u.cases.filter((c) =>
          ['OPEN', 'PENDING', 'IN_PROGRESS', 'INVESTIGATION'].includes(c.status),
        ).length,
        paymentsToday: this.u.payments.filter((p) => p.createdAt.slice(0, 10) === today)
          .length,
        activeAgents: this.u.agents.filter((a) => a.status === 'ACTIVE').length,
        totalCards: this.u.cards.length,
      },
      paymentsByStatus: Object.entries(paymentsByStatus).map(([status, count]) => ({
        status,
        count,
      })),
      paymentsByType: Object.entries(paymentsByType).map(([type, count]) => ({
        type,
        count,
      })),
      honesty: this.u.meta.honesty,
    };
  }

  getCustomer360(customerId: string): Customer360 {
    const customer =
      this.u.customers.find((c) => c.id === customerId) ||
      ({
        id: customerId,
        firstName: 'Unknown',
        lastName: 'Customer',
        email: `${customerId}@demo.yole.com`,
        password: '',
        phoneE164: null,
        segment: 'OPEN',
        kycStatus: 'PENDING',
        createdAt: new Date().toISOString(),
      } as Customer);

    const wallets = this.u.wallets
      .filter((w) => w.customerId === customerId)
      .map(walletForAdmin);

    const recentPayments = this.u.payments
      .filter((p) => p.customerId === customerId)
      .slice()
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt))
      .slice(0, 12)
      .map(paymentForAdmin);

    const loans = this.u.loans.filter((l) => l.customerId === customerId);
    const cards = this.u.cards.filter((c) => c.customerId === customerId).map(cardForAdmin);
    const cases = this.u.cases.filter((c) => c.customerId === customerId);

    return { customer, wallets, recentPayments, loans, cards, cases };
  }

  listKycSubmissions(status?: string): KycSubmission[] {
    if (!status) return this.u.kyc.slice();
    return this.u.kyc.filter((k) => k.status === status);
  }

  makeKycDecision(submissionId: string, decision: string, reason?: string) {
    const row = this.u.kyc.find((k) => k.id === submissionId);
    const status = decision === 'APPROVE' || decision === 'APPROVED' ? 'APPROVED' : 'REJECTED';
    if (row) {
      row.status = status;
      row.reviewNotes = reason || row.reviewNotes || 'Offline demo decision';
      row.updatedAt = new Date().toISOString();
      const cust = this.u.customers.find((c) => c.id === row.customerId);
      if (cust) cust.kycStatus = status === 'APPROVED' ? 'APPROVED' : 'REJECTED';
    }
    return {
      id: submissionId,
      decision,
      reason: reason || 'Demo decision',
      status,
    };
  }

  listAgents(): Agent[] {
    return this.u.agents.slice();
  }

  enrollAgent(data: {
    firstName: string;
    lastName: string;
    phoneE164: string;
    email?: string;
  }) {
    const id = `agent_demo_${Date.now()}`;
    const agent: Agent = {
      id,
      name: `${data.firstName} ${data.lastName}`.trim(),
      firstName: data.firstName,
      lastName: data.lastName,
      phoneE164: data.phoneE164,
      floatCdfMinor: 0,
      floatUsdMinor: 0,
      floatWalletId: `wal_float_${id}`,
      status: 'ACTIVE',
      createdAt: new Date().toISOString(),
    };
    if (data.email) agent.email = data.email;
    this.u.agents.push(agent);
    return agent;
  }

  searchPayments(filters?: { customerId?: string; status?: string; type?: string }) {
    return this.u.payments
      .filter((p) => {
        if (filters?.customerId && p.customerId !== filters.customerId) return false;
        if (filters?.status && p.status !== filters.status) return false;
        if (
          filters?.type &&
          p.type !== filters.type &&
          !(filters.type === 'BILL_PAY' && p.type === 'BILL')
        ) {
          return false;
        }
        return true;
      })
      .map(paymentForAdmin);
  }

  listFeeConfigs() {
    return this.u.feeLimits.filter((f) => f.kind === 'FEE').map(feeForAdmin);
  }

  createFeeConfig(data: Record<string, unknown>) {
    const id = `fee_demo_${Date.now()}`;
    const feePercent = Number(data.feePercent ?? 0);
    const row: FeeLimit = {
      id,
      kind: 'FEE',
      paymentType: String(data.paymentType || 'W2W'),
      feePercent,
      minFeeMinor: Number(data.minFeeMinor ?? 0),
      maxFeeMinor: Number(data.maxFeeMinor ?? 0),
      currency: String(data.currency || 'USD'),
      effectiveFrom: new Date().toISOString().slice(0, 10),
      status: 'ACTIVE',
    };
    this.u.feeLimits.push(row);
    return feeForAdmin(row);
  }

  listLimitConfigs() {
    return this.u.feeLimits.filter((f) => f.kind === 'LIMIT').map(limitForAdmin);
  }

  listCards(customerId?: string) {
    const list = customerId
      ? this.u.cards.filter((c) => c.customerId === customerId)
      : this.u.cards.slice();
    return list.map(cardForAdmin);
  }

  listEmployers() {
    return this.u.employers.map((e) => {
      const employees = this.u.employees
        .filter((emp) => emp.employerId === e.id)
        .map((emp) => ({
          customerId: emp.customerId,
          salaryMinor: strMinor(emp.netSalaryCdfMinor),
          currency: 'CDF',
          employeeNumber: emp.employeeNumber,
          jobTitle: emp.jobTitle,
          status: emp.status,
        }));
      return {
        ...e,
        employeeCount: e.employeeCount ?? employees.length,
        employees,
      };
    });
  }

  createEmployer(data: { name: string; taxId: string }) {
    const id = `emp_demo_${Date.now()}`;
    const employer: Employer = {
      id,
      name: data.name,
      taxId: data.taxId,
      employeeCount: 0,
      createdAt: new Date().toISOString(),
    };
    this.u.employers.push(employer);
    return { ...employer, employees: [] as Employee[] };
  }

  importEmployees(
    employerId: string,
    employees: { customerId: string; salaryMinor: string; currency: string }[],
  ) {
    for (const row of employees) {
      const id = `emp_row_demo_${Date.now()}_${row.customerId}`;
      this.u.employees.push({
        id,
        employerId,
        customerId: row.customerId,
        employeeNumber: id,
        grossSalaryCdfMinor: Number(row.salaryMinor),
        netSalaryCdfMinor: Number(row.salaryMinor),
        eligibleAdvanceMaxCdfMinor: Math.floor(Number(row.salaryMinor) / 2),
        status: 'ACTIVE',
        hiredAt: new Date().toISOString().slice(0, 10),
      });
    }
    const employer = this.u.employers.find((e) => e.id === employerId);
    if (employer) {
      employer.employeeCount = this.u.employees.filter((e) => e.employerId === employerId).length;
    }
    return { employerId, imported: employees.length, employees };
  }

  creditSalaries(employerId: string) {
    const employees = this.u.employees.filter((e) => e.employerId === employerId);
    let total = 0;
    for (const emp of employees) {
      total += emp.netSalaryCdfMinor;
      this.u.salaryHistory.push({
        id: `sal_demo_${Date.now()}_${emp.id}`,
        employeeId: emp.id,
        customerId: emp.customerId,
        period: new Date().toISOString().slice(0, 7),
        grossCdfMinor: emp.grossSalaryCdfMinor,
        netCdfMinor: emp.netSalaryCdfMinor,
        paidAt: new Date().toISOString(),
      });
    }
    return {
      employerId,
      credited: true,
      count: employees.length,
      totalMinor: strMinor(total),
      message: 'Offline demo salary credit posted',
    };
  }

  getDailySummary(date: string) {
    const day: ReconDay | undefined =
      this.u.reconDays.find((r) => r.businessDate === date) || this.u.reconDays[0];
    const payments = this.u.payments;
    const totalVolume = payments.reduce((s, p) => s + Number(p.amountMinor), 0);
    return {
      date: day?.businessDate || date,
      totalTransactions: payments.length,
      totalVolumeMinor: strMinor(totalVolume),
      status: day?.status || 'BALANCED',
      matchedCount: day?.matchedCount,
      exceptionCount: day?.exceptionCount,
      details: {
        exceptions: day?.exceptions || [],
        eodSnapshot: day?.eodSnapshot || {},
        rails: {},
        ledgerDeltaMinor: '0',
      },
    };
  }

  listCases(status?: string) {
    if (!status) return this.u.cases.slice();
    return this.u.cases.filter((c) => c.status === status);
  }

  createCase(data: { type: string; description: string; customerId?: string }) {
    const row: Case = {
      id: `case_demo_${Date.now()}`,
      type: data.type,
      description: data.description,
      customerId: data.customerId ?? null,
      status: 'PENDING',
      createdAt: new Date().toISOString(),
    };
    this.u.cases.push(row);
    return row;
  }

  updateCase(caseId: string, status: string) {
    const row = this.u.cases.find((c) => c.id === caseId);
    if (row) {
      row.status = status;
      if (['RESOLVED', 'CLOSED', 'APPROVED', 'REJECTED'].includes(status)) {
        row.decidedAt = new Date().toISOString();
      }
    }
    return { id: caseId, status };
  }
}

let singleton: OfflineDemoStore | null = null;

export function getOfflineStore(): OfflineDemoStore {
  if (!singleton) {
    singleton = OfflineDemoStore.createFresh();
  }
  return singleton;
}

/** Discard singleton and create a fresh store from universe seed. */
export function resetOfflineStore(): OfflineDemoStore {
  singleton = OfflineDemoStore.createFresh();
  return singleton;
}
