import { OfflineDemoStore } from './store';

describe('OfflineDemoStore AML ban + customers directory', () => {
  test('listAmlBanList returns seeded BANNED and LIFTED entries', () => {
    const store = OfflineDemoStore.createFresh();
    const list = store.listAmlBanList();
    expect(list.length).toBeGreaterThanOrEqual(5);
    expect(list.some((e) => e.status === 'BANNED')).toBe(true);
    expect(list.some((e) => e.id === 'ban_demo_001')).toBe(true);
  });

  test('addAmlBanEntry appends BANNED row', () => {
    const store = OfflineDemoStore.createFresh();
    const before = store.listAmlBanList().length;
    const row = store.addAmlBanEntry({
      fullName: 'NEW DEMO BAN',
      matchType: 'NAME',
      reason: 'Demo add',
      sourceList: 'DEMO_SANCTIONS',
    });
    expect(row.status).toBe('BANNED');
    expect(row.id).toMatch(/^ban_demo_/);
    expect(store.listAmlBanList().length).toBe(before + 1);
  });

  test('liftAmlBanEntry sets LIFTED', () => {
    const store = OfflineDemoStore.createFresh();
    const updated = store.liftAmlBanEntry('ban_demo_001');
    expect(updated.status).toBe('LIFTED');
    expect(store.listAmlBanList().find((e) => e.id === 'ban_demo_001')?.status).toBe('LIFTED');
  });

  test('listCustomers omits passwords and includes cust_kasee', () => {
    const store = OfflineDemoStore.createFresh();
    const list = store.listCustomers();
    expect(list.length).toBeGreaterThanOrEqual(4);
    for (const c of list) {
      expect(c).not.toHaveProperty('password');
    }
    expect(list.some((c) => c.id === 'cust_kasee')).toBe(true);
  });

  test('reset restores ban seed', () => {
    const store = OfflineDemoStore.createFresh();
    store.addAmlBanEntry({
      fullName: 'TEMP',
      matchType: 'NAME',
      reason: 'x',
      sourceList: 'DEMO_SANCTIONS',
    });
    store.reset();
    expect(store.listAmlBanList().some((e) => e.fullName === 'TEMP')).toBe(false);
    expect(store.listAmlBanList().some((e) => e.id === 'ban_demo_001')).toBe(true);
  });
});
