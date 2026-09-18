// Mock API client for demo purposes
// Implements same interface as api.ts but returns mock data

import {
  MOCK_CUSTOMERS,
  MOCK_AGENTS,
  MOCK_PAYMENTS,
  MOCK_KYC_SUBMISSIONS,
  MOCK_CARDS,
  MOCK_EMPLOYERS,
  MOCK_CASES,
  MOCK_WALLETS,
  MOCK_FEES,
  MOCK_LIMITS,
  type Payment,
  type KycSubmission,
  type Agent,
  type Card,
  type Employer,
  type Case,
} from './mockData';

// Simulated network delay
const delay = (ms: number = 200) => new Promise(resolve => setTimeout(resolve, ms));

// Local storage helpers for persistence
const getLocalData = <T>(key: string, defaultValue: T): T => {
  if (typeof window === 'undefined') return defaultValue;
  try {
    const stored = localStorage.getItem(key);
    return stored ? JSON.parse(stored) : defaultValue;
  } catch {
    return defaultValue;
  }
};

const setLocalData = <T>(key: string, value: T): void => {
  if (typeof window === 'undefined') return;
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch (e) {
    console.warn('Failed to save to localStorage:', e);
  }
};

// Initialize local storage with mock data if not present
const initializeLocalStorage = () => {
  if (typeof window === 'undefined') return;
  
  if (!localStorage.getItem('mock_kyc_submissions')) {
    setLocalData('mock_kyc_submissions', MOCK_KYC_SUBMISSIONS);
  }
  if (!localStorage.getItem('mock_agents')) {
    setLocalData('mock_agents', MOCK_AGENTS);
  }
  if (!localStorage.getItem('mock_employers')) {
    setLocalData('mock_employers', MOCK_EMPLOYERS);
  }
  if (!localStorage.getItem('mock_cases')) {
    setLocalData('mock_cases', MOCK_CASES);
  }
};

// Initialize on module load
initializeLocalStorage();

export class MockAdminApiClient {
  // Dashboard summary
  async getDashboardSummary() {
    await delay();
    
    const payments = MOCK_PAYMENTS;
    const kycSubmissions = getLocalData('mock_kyc_submissions', MOCK_KYC_SUBMISSIONS);
    const cases = getLocalData('mock_cases', MOCK_CASES);
    const agents = getLocalData('mock_agents', MOCK_AGENTS);
    const cards = MOCK_CARDS;

    // Filter today's payments
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayPayments = payments.filter(p => {
      const pDate = new Date(p.createdAt);
      pDate.setHours(0, 0, 0, 0);
      return pDate.getTime() === today.getTime();
    });

    // Group by status
    const paymentsByStatus = payments.reduce((acc: any[], p) => {
      const existing = acc.find(item => item.status === p.status);
      if (existing) {
        existing.count++;
      } else {
        acc.push({ status: p.status, count: 1 });
      }
      return acc;
    }, []);

    // Group by type (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const recentPayments = payments.filter(p => new Date(p.createdAt) >= sevenDaysAgo);
    const paymentsByType = recentPayments.reduce((acc: any[], p) => {
      const existing = acc.find(item => item.type === p.type);
      if (existing) {
        existing.count++;
      } else {
        acc.push({ type: p.type, count: 1 });
      }
      return acc;
    }, []);

    return {
      kpis: {
        pendingKyc: kycSubmissions.filter((k: KycSubmission) => k.status === 'PENDING_REVIEW').length,
        openCases: cases.filter((c: Case) => c.status === 'OPEN').length,
        paymentsToday: todayPayments.length,
        activeAgents: agents.filter((a: Agent) => a.status === 'ACTIVE').length,
        totalCards: cards.length,
      },
      paymentsByStatus,
      paymentsByType,
    };
  }

  // Customer 360
  async getCustomer360(customerId: string) {
    await delay();
    
    const customer = MOCK_CUSTOMERS.find(c => c.id === customerId);
    if (!customer) {
      throw new Error('Customer not found');
    }

    const wallets = MOCK_WALLETS[customerId] ? [MOCK_WALLETS[customerId]] : [];
    const recentPayments = MOCK_PAYMENTS
      .filter(p => p.customerId === customerId)
      .slice(-10);

    return {
      customer,
      wallets,
      recentPayments,
    };
  }

  // KYC
  async listKycSubmissions(status?: string) {
    await delay();
    
    const submissions = getLocalData('mock_kyc_submissions', MOCK_KYC_SUBMISSIONS);
    
    if (status) {
      return submissions.filter((s: KycSubmission) => s.status === status);
    }
    return submissions;
  }

  async makeKycDecision(submissionId: string, decision: string, reason?: string) {
    await delay(300);
    
    const submissions = getLocalData('mock_kyc_submissions', MOCK_KYC_SUBMISSIONS);
    const submission = submissions.find((s: KycSubmission) => s.id === submissionId);
    
    if (!submission) {
      throw new Error('Submission not found');
    }

    submission.status = decision === 'APPROVE' ? 'APPROVED' : 'REJECTED';
    submission.reviewNotes = reason || `Decision: ${decision}`;
    submission.updatedAt = new Date().toISOString();
    
    setLocalData('mock_kyc_submissions', submissions);
    
    return submission;
  }

