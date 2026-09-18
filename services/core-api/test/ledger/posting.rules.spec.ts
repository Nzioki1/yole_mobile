import { assertBalancedPostings } from '../../src/modules/ledger/ledger.types';

describe('assertBalancedPostings', () => {
  it('accepts equal debit and credit totals in one currency', () => {
    expect(() =>
      assertBalancedPostings([
        { accountCode: 'CUST_WALLET_USD', direction: 'debit', amountMinor: 1000n, currency: 'USD' },
        { accountCode: 'CUST_WALLET_USD', direction: 'credit', amountMinor: 1000n, currency: 'USD' },
      ]),
    ).not.toThrow();
  });

  it('rejects unbalanced postings', () => {
    expect(() =>
      assertBalancedPostings([
        { accountCode: 'CUST_WALLET_USD', direction: 'debit', amountMinor: 1000n, currency: 'USD' },
        { accountCode: 'FEE_INCOME_USD', direction: 'credit', amountMinor: 900n, currency: 'USD' },
      ]),
    ).toThrow(/unbalanced/i);
  });

  it('rejects mixed currencies in one journal entry', () => {
    expect(() =>
      assertBalancedPostings([
        { accountCode: 'CUST_WALLET_USD', direction: 'debit', amountMinor: 1000n, currency: 'USD' },
        { accountCode: 'CUST_WALLET_CDF', direction: 'credit', amountMinor: 1000n, currency: 'CDF' },
      ]),
    ).toThrow(/currency/i);
  });
});
