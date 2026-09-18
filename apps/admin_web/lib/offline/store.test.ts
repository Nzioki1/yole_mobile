import { OfflineDemoStore } from './store';

test('offline store customer360 for cust_kasee has dual wallets', () => {
  const store = OfflineDemoStore.createFresh();
  const c360 = store.getCustomer360('cust_kasee');
  expect(c360.customer.id).toBe('cust_kasee');
  expect(c360.wallets).toHaveLength(2);
});
