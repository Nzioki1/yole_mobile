import { OfflineDemoStore } from './store';

describe('OfflineDemoStore staff users', () => {
  test('listStaff omits password', () => {
    const store = OfflineDemoStore.createFresh();
    const list = store.listStaff();
    expect(list.length).toBeGreaterThanOrEqual(4);
    for (const s of list) {
      expect(s).not.toHaveProperty('password');
      expect(s.email).toBeTruthy();
      expect(s.role).toBeTruthy();
    }
  });

  test('createStaff adds loginable OPS user', () => {
    const store = OfflineDemoStore.createFresh();
    const created = store.createStaff({
      firstName: 'Nova',
      lastName: 'Ops',
      email: 'nova.ops@postefinance.com',
      password: 'Password1!',
      role: 'OPS',
    });
    expect(created.id).toMatch(/^staff_demo_/);
    expect(created.role).toBe('OPS');
    expect(created).not.toHaveProperty('password');

    const auth = store.authenticateStaff('nova.ops@postefinance.com', 'Password1!');
    expect(auth?.id).toBe(created.id);
    expect(auth?.role).toBe('OPS');
  });

  test('createStaff rejects duplicate email case-insensitively', () => {
    const store = OfflineDemoStore.createFresh();
    expect(() =>
      store.createStaff({
        firstName: 'Dup',
        lastName: 'Admin',
        email: 'Admin@postefinance.com',
        password: 'Password1!',
        role: 'SUPPORT',
      }),
    ).toThrow(/already/i);
  });

  test('updateStaffRole changes role', () => {
    const store = OfflineDemoStore.createFresh();
    const created = store.createStaff({
      firstName: 'Sam',
      lastName: 'Support',
      email: 'sam.support@postefinance.com',
      password: 'Password1!',
      role: 'SUPPORT',
    });
    const updated = store.updateStaffRole(created.id, 'FINANCE');
    expect(updated.role).toBe('FINANCE');
    expect(store.listStaff().find((s) => s.id === created.id)?.role).toBe('FINANCE');
  });

  test('updateStaffRole refuses demoting the last ADMIN', () => {
    const store = OfflineDemoStore.createFresh();
    const admins = store.listStaff().filter((s) => s.role === 'ADMIN');
    expect(admins.length).toBeGreaterThanOrEqual(1);
    const onlyAdmin = admins[0];
    expect(() => store.updateStaffRole(onlyAdmin.id, 'OPS')).toThrow(/last.*ADMIN/i);
    expect(store.listStaff().find((s) => s.id === onlyAdmin.id)?.role).toBe('ADMIN');
  });

  test('reset restores seed staff (created users gone)', () => {
    const store = OfflineDemoStore.createFresh();
    store.createStaff({
      firstName: 'Temp',
      lastName: 'User',
      email: 'temp.user@postefinance.com',
      password: 'Password1!',
      role: 'OPS',
    });
    expect(store.listStaff().some((s) => s.email === 'temp.user@postefinance.com')).toBe(true);
    store.reset();
    expect(store.listStaff().some((s) => s.email === 'temp.user@postefinance.com')).toBe(false);
    expect(store.authenticateStaff('admin@postefinance.com', 'Password1!')?.role).toBe('ADMIN');
  });
});
