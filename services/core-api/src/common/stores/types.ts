// Common types for in-memory stores (matching Prisma schema shapes)

export type CurrencyCode = 'CDF' | 'USD';
export type KycStatus = 'PENDING_REVIEW' | 'AUTO_APPROVED' | 'APPROVED' | 'REJECTED';
export type JournalStatus = 'PENDING' | 'POSTED' | 'FAILED' | 'REVERSED';

export interface Customer {
  id: string;
  email: string | null;
  phoneE164: string | null;
  firstName: string;
  lastName: string;
  passwordHash: string | null;
  segment: string;
  status: string;
  enrolledByAgentId: string | null;
  createdAt: Date;
}

export interface Wallet {
  id: string;
  customerId: string;
}

export interface WalletPocket {
  id: string;
  walletId: string;
  currency: CurrencyCode;
  ledgerMinor: bigint;
  blockedMinor: bigint;
  pendingOutMinor: bigint;
  pendingInMinor: bigint;
}

export interface JournalEntry {
  id: string;
  yoleReference: string;
  idempotencyKey: string;
  status: JournalStatus;
  currency: CurrencyCode;
  correlationId: string;
  actorType: string;
  actorId: string | null;
  externalRefsJson: any;
  createdAt: Date;
}

export interface Posting {
  id: string;
  journalId: string;
  accountCode: string;
  direction: string;
  amountMinor: bigint;
  currency: CurrencyCode;
  walletPocketId: string | null;
}

export interface IdempotencyRecord {
  key: string;
  requestHash: string;
  responseJson: any;
  createdAt: Date;
}

export interface KycSubmission {
  id: string;
  customerId: string;
  idNumber: string;
  phoneE164: string;
  idDocumentPath: string;
  selfiePath: string;
  status: KycStatus;
  screeningHit: boolean;
  screeningRef: string | null;
  decision: string | null;
  decisionReason: string | null;
  decidedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}
