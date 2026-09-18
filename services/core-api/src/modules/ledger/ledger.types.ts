export type CurrencyCode = 'CDF' | 'USD';
export type PostingDirection = 'debit' | 'credit';

export interface PostingInput {
  accountCode: string;
  direction: PostingDirection;
  amountMinor: bigint;
  currency: CurrencyCode;
}

export function assertBalancedPostings(postings: PostingInput[]): void {
  if (postings.length < 2) throw new Error('journal requires at least two postings');
  const currency = postings[0].currency;
  if (postings.some((p) => p.currency !== currency)) {
    throw new Error('mixed currency in one journal entry');
  }
  let debit = 0n;
  let credit = 0n;
  for (const p of postings) {
    if (p.amountMinor <= 0n) throw new Error('amount must be positive');
    if (p.direction === 'debit') debit += p.amountMinor;
    else credit += p.amountMinor;
  }
  if (debit !== credit) throw new Error('unbalanced journal entry');
}