  // Agents
  async listAgents() {
    await delay();
    return getLocalData('mock_agents', MOCK_AGENTS);
  }

  async enrollAgent(data: { firstName: string; lastName: string; phoneE164: string; email?: string }) {
    await delay(300);
    
    const agents = getLocalData('mock_agents', MOCK_AGENTS);
    const newAgent = {
      id: `agent_${String(agents.length + 1).padStart(3, '0')}`,
      firstName: data.firstName,
      lastName: data.lastName,
      phoneE164: data.phoneE164,
      email: data.email || '',
      status: 'ACTIVE',
      floatWalletId: `wallet_float_${String(agents.length + 1).padStart(3, '0')}`,
      createdAt: new Date().toISOString(),
    };
    
    agents.push(newAgent);
    setLocalData('mock_agents', agents);
    
    return newAgent;
  }

  // Payments
  async searchPayments(filters?: { customerId?: string; status?: string; type?: string }) {
    await delay();
    
    let payments = [...MOCK_PAYMENTS];

    if (filters?.customerId) {
      payments = payments.filter(p => p.customerId === filters.customerId);
    }
    if (filters?.status) {
      payments = payments.filter(p => p.status === filters.status);
    }
    if (filters?.type) {
      payments = payments.filter(p => p.type === filters.type);
    }

    // Sort by date descending
    payments.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    return payments;
  }

  // Cards
  async listCards(customerId?: string) {
    await delay();
    
    if (customerId) {
      return MOCK_CARDS.filter(c => c.customerId === customerId);
    }
    return MOCK_CARDS;
  }

  // Payroll
  async listEmployers() {
    await delay();
    return getLocalData('mock_employers', MOCK_EMPLOYERS);
  }

  async createEmployer(data: { name: string; taxId: string }) {
    await delay(300);
    
    const employers = getLocalData('mock_employers', MOCK_EMPLOYERS);
    const newEmployer = {
      id: `emp_${String(employers.length + 1).padStart(3, '0')}`,
      name: data.name,
      taxId: data.taxId,
      employeeCount: 0,
      createdAt: new Date().toISOString(),
    };
    
    employers.push(newEmployer);
    setLocalData('mock_employers', employers);
    
    return newEmployer;
  }

  async importEmployees(employerId: string, employees: any[]) {
    await delay(500);
    return { success: true, imported: employees.length };
  }

  async creditSalaries(employerId: string) {
    await delay(500);
    return { success: true, employerId };
  }

  // Recon & Cases
  async getDailySummary(date: string) {
    await delay();
    
    const selectedDate = new Date(date);
    const payments = MOCK_PAYMENTS.filter(p => {
      const pDate = new Date(p.createdAt);
      return pDate.toDateString() === selectedDate.toDateString();
    });

    const totalVolume = payments.reduce((sum, p) => sum + parseInt(p.amountMinor), 0);

    return {
      date,
      totalJournals: payments.length * 2, // Each payment has 2 journal entries
      postedJournals: payments.filter(p => p.status === 'POSTED').length * 2,
      totalTransactions: payments.length,
      totalVolumeMinor: String(totalVolume),
      status: payments.length > 0 ? 'RECONCILED' : 'NO_DATA',
      details: {
        payments: payments.map(p => ({
          id: p.id,
          type: p.type,
          status: p.status,
          amount: `${p.currency} ${(parseInt(p.amountMinor) / 100).toFixed(2)}`,
        })),
      },
    };
  }

  async listCases(status?: string) {
    await delay();
    
    const cases = getLocalData('mock_cases', MOCK_CASES);
    
    if (status) {
      return cases.filter((c: Case) => c.status === status);
    }
    return cases;
  }

  async createCase(data: { type: string; description: string; customerId?: string }) {
    await delay(300);
    
    const cases = getLocalData('mock_cases', MOCK_CASES);
    const newCase = {
      id: `case_${String(cases.length + 1).padStart(3, '0')}`,
      type: data.type,
      description: data.description,
      customerId: data.customerId || null,
      status: 'OPEN',
      createdAt: new Date().toISOString(),
      decidedAt: null,
    };
    
    cases.push(newCase);
    setLocalData('mock_cases', cases);
    
    return newCase;
  }

  async updateCase(caseId: string, status: string) {
    await delay(300);
    
    const cases = getLocalData('mock_cases', MOCK_CASES);
    const caseItem = cases.find((c: Case) => c.id === caseId);
    
    if (!caseItem) {
      throw new Error('Case not found');
    }

    caseItem.status = status;
    if (status === 'RESOLVED' || status === 'CLOSED') {
      caseItem.decidedAt = new Date().toISOString();
    }
    
    setLocalData('mock_cases', cases);
    
    return caseItem;
  }

  // Config
  async listFeeConfigs() {
    await delay();
    return MOCK_FEES;
  }

  async createFeeConfig(data: any) {
    await delay(300);
    return { ...data, id: `fee_${Date.now()}` };
  }

  async listLimitConfigs() {
    await delay();
    return MOCK_LIMITS;
  }

  async createLimitConfig(data: any) {
    await delay(300);
    return { ...data, id: `limit_${Date.now()}` };
  }
}

export const mockApi = new MockAdminApiClient();
