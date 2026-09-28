import { describe, it, expect, beforeEach } from 'vitest';
import { OfflineDemoStore } from './store';

describe('OfflineDemoStore - Priority Fixes', () => {
  let store: OfflineDemoStore;

  beforeEach(() => {
    store = OfflineDemoStore.createFresh();
  });

  describe('Priority 3: Salary System', () => {
    it('should credit salaries to employee wallets', () => {
      const employerId = 'emp_poste';
      
      const result = store.creditSalaries(employerId);
      
      expect(result.credited).toBe(true);
      expect(result.count).toBeGreaterThan(0);
      expect(parseInt(result.totalMinor)).toBeGreaterThan(0);
    });

    it('should create journal entries for salary credits', () => {
      const employerId = 'emp_poste';
      
      const initialJournalCount = (store as any).u.journals.length;
      store.creditSalaries(employerId);
      const finalJournalCount = (store as any).u.journals.length;
      
      expect(finalJournalCount).toBeGreaterThan(initialJournalCount);
    });

    it('should send notifications for salary credits', () => {
      const employerId = 'emp_poste';
      
      const initialNotifCount = (store as any).u.notifications.length;
      store.creditSalaries(employerId);
      const finalNotifCount = (store as any).u.notifications.length;
      
      expect(finalNotifCount).toBeGreaterThan(initialNotifCount);
    });
  });

  describe('Priority 2: Employer Portal', () => {
    it('should list employees for employer', () => {
      const employer = store.getEmployer('emp_poste');
      
      expect(employer).toBeDefined();
      expect(employer?.employees).toBeDefined();
      expect(Array.isArray(employer?.employees)).toBe(true);
    });

    it('should update employee details', () => {
      const employees = store.listEmployers()[0].employees;
      const employeeId = employees[0].employeeId;
      
      const updated = store.updateEmployee(employeeId, {
        jobTitle: 'Senior Analyst',
        status: 'ACTIVE',
      });
      
      expect(updated.jobTitle).toBe('Senior Analyst');
    });

    it('should add new employee', () => {
      const employerId = 'emp_poste';
      const initialCount = store.listEmployers()[0].employees.length;
      
      store.addEmployee(employerId, {
        employeeNumber: 'TEST-001',
        jobTitle: 'Test Employee',
        grossSalaryCdfMinor: 50000000,
        netSalaryCdfMinor: 42000000,
      });
      
      const finalCount = store.listEmployers()[0].employees.length;
      expect(finalCount).toBe(initialCount + 1);
    });
  });

  describe('Priority 6: Credit Configuration', () => {
    it('should list credit products', () => {
      const products = store.listCreditProducts();
      
      expect(Array.isArray(products)).toBe(true);
      expect(products.length).toBeGreaterThan(0);
      expect(products[0]).toHaveProperty('id');
      expect(products[0]).toHaveProperty('annualRate');
    });

    it('should update credit product', () => {
      const products = store.listCreditProducts();
      const productId = products[0].id;
      
      const updated = store.updateCreditProduct(productId, {
        annualRate: 0.15,
        maxTenorMonths: 24,
      });
      
      expect((updated as any).annualRate).toBe(0.15);
    });

    it('should list scoring configs', () => {
      const configs = store.listScoringConfigs();
      
      expect(Array.isArray(configs)).toBe(true);
      expect(configs.length).toBeGreaterThan(0);
      expect(configs[0]).toHaveProperty('weights');
      expect(configs[0]).toHaveProperty('thresholds');
    });
  });

  describe('Priority 8: Audit Log and KPIs', () => {
    it('should list audit logs', () => {
      const logs = store.listAuditLogs();
      
      expect(Array.isArray(logs)).toBe(true);
    });

    it('should calculate dashboard KPIs', () => {
      const kpis = store.getDashboardKPIs();
      
      expect(kpis).toHaveProperty('credit');
      expect(kpis).toHaveProperty('savings');
      expect(kpis).toHaveProperty('employer');
      expect(kpis).toHaveProperty('salary');
      
      expect(kpis.credit.activeLoans).toBeGreaterThanOrEqual(0);
      expect(kpis.employer.totalEmployers).toBeGreaterThan(0);
    });

    it('should track salary reconciliation', () => {
      const kpis = store.getDashboardKPIs();
      
      expect(kpis.salary).toHaveProperty('lastMonthPayments');
      expect(kpis.salary).toHaveProperty('thisMonthPayments');
      expect(kpis.salary).toHaveProperty('lastMonthTotalMinor');
      expect(kpis.salary).toHaveProperty('thisMonthTotalMinor');
    });
  });
});
