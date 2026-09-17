const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

export class AdminApiClient {
  private apiKey: string;

  constructor(apiKey: string = 'dev-admin-key') {
    this.apiKey = apiKey;
  }

  private async request(endpoint: string, options: RequestInit = {}) {
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

  // Dashboard counts
  async getDashboardCounts() {
    // TODO: Add lightweight endpoint or aggregate from existing
    return {
      customers: 0,
      payments: 0,
      pendingKyc: 0,
      agents: 0,
    };
  }

  // Customer 360
  async getCustomer360(customerId: string) {
    return this.request(`/v1/admin/customers/${customerId}/360`);
  }

  // KYC
  async listKycSubmissions(status?: string) {
    const query = status ? `?status=${status}` : '';
    return this.request(`/v1/admin/kyc/submissions${query}`);
  }

  async makeKycDecision(submissionId: string, decision: string, reason?: string) {
    return this.request(`/v1/admin/kyc/submissions/${submissionId}/decision`, {
      method: 'POST',
      body: JSON.stringify({ decision, reason }),
    });
  }

  // Agents
  async listAgents() {
    return this.request('/v1/admin/agents');
  }

  async enrollAgent(data: { firstName: string; lastName: string; phoneE164: string; email?: string }) {
    return this.request('/v1/admin/agents', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  // Payments
  async searchPayments(filters?: { customerId?: string; status?: string; type?: string }) {
    const params = new URLSearchParams(filters as Record<string, string>);
    return this.request(`/v1/admin/payments/search?${params}`);
  }

  // Fees/Limits
  async listFeeConfigs() {
    return this.request('/v1/admin/config/fees');
  }

  async createFeeConfig(data: any) {
    return this.request('/v1/admin/config/fees', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async listLimitConfigs() {
    return this.request('/v1/admin/config/limits');
  }

  // Payroll
  async listEmployers() {
    return this.request('/v1/admin/payroll/employers');
  }

  async createEmployer(data: { name: string; taxId: string }) {
    return this.request('/v1/admin/payroll/employers', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async importEmployees(employerId: string, employees: { customerId: string; salaryMinor: string; currency: string }[]) {
    return this.request(`/v1/admin/payroll/employers/${employerId}/employees/import`, {
      method: 'POST',
      body: JSON.stringify({ employees }),
    });
  }

  async creditSalaries(employerId: string) {
    return this.request(`/v1/admin/payroll/employers/${employerId}/salary/credit`, {
      method: 'POST',
    });
  }

  // Recon & Cases
  async getDailySummary(date: string) {
    return this.request(`/v1/admin/recon/daily?date=${date}`);
  }

  async listCases(status?: string) {
    const query = status ? `?status=${status}` : '';
    return this.request(`/v1/admin/cases${query}`);
  }

  async createCase(data: { type: string; description: string; customerId?: string }) {
    return this.request('/v1/admin/cases', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }
}

export const api = new AdminApiClient();
