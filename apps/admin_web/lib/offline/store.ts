import { loadUniverse } from 'demo_universe';
import type {
  Universe,
  Staff,
  Customer,
  Wallet,
  Payment,
  Loan,
  LoanSchedule,
  Card,
  Case,
  KycSubmission,
  Agent,
  Employer,
  Employee,
  FeeLimit,
  ReconDay,
  Journal,
  Notification,
  Product,
  PendingApproval,
  Remittance,
  CardAuth,
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

function nowIso() {
  return new Date().toISOString();
}

export type Customer360 = {
  customer: Customer;
  wallets: ReturnType<typeof walletForAdmin>[];
  recentPayments: ReturnType<typeof paymentForAdmin>[];
  loans: Loan[];
  loanSchedules: LoanSchedule[];
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
        email: `${customerId}@demo.postefinance.com`,
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
    const loanSchedules = this.u.loanSchedules.filter((s) =>
      loans.some((l) => l.id === s.loanId || l.scheduleId === s.id),
    );
    const cards = this.u.cards.filter((c) => c.customerId === customerId).map(cardForAdmin);
    const cases = this.u.cases.filter((c) => c.customerId === customerId);

    return { customer, wallets, recentPayments, loans, loanSchedules, cards, cases };
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

  listCardAuths(cardId?: string) {
    if (!cardId) return this.u.cardAuths.slice();
    return this.u.cardAuths.filter((a) => a.cardId === cardId);
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
    const eod = day?.eodSnapshot || {};
    return {
      date: day?.businessDate || date,
      totalTransactions: payments.length,
      totalVolumeMinor: strMinor(totalVolume),
      status: day?.status || 'BALANCED',
      matchedCount: day?.matchedCount,
      exceptionCount: day?.exceptionCount,
      details: {
        exceptions: day?.exceptions || [],
        unmatched: day?.exceptions || [],
        eodSnapshot: eod,
        suspenseMinor: strMinor((eod as { suspenseMinor?: number }).suspenseMinor ?? 0),
        glBalanced: Boolean((eod as { glBalanced?: boolean }).glBalanced),
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

  // ─── DEM list helpers ─────────────────────────────────────────────

  listProducts(): Product[] {
    return this.u.products.slice();
  }

  listPendingApprovals(status?: string): PendingApproval[] {
    if (!status) return this.u.pendingApprovals.slice();
    return this.u.pendingApprovals.filter((a) => a.status === status);
  }

  listCreditExceptions() {
    return this.u.loans.filter((l) =>
      ['PENDING_EXCEPTION', 'EXCEPTION', 'REJECTED_EXCEPTION'].includes(l.status) ||
      l.status === 'PENDING_EXCEPTION',
    );
  }

  listLoans(customerId?: string) {
    if (!customerId) return this.u.loans.slice();
    return this.u.loans.filter((l) => l.customerId === customerId);
  }

  getLoanSchedule(scheduleId: string): LoanSchedule | null {
    return this.u.loanSchedules.find((s) => s.id === scheduleId) || null;
  }

  listRemittances(status?: string): Remittance[] {
    if (!status) return this.u.remittances.slice();
    return this.u.remittances.filter((r) => r.status === status);
  }

  listJournals(filters?: { customerId?: string; refId?: string; walletId?: string }): Journal[] {
    return this.u.journals.filter((j) => {
      if (filters?.customerId && j.customerId !== filters.customerId) return false;
      if (filters?.refId && j.refId !== filters.refId) return false;
      if (filters?.walletId && j.walletId !== filters.walletId) return false;
      return true;
    });
  }

  listNotifications(filters?: { customerId?: string }): Notification[] {
    if (!filters?.customerId) return this.u.notifications.slice();
    return this.u.notifications.filter((n) => n.customerId === filters.customerId);
  }

  getHonesty() {
    return this.u.meta.honesty || {
      globalBadge: 'Offline demo — no live API',
      cardsBadge: 'MOCK — not Visa/Mastercard certified',
      resilienceBadge: 'DEMO STORYBOARD — not a live HA failover',
    };
  }

  // ─── DEM mutations ────────────────────────────────────────────────

  /**
   * DEM-02: approve/reject pendingApprovals. FEE_CHANGE activates pending fee.
   */
  approvePending(approvalId: string, decision: string, _approverStaffId?: string) {
    const apr = this.u.pendingApprovals.find((a) => a.id === approvalId);
    if (!apr) throw new Error(`Approval not found: ${approvalId}`);
    const approved = decision === 'APPROVE' || decision === 'APPROVED';
    apr.status = approved ? 'APPROVED' : 'REJECTED';

    if (apr.type === 'FEE_CHANGE') {
      const pendingFee = this.u.feeLimits.find((f) => f.id === apr.targetId);
      if (pendingFee) {
        if (approved) {
          // Supersede other ACTIVE fees of same paymentType
          for (const f of this.u.feeLimits) {
            if (
              f.kind === 'FEE' &&
              f.paymentType === pendingFee.paymentType &&
              f.id !== pendingFee.id &&
              f.status === 'ACTIVE'
            ) {
              f.status = 'SUPERSEDED';
            }
          }
          pendingFee.status = 'ACTIVE';
        } else {
          pendingFee.status = 'REJECTED';
        }
      }
    }

    if (apr.type === 'CREDIT_EXCEPTION' && approved) {
      this.decideCreditException(apr.targetId, 'APPROVE');
    }

    if (apr.type === 'AML_CASE' && approved) {
      this.advanceAmlCase(apr.targetId, 'APPROVE', { approverRole: 'ADMIN' });
    }

    return { id: approvalId, status: apr.status, type: apr.type, targetId: apr.targetId };
  }

  /**
   * DEM-04: approve PENDING_EXCEPTION → ACTIVE + schedule + wallet credit + journal.
   */
  decideCreditException(loanId: string, decision: string) {
    const loan = this.u.loans.find((l) => l.id === loanId);
    if (!loan) throw new Error(`Loan not found: ${loanId}`);

    const approved = decision === 'APPROVE' || decision === 'APPROVED';
    if (!approved) {
      loan.status = 'REJECTED_EXCEPTION';
      const apr = this.u.pendingApprovals.find(
        (a) => a.type === 'CREDIT_EXCEPTION' && a.targetId === loanId && a.status === 'PENDING',
      );
      if (apr) apr.status = 'REJECTED';
      return { id: loanId, status: loan.status, scheduleId: loan.scheduleId ?? null };
    }

    const scheduleId = `sched_${loanId}`;
    const half = Math.floor(loan.principalMinor / 2);
    const interest = Math.floor(loan.principalMinor * 0.05);
    const schedule: LoanSchedule = {
      id: scheduleId,
      loanId: loan.id,
      installments: [
        {
          id: `${scheduleId}_inst_1`,
          dueDate: new Date(Date.now() + 14 * 86400000).toISOString().slice(0, 10),
          principalMinor: half,
          interestMinor: interest,
          status: 'DUE',
          paidAt: null,
        },
        {
          id: `${scheduleId}_inst_2`,
          dueDate: new Date(Date.now() + 44 * 86400000).toISOString().slice(0, 10),
          principalMinor: loan.principalMinor - half,
          interestMinor: interest,
          status: 'DUE',
          paidAt: null,
        },
      ],
    };
    // replace if exists
    const existingIdx = this.u.loanSchedules.findIndex((s) => s.loanId === loan.id);
    if (existingIdx >= 0) this.u.loanSchedules[existingIdx] = schedule;
    else this.u.loanSchedules.push(schedule);

    loan.status = 'ACTIVE';
    loan.scheduleId = scheduleId;
    loan.receivableMinor = loan.principalMinor + interest * 2;
    loan.disbursedAt = nowIso();

    const wallet =
      this.u.wallets.find((w) => w.customerId === loan.customerId && w.currency === loan.currency) ||
      this.u.wallets.find((w) => w.customerId === loan.customerId);
    if (wallet) {
      wallet.availableMinor += loan.principalMinor;
      wallet.ledgerMinor += loan.principalMinor;
      const jnl: Journal = {
        id: `jnl_disburse_${loan.id}`,
        customerId: loan.customerId,
        walletId: wallet.id,
        type: 'LOAN_DISBURSEMENT',
        direction: 'CREDIT',
        currency: loan.currency,
        amountMinor: loan.principalMinor,
        balanceAfterMinor: wallet.availableMinor,
        refType: 'LOAN',
        refId: loan.id,
        narration: `Credit exception approved — ${loan.productId}`,
        postedAt: nowIso(),
      };
      this.u.journals.push(jnl);
    }

    const apr = this.u.pendingApprovals.find(
      (a) => a.type === 'CREDIT_EXCEPTION' && a.targetId === loanId && a.status === 'PENDING',
    );
    if (apr) apr.status = 'APPROVED';

    this.u.notifications.push({
      id: `ntf_loan_${loan.id}_${Date.now()}`,
      customerId: loan.customerId,
      channel: 'PUSH',
      title: 'Loan disbursed',
      body: `Credit exception approved — ${loan.currency} ${loan.principalMinor / 100} credited`,
      read: false,
      createdAt: nowIso(),
    });

    return { id: loanId, status: loan.status, scheduleId };
  }

  /**
   * DEM-05: Compensate posts reversing journal + notification; marks payment COMPENSATED.
   */
  compensatePayment(paymentId: string) {
    const pay = this.u.payments.find((p) => p.id === paymentId);
    if (!pay) throw new Error(`Payment not found: ${paymentId}`);
    if (pay.status === 'COMPENSATED') {
      return { id: paymentId, status: 'COMPENSATED', alreadyCompensated: true };
    }

    pay.status = 'COMPENSATED';
    const walletId =
      (pay.sourceRef && this.u.wallets.some((w) => w.id === pay.sourceRef)
        ? pay.sourceRef
        : null) ||
      this.u.wallets.find((w) => w.customerId === pay.customerId && w.currency === pay.currency)
        ?.id ||
      this.u.wallets.find((w) => w.customerId === pay.customerId)?.id;

    if (walletId) {
      const wallet = this.u.wallets.find((w) => w.id === walletId)!;
      // Reverse original debit → credit customer back
      wallet.availableMinor += pay.totalMinor || pay.amountMinor;
      wallet.ledgerMinor += pay.totalMinor || pay.amountMinor;
      const jnl: Journal = {
        id: `jnl_comp_${paymentId}`,
        customerId: pay.customerId,
        walletId,
        type: 'COMPENSATION',
        direction: 'CREDIT',
        currency: pay.currency,
        amountMinor: pay.totalMinor || pay.amountMinor,
        balanceAfterMinor: wallet.availableMinor,
        refType: 'PAYMENT',
        refId: paymentId,
        narration: `Compensation for ${paymentId}`,
        postedAt: nowIso(),
      };
      this.u.journals.push(jnl);
      pay.journalId = jnl.id;
    }

    this.u.notifications.push({
      id: `ntf_comp_${paymentId}_${Date.now()}`,
      customerId: pay.customerId,
      channel: 'PUSH',
      title: 'Payment compensated',
      body: `Payment ${paymentId} was compensated — funds restored`,
      read: false,
      createdAt: nowIso(),
    });

    return { id: paymentId, status: 'COMPENSATED', journalId: pay.journalId };
  }

  /**
   * DEM-05: Replay same idempotency key returns the same payment (no duplicate).
   */
  replayIdempotentConfirm(idempotencyKey: string, _payload?: Record<string, unknown>) {
    const existing = this.u.payments.find((p) => p.idempotencyKey === idempotencyKey);
    if (existing) {
      return {
        payment: paymentForAdmin(existing),
        replayed: true,
        message: 'Idempotent replay — same payment returned, no duplicate posted',
      };
    }
    // If key unknown, create a demo payment once then subsequent calls return it
    const id = `pay_idem_${Date.now()}`;
    const pay: Payment = {
      id,
      customerId: 'cust_kasee',
      type: 'W2W',
      status: 'POSTED',
      currency: 'USD',
      amountMinor: 1000,
      feeMinor: 10,
      totalMinor: 1010,
      sourceRef: 'wal_kasee_usd',
      destRef: 'cust_amina',
      journalId: null,
      idempotencyKey,
      createdAt: nowIso(),
      notes: 'Idempotency lab first confirm',
    };
    this.u.payments.push(pay);
    return {
      payment: paymentForAdmin(pay),
      replayed: false,
      message: 'First confirm — payment posted',
    };
  }

  /**
   * DEM-08 remittance actions: CLEAR / RELEASE / REFUND / HOLD + partner recon stub.
   */
  remittanceAction(remittanceId: string, action: string) {
    const rmt = this.u.remittances.find((r) => r.id === remittanceId);
    if (!rmt) throw new Error(`Remittance not found: ${remittanceId}`);
    const act = action.toUpperCase();

    if (act === 'CLEAR' || act === 'RELEASE' || act === 'APPROVE') {
      rmt.status = 'CLEARED';
      const wallet =
        (rmt.walletId && this.u.wallets.find((w) => w.id === rmt.walletId)) ||
        this.u.wallets.find(
          (w) => w.customerId === rmt.customerId && w.currency === rmt.receiveCurrency,
        );
      if (wallet) {
        rmt.walletId = wallet.id;
        wallet.availableMinor += rmt.receiveAmountMinor;
        wallet.ledgerMinor += rmt.receiveAmountMinor;
        this.u.journals.push({
          id: `jnl_rmt_${rmt.id}`,
          customerId: rmt.customerId,
          walletId: wallet.id,
          type: 'REMITTANCE',
          direction: 'CREDIT',
          currency: rmt.receiveCurrency,
          amountMinor: rmt.receiveAmountMinor,
          balanceAfterMinor: wallet.availableMinor,
          refType: 'REMITTANCE',
          refId: rmt.id,
          narration: `Remittance cleared from ${rmt.partner}`,
          postedAt: nowIso(),
        });
      }
    } else if (act === 'REFUND') {
      rmt.status = 'REFUNDED';
    } else if (act === 'HOLD' || act === 'SCREEN') {
      rmt.status = 'SCREENING_HIT';
    } else if (act === 'PARTNER_RECON') {
      return {
        id: remittanceId,
        status: rmt.status,
        partnerRecon: {
          partner: rmt.partner,
          matched: rmt.status === 'CLEAR' || rmt.status === 'CLEARED',
          stub: true,
          message: 'Partner recon stub — offline demo only',
        },
      };
    }

    return { id: remittanceId, status: rmt.status, action: act };
  }

  /**
   * DEM-09: AML confidential workflow — Investigate → Recommend → maker-checker.
   */
  advanceAmlCase(
    caseId: string,
    action: string,
    opts?: { approverRole?: string; recommendation?: string },
  ) {
    const row = this.u.cases.find((c) => c.id === caseId);
    if (!row) throw new Error(`Case not found: ${caseId}`);
    const act = action.toUpperCase();
    const steps = row.steps || ['ALERT', 'INVESTIGATION', 'RECOMMEND', 'MAKER_CHECKER'];
    if (!row.steps) row.steps = steps;

    if (act === 'INVESTIGATE') {
      row.currentStep = 'INVESTIGATION';
      row.status = 'INVESTIGATION';
    } else if (act === 'RECOMMEND') {
      row.currentStep = 'RECOMMEND';
      row.status = 'PENDING_APPROVAL';
      (row as Case & { recommendation?: string }).recommendation =
        opts?.recommendation || 'ESCALATE';
      (row as Case & { approverRole?: string }).approverRole = opts?.approverRole || 'ADMIN';
    } else if (act === 'APPROVE' || act === 'APPROVED') {
      row.currentStep = 'MAKER_CHECKER';
      row.status = 'APPROVED';
      row.decidedAt = nowIso();
      (row as Case & { approverRole?: string }).approverRole = opts?.approverRole || 'ADMIN';
      const apr = this.u.pendingApprovals.find(
        (a) => a.type === 'AML_CASE' && a.targetId === caseId && a.status === 'PENDING',
      );
      if (apr) apr.status = 'APPROVED';
    } else if (act === 'REJECT' || act === 'DENIED') {
      row.currentStep = 'MAKER_CHECKER';
      row.status = 'REJECTED';
      row.decidedAt = nowIso();
      (row as Case & { approverRole?: string }).approverRole = opts?.approverRole || 'ADMIN';
      const apr = this.u.pendingApprovals.find(
        (a) => a.type === 'AML_CASE' && a.targetId === caseId && a.status === 'PENDING',
      );
      if (apr) apr.status = 'REJECTED';
    }

    return {
      id: caseId,
      status: row.status,
      currentStep: row.currentStep,
      confidential: row.confidential,
      approverRole: (row as Case & { approverRole?: string }).approverRole,
    };
  }

  /**
   * DEM-11: Run EOD writes snapshot on recon day (GL balanced, clears suspense demo).
   */
  runEod(businessDate?: string) {
    const date = businessDate || this.u.reconDays[0]?.businessDate || new Date().toISOString().slice(0, 10);
    let day = this.u.reconDays.find((r) => r.businessDate === date);
    if (!day) {
      day = {
        id: `recon_${date}`,
        businessDate: date,
        status: 'OPEN',
        matchedCount: 0,
        exceptionCount: 0,
        exceptions: [],
        eodSnapshot: {},
      };
      this.u.reconDays.push(day);
    }

    const debit = this.u.journals
      .filter((j) => j.direction === 'DEBIT')
      .reduce((s, j) => s + j.amountMinor, 0);
    const credit = this.u.journals
      .filter((j) => j.direction === 'CREDIT')
      .reduce((s, j) => s + j.amountMinor, 0);

    day.eodSnapshot = {
      runAt: nowIso(),
      glBalanced: true,
      suspenseMinor: 0,
      currency: 'CDF',
      notes: 'DEM-11 EOD run — offline demo snapshot',
      journalDebitMinor: debit,
      journalCreditMinor: credit,
      bodReady: true,
    };
    day.status = day.exceptionCount > 0 ? 'EOD_COMPLETE_WITH_EXCEPTIONS' : 'EOD_COMPLETE';
    day.matchedCount = Math.max(day.matchedCount, this.u.payments.length);

    return {
      businessDate: day.businessDate,
      status: day.status,
      eodSnapshot: day.eodSnapshot,
    };
  }

  /**
   * DEM-12: Build open-format export pack JSON.
   */
  buildExportPack() {
    const pack = {
      exportedAt: nowIso(),
      format: 'yole-demo-export/v1',
      filename: 'poste-finance-demo-export.json',
      honesty: this.getHonesty(),
      customers: this.u.customers.map(({ password: _p, ...rest }) => rest),
      wallets: this.u.wallets,
      loans: this.u.loans,
      loanSchedules: this.u.loanSchedules,
      payments: this.u.payments,
      journals: this.u.journals,
      cases: this.u.cases,
      remittances: this.u.remittances,
      cards: this.u.cards,
      cardAuths: this.u.cardAuths,
      products: this.u.products,
      feeLimits: this.u.feeLimits,
      reconDays: this.u.reconDays,
      notifications: this.u.notifications,
      agents: this.u.agents.map(({ password: _p, ...rest }) => rest),
      employers: this.u.employers,
      employees: this.u.employees,
    };
    return pack;
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
