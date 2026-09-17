// Mock data store for YOLE Admin demo
// Congo DRC context: Vodacom, Airtel, CDF/USD currencies

export interface Customer {
  id: string;
  email: string | null;
  phoneE164: string | null;
  firstName: string;
  lastName: string;
  segment: string;
  status: string;
  kycStatus: string;
  enrolledByAgentId: string | null;
  createdAt: string;
}

export interface Agent {
  id: string;
  firstName: string;
  lastName: string;
  phoneE164: string;
  email: string;
  status: string;
  floatWalletId: string;
  createdAt: string;
}

export interface Payment {
  id: string;
  customerId: string;
  type: string;
  status: string;
  currency: string;
  amountMinor: string;
  feeMinor: string;
  totalMinor: string;
  sourceRef: string | null;
  destRef: string | null;
  createdAt: string;
}

export interface KycSubmission {
  id: string;
  customerId: string;
  phoneE164: string;
  idNumber: string;
  idType: string;
  status: string;
  reviewNotes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Card {
  id: string;
  customerId: string;
  last4: string;
  currency: string;
  status: string;
  dailyLimitMinor: string;
  monthlyLimitMinor: string;
  createdAt: string;
}

export interface Employer {
  id: string;
  name: string;
  taxId: string;
  employeeCount: number;
  createdAt: string;
}

export interface Case {
  id: string;
  type: string;
  description: string;
  customerId: string | null;
  status: string;
  createdAt: string;
  decidedAt: string | null;
}

// Seed Customers
export const MOCK_CUSTOMERS: Customer[] = [
  {
    id: 'cust_001',
    email: 'jkabila@example.cd',
    phoneE164: '+243990123456',
    firstName: 'Jean-Paul',
    lastName: 'Kabila',
    segment: 'RETAIL',
    status: 'ACTIVE',
    kycStatus: 'APPROVED',
    enrolledByAgentId: 'agent_001',
    createdAt: '2026-08-15T10:30:00Z',
  },
  {
    id: 'cust_002',
    email: 'mtshala@example.cd',
    phoneE164: '+243991234567',
    firstName: 'Marie',
    lastName: 'Tshala',
    segment: 'RETAIL',
    status: 'ACTIVE',
    kycStatus: 'PENDING_REVIEW',
    enrolledByAgentId: 'agent_002',
    createdAt: '2026-09-10T14:20:00Z',
  },
  {
    id: 'cust_003',
    email: 'jmukendi@example.cd',
    phoneE164: '+243992345678',
    firstName: 'Joseph',
    lastName: 'Mukendi',
    segment: 'PREMIUM',
    status: 'ACTIVE',
    kycStatus: 'APPROVED',
    enrolledByAgentId: 'agent_001',
    createdAt: '2026-07-22T09:15:00Z',
  },
  {
    id: 'cust_004',
    email: 'gmbuyi@example.cd',
    phoneE164: '+243993456789',
    firstName: 'Grace',
    lastName: 'Mbuyi',
    segment: 'RETAIL',
    status: 'ACTIVE',
    kycStatus: 'APPROVED',
    enrolledByAgentId: 'agent_003',
    createdAt: '2026-08-30T16:45:00Z',
  },
  {
    id: 'cust_005',
    email: 'plumba@example.cd',
    phoneE164: '+243994567890',
    firstName: 'Patrick',
    lastName: 'Lumba',
    segment: 'RETAIL',
    status: 'ACTIVE',
    kycStatus: 'APPROVED',
    enrolledByAgentId: 'agent_002',
    createdAt: '2026-09-01T11:30:00Z',
  },
  {
    id: 'cust_006',
    email: null,
    phoneE164: '+243995678901',
    firstName: 'Esther',
    lastName: 'Kasongo',
    segment: 'RETAIL',
    status: 'ACTIVE',
    kycStatus: 'AUTO_APPROVED',
    enrolledByAgentId: 'agent_001',
    createdAt: '2026-09-05T08:20:00Z',
  },
  {
    id: 'cust_007',
    email: 'dnkulu@example.cd',
    phoneE164: '+243996789012',
    firstName: 'David',
    lastName: 'Nkulu',
    segment: 'RETAIL',
    status: 'ACTIVE',
    kycStatus: 'PENDING_REVIEW',
    enrolledByAgentId: 'agent_003',
    createdAt: '2026-09-12T13:10:00Z',
  },
  {
    id: 'cust_008',
    email: 'ckimba@example.cd',
    phoneE164: '+243997890123',
    firstName: 'Christine',
    lastName: 'Kimba',
    segment: 'PREMIUM',
    status: 'ACTIVE',
    kycStatus: 'APPROVED',
    enrolledByAgentId: 'agent_002',
    createdAt: '2026-08-18T15:40:00Z',
  },
];

// Seed Agents
export const MOCK_AGENTS: Agent[] = [
  {
    id: 'agent_001',
    firstName: 'Claude',
    lastName: 'Mokonzi',
    phoneE164: '+243810111111',
    email: 'cmokonzi@yole-agents.cd',
    status: 'ACTIVE',
    floatWalletId: 'wallet_float_001',
    createdAt: '2026-07-01T08:00:00Z',
  },
  {
    id: 'agent_002',
    firstName: 'Beatrice',
    lastName: 'Nzuzi',
    phoneE164: '+243810222222',
    email: 'bnzuzi@yole-agents.cd',
    status: 'ACTIVE',
    floatWalletId: 'wallet_float_002',
    createdAt: '2026-07-01T08:00:00Z',
  },
  {
    id: 'agent_003',
    firstName: 'Andre',
    lastName: 'Kitoko',
    phoneE164: '+243810333333',
    email: 'akitoko@yole-agents.cd',
    status: 'ACTIVE',
    floatWalletId: 'wallet_float_003',
    createdAt: '2026-07-15T08:00:00Z',
  },
  {
    id: 'agent_004',
    firstName: 'Solange',
    lastName: 'Lubamba',
    phoneE164: '+243810444444',
    email: 'slubamba@yole-agents.cd',
    status: 'INACTIVE',
    floatWalletId: 'wallet_float_004',
    createdAt: '2026-08-01T08:00:00Z',
  },
];

// Seed Payments
export const MOCK_PAYMENTS: Payment[] = [
  // W2W Transfers
  {
    id: 'pay_001',
    customerId: 'cust_001',
    type: 'W2W',
    status: 'POSTED',
    currency: 'USD',
    amountMinor: '5000',
    feeMinor: '50',
    totalMinor: '5050',
    sourceRef: null,
    destRef: 'cust_003',
    createdAt: '2026-09-16T10:30:00Z',
  },
  {
    id: 'pay_002',
    customerId: 'cust_003',
    type: 'W2W',
    status: 'POSTED',
    currency: 'CDF',
    amountMinor: '10000000',
    feeMinor: '100000',
    totalMinor: '10100000',
    sourceRef: null,
    destRef: 'cust_001',
    createdAt: '2026-09-16T14:15:00Z',
  },
  // Mobile Money
  {
    id: 'pay_003',
    customerId: 'cust_002',
    type: 'MNO_IN',
    status: 'POSTED',
    currency: 'CDF',
    amountMinor: '5000000',
    feeMinor: '50000',
    totalMinor: '5050000',
    sourceRef: 'Vodacom',
    destRef: null,
    createdAt: '2026-09-15T09:20:00Z',
  },
  {
    id: 'pay_004',
    customerId: 'cust_004',
    type: 'MNO_OUT',
    status: 'POSTED',
    currency: 'CDF',
    amountMinor: '3000000',
    feeMinor: '60000',
    totalMinor: '3060000',
    sourceRef: null,
    destRef: 'Airtel',
    createdAt: '2026-09-15T11:45:00Z',
  },
  {
    id: 'pay_005',
    customerId: 'cust_001',
    type: 'MNO_IN',
    status: 'POSTED',
    currency: 'USD',
    amountMinor: '10000',
    feeMinor: '100',
    totalMinor: '10100',
    sourceRef: 'Vodacom',
    destRef: null,
    createdAt: '2026-09-14T16:30:00Z',
  },
  // Bill Payments
  {
    id: 'pay_006',
    customerId: 'cust_003',
    type: 'BILL',
    status: 'POSTED',
    currency: 'CDF',
    amountMinor: '15000000',
    feeMinor: '150000',
    totalMinor: '15150000',
    sourceRef: null,
    destRef: 'SNEL',
    createdAt: '2026-09-13T08:10:00Z',
  },
  {
    id: 'pay_007',
    customerId: 'cust_005',
    type: 'BILL',
    status: 'POSTED',
    currency: 'CDF',
    amountMinor: '8000000',
    feeMinor: '80000',
    totalMinor: '8080000',
    sourceRef: null,
    destRef: 'REGIDESO',
    createdAt: '2026-09-12T12:25:00Z',
  },
  // Airtime
  {
    id: 'pay_008',
    customerId: 'cust_002',
    type: 'AIRTIME',
    status: 'POSTED',
    currency: 'CDF',
    amountMinor: '500000',
    feeMinor: '5000',
    totalMinor: '505000',
    sourceRef: null,
    destRef: 'Vodacom',
    createdAt: '2026-09-16T07:15:00Z',
  },
  {
    id: 'pay_009',
    customerId: 'cust_006',
    type: 'AIRTIME',
    status: 'POSTED',
    currency: 'CDF',
    amountMinor: '1000000',
    feeMinor: '10000',
    totalMinor: '1010000',
    sourceRef: null,
    destRef: 'Airtel',
    createdAt: '2026-09-15T18:40:00Z',
  },
  // Failed transactions
  {
    id: 'pay_010',
    customerId: 'cust_004',
    type: 'MNO_OUT',
    status: 'FAILED',
    currency: 'USD',
    amountMinor: '20000',
    feeMinor: '200',
    totalMinor: '20200',
    sourceRef: null,
    destRef: 'Vodacom',
    createdAt: '2026-09-14T10:05:00Z',
  },
  {
    id: 'pay_011',
    customerId: 'cust_007',
    type: 'W2W',
    status: 'PENDING',
    currency: 'CDF',
    amountMinor: '2500000',
    feeMinor: '25000',
    totalMinor: '2525000',
    sourceRef: null,
    destRef: 'cust_005',
    createdAt: '2026-09-16T16:20:00Z',
  },
  // Bank transfers
  {
    id: 'pay_012',
    customerId: 'cust_008',
    type: 'BANK_IN',
    status: 'POSTED',
    currency: 'USD',
    amountMinor: '50000',
    feeMinor: '500',
    totalMinor: '50500',
    sourceRef: 'Rawbank',
    destRef: null,
    createdAt: '2026-09-13T14:30:00Z',
  },
  {
    id: 'pay_013',
    customerId: 'cust_003',
    type: 'BANK_OUT',
    status: 'POSTED',
    currency: 'USD',
    amountMinor: '30000',
    feeMinor: '300',
    totalMinor: '30300',
    sourceRef: null,
    destRef: 'Equity BCDC',
    createdAt: '2026-09-12T09:45:00Z',
  },
];

// Seed KYC Submissions
export const MOCK_KYC_SUBMISSIONS: KycSubmission[] = [
  {
    id: 'kyc_001',
    customerId: 'cust_002',
    phoneE164: '+243991234567',
    idNumber: 'ID123456789',
    idType: 'NATIONAL_ID',
    status: 'PENDING_REVIEW',
    reviewNotes: null,
    createdAt: '2026-09-10T14:25:00Z',
    updatedAt: '2026-09-10T14:25:00Z',
  },
  {
    id: 'kyc_002',
    customerId: 'cust_007',
    phoneE164: '+243996789012',
    idNumber: 'ID987654321',
    idType: 'PASSPORT',
    status: 'PENDING_REVIEW',
    reviewNotes: null,
    createdAt: '2026-09-12T13:15:00Z',
    updatedAt: '2026-09-12T13:15:00Z',
  },
  {
    id: 'kyc_003',
    customerId: 'cust_001',
    phoneE164: '+243990123456',
    idNumber: 'ID111222333',
    idType: 'NATIONAL_ID',
    status: 'APPROVED',
    reviewNotes: 'All documents verified',
    createdAt: '2026-08-15T10:35:00Z',
    updatedAt: '2026-08-15T11:00:00Z',
  },
  {
    id: 'kyc_004',
    customerId: 'cust_009',
    phoneE164: '+243998901234',
    idNumber: 'ID444555666',
    idType: 'NATIONAL_ID',
    status: 'REJECTED',
    reviewNotes: 'Document quality insufficient',
    createdAt: '2026-09-11T08:20:00Z',
    updatedAt: '2026-09-11T10:30:00Z',
  },
];

// Seed Cards
export const MOCK_CARDS: Card[] = [
  {
    id: 'card_001',
    customerId: 'cust_003',
    last4: '4532',
    currency: 'USD',
    status: 'ACTIVE',
    dailyLimitMinor: '100000',
    monthlyLimitMinor: '500000',
    createdAt: '2026-07-25T10:00:00Z',
  },
  {
    id: 'card_002',
    customerId: 'cust_003',
    last4: '8765',
    currency: 'CDF',
    status: 'ACTIVE',
    dailyLimitMinor: '100000000',
    monthlyLimitMinor: '500000000',
    createdAt: '2026-08-05T11:30:00Z',
  },
  {
    id: 'card_003',
    customerId: 'cust_001',
    last4: '2341',
    currency: 'USD',
    status: 'ACTIVE',
    dailyLimitMinor: '50000',
    monthlyLimitMinor: '200000',
    createdAt: '2026-08-20T14:15:00Z',
  },
  {
    id: 'card_004',
    customerId: 'cust_008',
    last4: '9876',
    currency: 'USD',
    status: 'FROZEN',
    dailyLimitMinor: '150000',
    monthlyLimitMinor: '700000',
    createdAt: '2026-08-28T09:45:00Z',
  },
  {
    id: 'card_005',
    customerId: 'cust_004',
    last4: '5544',
    currency: 'CDF',
    status: 'BLOCKED',
    dailyLimitMinor: '50000000',
    monthlyLimitMinor: '200000000',
    createdAt: '2026-09-01T16:20:00Z',
  },
];

// Seed Employers
export const MOCK_EMPLOYERS: Employer[] = [
  {
    id: 'emp_001',
    name: 'Congo Mining Corp',
    taxId: 'TAX001234',
    employeeCount: 145,
    createdAt: '2026-07-10T08:00:00Z',
  },
  {
    id: 'emp_002',
    name: 'Kinshasa Logistics SA',
    taxId: 'TAX005678',
    employeeCount: 87,
    createdAt: '2026-08-02T10:30:00Z',
  },
  {
    id: 'emp_003',
    name: 'DRC Telecom Services',
    taxId: 'TAX009012',
    employeeCount: 234,
    createdAt: '2026-08-15T14:20:00Z',
  },
  {
    id: 'emp_004',
    name: 'Gombe Construction Ltd',
    taxId: 'TAX003456',
    employeeCount: 56,
    createdAt: '2026-09-01T09:00:00Z',
  },
];

// Seed Cases
export const MOCK_CASES: Case[] = [
  {
    id: 'case_001',
    type: 'DISPUTE',
    description: 'Payment sent but not received by beneficiary. Transaction ID: pay_010',
    customerId: 'cust_004',
    status: 'OPEN',
    createdAt: '2026-09-14T11:30:00Z',
    decidedAt: null,
  },
  {
    id: 'case_002',
    type: 'FRAUD',
    description: 'Suspicious transaction pattern detected - multiple high-value transfers in short period',
    customerId: 'cust_003',
    status: 'IN_PROGRESS',
    createdAt: '2026-09-13T09:15:00Z',
    decidedAt: null,
  },
  {
    id: 'case_003',
    type: 'INQUIRY',
    description: 'Customer requesting information on how to increase daily transaction limits',
    customerId: 'cust_001',
    status: 'RESOLVED',
    createdAt: '2026-09-10T14:20:00Z',
    decidedAt: '2026-09-11T10:00:00Z',
  },
  {
    id: 'case_004',
    type: 'OTHER',
    description: 'Mobile app not loading properly on customer device',
    customerId: 'cust_002',
    status: 'OPEN',
    createdAt: '2026-09-15T16:40:00Z',
    decidedAt: null,
  },
  {
    id: 'case_005',
    type: 'DISPUTE',
    description: 'Incorrect fee charged on bill payment transaction',
    customerId: 'cust_005',
    status: 'RESOLVED',
    createdAt: '2026-09-12T13:10:00Z',
    decidedAt: '2026-09-12T15:30:00Z',
  },
];

// Wallets for Customer 360
export const MOCK_WALLETS: Record<string, any> = {
  cust_001: {
    id: 'wallet_001',
    customerId: 'cust_001',
    pockets: [
      {
        id: 'pocket_001_usd',
        currency: 'USD',
        ledgerMinor: '125000',
        availableMinor: '125000',
        blockedMinor: '0',
        pendingOutMinor: '0',
        pendingInMinor: '0',
      },
      {
        id: 'pocket_001_cdf',
        currency: 'CDF',
        ledgerMinor: '15000000',
        availableMinor: '15000000',
        blockedMinor: '0',
        pendingOutMinor: '0',
        pendingInMinor: '0',
      },
    ],
  },
  cust_003: {
    id: 'wallet_003',
    customerId: 'cust_003',
    pockets: [
      {
        id: 'pocket_003_usd',
        currency: 'USD',
        ledgerMinor: '285000',
        availableMinor: '285000',
        blockedMinor: '0',
        pendingOutMinor: '0',
        pendingInMinor: '0',
      },
      {
        id: 'pocket_003_cdf',
        currency: 'CDF',
        ledgerMinor: '25000000',
        availableMinor: '25000000',
        blockedMinor: '0',
        pendingOutMinor: '0',
        pendingInMinor: '0',
      },
    ],
  },
};

// Fee configurations
export const MOCK_FEES = [
  {
    id: 'fee_001',
    paymentType: 'W2W',
    feePercent: 1,
    minFeeMinor: '100',
    maxFeeMinor: '10000',
  },
  {
    id: 'fee_002',
    paymentType: 'MNO_OUT',
    feePercent: 2,
    minFeeMinor: '200',
    maxFeeMinor: '20000',
  },
];

// Limit configurations
export const MOCK_LIMITS = [
  {
    id: 'limit_001',
    limitType: 'CUSTOMER_DAILY',
    currency: 'USD',
    dailyLimitMinor: '100000',
    monthlyLimitMinor: '1000000',
  },
  {
    id: 'limit_002',
    limitType: 'CUSTOMER_DAILY',
    currency: 'CDF',
    dailyLimitMinor: '100000000',
    monthlyLimitMinor: '1000000000',
  },
];
