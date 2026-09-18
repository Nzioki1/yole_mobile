import { loadUniverse } from './load';

test('loadUniverse returns cust_kasee with CDF+USD wallets and linked journals', () => {
  const u = loadUniverse();
  expect(u.customers.find((c) => c.id === 'cust_kasee')).toBeTruthy();
  const wallets = u.wallets.filter((w) => w.customerId === 'cust_kasee');
  expect(wallets.map((w) => w.currency).sort()).toEqual(['CDF', 'USD']);
  expect(u.journals.some((j) => j.customerId === 'cust_kasee')).toBe(true);
  expect(u.agents.some((a) => a.id === 'agent-001')).toBe(true);
  expect(u.employers.some((e) => e.id === 'emp_poste')).toBe(true);
  expect(u.loans.some((l) => l.status === 'ACTIVE' && l.scheduleId)).toBe(true);
  expect(u.loans.some((l) => l.status === 'PENDING_EXCEPTION')).toBe(true);
  expect(u.pendingApprovals.length).toBeGreaterThan(0);
  expect(u.cases.some((c) => c.type === 'AML' && c.confidential === true)).toBe(true);
});
