import { OfflineDemoStore } from './store';

describe('Jean-Paul demo enrichment seed', () => {
  test('single Jean-Paul customer is cust_kasee with jp.kabila@gmail.com', () => {
    const store = OfflineDemoStore.createFresh();
    const jps = store.listCustomers().filter(
      (c) => c.firstName === 'Jean-Paul' && c.lastName === 'Kabila',
    );
    expect(jps).toHaveLength(1);
    expect(jps[0].id).toBe('cust_kasee');
    expect(jps[0].email).toBe('jp.kabila@gmail.com');
    expect(store.listCustomers().some((c) => c.id === 'cust_jp_kabila')).toBe(false);
  });

  test('emp_poste has at least 6 employees', () => {
    const store = OfflineDemoStore.createFresh();
    const poste = store.listEmployers().find((e) => e.id === 'emp_poste');
    expect(poste).toBeTruthy();
    expect((poste!.employees || []).length).toBeGreaterThanOrEqual(6);
  });

  test('at least 4 pending credit exceptions including Jean-Paul', () => {
    const store = OfflineDemoStore.createFresh();
    const list = store.listCreditExceptions();
    expect(list.length).toBeGreaterThanOrEqual(4);
    expect(list.some((l) => l.customerId === 'cust_kasee' && l.status === 'PENDING_EXCEPTION')).toBe(true);
  });
});
