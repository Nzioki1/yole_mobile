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
    const jpLoan = list.find((l) => l.customerId === 'cust_kasee');
    expect(jpLoan).toBeTruthy();
    expect(jpLoan!.customerName).toContain('Jean-Paul');
  });

  test('listEmployers projects employees with displayName and import aliases', () => {
    const store = OfflineDemoStore.createFresh();
    const employers = store.listEmployers();
    const poste = employers.find((e) => e.id === 'emp_poste');
    expect(poste).toBeTruthy();
    expect(poste!.employees.length).toBeGreaterThanOrEqual(6);
    
    const amina = poste!.employees.find((e) => e.customerId === 'cust_amina');
    expect(amina).toBeTruthy();
    expect(amina!.displayName).toBe('Amina Payroll');
    expect(amina!.employeeId).toBe('emp_row_amina');
    expect(amina!.employeeNumber).toBe('PD-10042');
    expect(amina!.jobTitle).toBe('Operations Analyst');
    expect(amina!.grossSalaryCdfMinor).toBe(85000000);
    expect(amina!.netSalaryCdfMinor).toBe(72000000);
    expect(amina!.eligibleAdvanceMaxCdfMinor).toBe(36000000);
    expect(amina!.status).toBe('ACTIVE');
    expect(amina!.salaryMinor).toBe('72000000');
    expect(amina!.currency).toBe('CDF');

    const noCustomer = poste!.employees.find((e) => e.employeeNumber === 'PD-10043');
    expect(noCustomer).toBeTruthy();
    expect(noCustomer!.displayName).toBe('Teller Supervisor');
  });

  test('listSalaryHistory filters by employer and projects displayName', () => {
    const store = OfflineDemoStore.createFresh();
    const history = store.listSalaryHistory('emp_poste');
    expect(history.length).toBeGreaterThanOrEqual(3);
    
    const aminaEntries = history.filter((h) => h.customerId === 'cust_amina');
    expect(aminaEntries.length).toBeGreaterThan(0);
    expect(aminaEntries[0].displayName).toBe('Amina Payroll');
    expect(aminaEntries[0].employeeId).toBe('emp_row_amina');
    expect(aminaEntries[0].period).toBeTruthy();
    expect(aminaEntries[0].grossCdfMinor).toBe(85000000);
    expect(aminaEntries[0].netCdfMinor).toBe(72000000);
  });
});
