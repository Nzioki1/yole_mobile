/** Shared offline demo universe types (DEM-01…DEM-12 seed graph). */

export interface AmlBanEntry {
  id: string;
  fullName: string;
  idRef?: string;
  matchType: 'NAME' | 'ID' | 'ENTITY';
  reason: string;
  sourceList: string;
  status: 'BANNED' | 'LIFTED';
  notes?: string;
  createdAt: string;
}

export interface UniverseMeta {
  version: number;
  name: string;
  description?: string;
  honesty?: {
    globalBadge: string;
    cardsBadge: string;
    resilienceBadge: string;
  };
  demBookmarks?: Record<string, unknown>;
}

export interface Staff {
  id: string;
  email: string;
  password: string;
  role: string;
  firstName?: string;
  lastName?: string;
}

export interface Customer {
  id: string;
  email: string;
  password: string;
  phoneE164?: string | null;
  firstName: string;
  lastName: string;
  segment: string;
  status?: string;
  kycStatus: string;
  employerId?: string | null;
  enrolledByAgentId?: string | null;
  createdAt?: string;
}

export interface Wallet {
  id: string;
  customerId: string;
  currency: string;
  availableMinor: number;
  ledgerMinor: number;
  blockedMinor: number;
  pendingMinor: number;
}

export interface Agent {
  id: string;
  name: string;
  firstName?: string;
  lastName?: string;
  phoneE164?: string;
  email?: string;
  password?: string;
  floatCdfMinor: number;
  floatUsdMinor: number;
  floatWalletId?: string;
  status: string;
  createdAt?: string;
}

export interface Employer {
  id: string;
  name: string;
  taxId: string;
  employeeCount?: number;
  createdAt?: string;
}

export interface Employee {
  id: string;
  employerId: string;
  customerId: string;
  employeeNumber: string;
  jobTitle?: string;
  grossSalaryCdfMinor: number;
  netSalaryCdfMinor: number;
  eligibleAdvanceMaxCdfMinor: number;
  status: string;
  hiredAt?: string;
}

export interface SalaryHistoryEntry {
  id: string;
  employeeId: string;
  customerId: string;
  period: string;
  grossCdfMinor: number;
  netCdfMinor: number;
  paidAt: string;
}

export interface Journal {
  id: string;
  customerId: string;
  walletId: string;
  type: string;
  direction: string;
  currency: string;
  amountMinor: number;
  balanceAfterMinor?: number;
  refType?: string;
  refId?: string;
  narration?: string;
  postedAt: string;
}

export interface Payment {
  id: string;
  customerId: string;
  type: string;
  status: string;
  currency: string;
  amountMinor: number;
  feeMinor: number;
  totalMinor: number;
  sourceRef?: string | null;
  destRef?: string | null;
  journalId?: string | null;
  idempotencyKey?: string;
  createdAt: string;
  notes?: string;
}

export interface AgentTransaction {
  id: string;
  agentId: string;
  customerId: string;
  type: string;
  currency?: string | null;
  amountMinor: number;
  journalId?: string | null;
  createdAt: string;
}

export interface LoanSchedule {
  id: string;
  loanId: string;
  installments: Array<{
    id: string;
    dueDate: string;
    principalMinor: number;
    interestMinor: number;
    status: string;
    paidAt?: string | null;
  }>;
}

export interface Loan {
  id: string;
  customerId: string;
  employerId?: string | null;
  productId: string;
  status: string;
  principalMinor: number;
  currency: string;
  scheduleId?: string | null;
  receivableMinor?: number;
  exceptionReason?: string;
  thresholdMinor?: number;
  disbursedAt?: string;
  createdAt: string;
}

export interface Card {
  id: string;
  customerId: string;
  type: string;
  last4: string;
  currency: string;
  status: string;
  dailyLimitMinor: number;
  monthlyLimitMinor: number;
  mockNetwork?: string;
  createdAt: string;
}

export interface CardAuth {
  id: string;
  cardId: string;
  customerId: string;
  amountMinor: number;
  currency: string;
  merchant: string;
  status: string;
  threeDs?: Record<string, unknown>;
  createdAt: string;
}

export interface Remittance {
  id: string;
  customerId: string;
  direction: string;
  partner: string;
  status: string;
  sendCurrency: string;
  sendAmountMinor: number;
  receiveCurrency: string;
  receiveAmountMinor: number;
  fxConversionId?: string | null;
  walletId?: string | null;
  screeningHit?: string;
  createdAt: string;
}

export interface FxRate {
  id: string;
  base: string;
  quote: string;
  rate: number;
  asOf: string;
}

export interface Conversion {
  id: string;
  customerId: string;
  fromCurrency: string;
  toCurrency: string;
  fromAmountMinor: number;
  toAmountMinor: number;
  rate: number;
  feeMinor: number;
  createdAt: string;
}

export interface Product {
  id: string;
  code: string;
  name: string;
  segment: string;
  currencies?: string[];
  maxAdvancePct?: number;
  autoApproveMaxMinor?: number;
  status: string;
}

export interface FeeLimit {
  id: string;
  kind: string;
  paymentType?: string;
  limitType?: string;
  currency?: string;
  feePercent?: number;
  minFeeMinor?: number;
  maxFeeMinor?: number;
  dailyLimitMinor?: number;
  monthlyLimitMinor?: number;
  effectiveFrom: string;
  status: string;
}

export interface PendingApproval {
  id: string;
  type: string;
  targetId: string;
  summary: string;
  makerStaffId: string;
  status: string;
  createdAt: string;
}

export interface Case {
  id: string;
  type: string;
  confidential?: boolean;
  description: string;
  customerId?: string | null;
  cardId?: string;
  cardAuthId?: string;
  status: string;
  steps?: string[];
  currentStep?: string;
  createdAt: string;
  decidedAt?: string | null;
}

export interface ReconDay {
  id: string;
  businessDate: string;
  status: string;
  matchedCount: number;
  exceptionCount: number;
  exceptions: Array<Record<string, unknown>>;
  eodSnapshot: Record<string, unknown>;
}

export interface KycSubmission {
  id: string;
  customerId: string;
  phoneE164: string;
  idNumber: string;
  idType: string;
  status: string;
  reviewNotes?: string | null;
  screeningResult?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Notification {
  id: string;
  customerId?: string;
  staffId?: string;
  channel: string;
  title: string;
  body: string;
  read: boolean;
  createdAt: string;
}

export interface Universe {
  meta: UniverseMeta;
  staff: Staff[];
  customers: Customer[];
  wallets: Wallet[];
  agents: Agent[];
  employers: Employer[];
  employees: Employee[];
  salaryHistory: SalaryHistoryEntry[];
  journals: Journal[];
  payments: Payment[];
  agentTransactions: AgentTransaction[];
  loanSchedules: LoanSchedule[];
  loans: Loan[];
  cards: Card[];
  cardAuths: CardAuth[];
  remittances: Remittance[];
  fxRates: FxRate[];
  conversions: Conversion[];
  products: Product[];
  feeLimits: FeeLimit[];
  pendingApprovals: PendingApproval[];
  cases: Case[];
  reconDays: ReconDay[];
  kyc: KycSubmission[];
  notifications: Notification[];
  amlBanList: AmlBanEntry[];
}
