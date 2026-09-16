import { Injectable } from '@nestjs/common';
import { LedgerService } from '../ledger/ledger.service';
import { InMemoryWalletStore } from '../../common/stores/wallet.store';
import { CurrencyCode } from '../../common/stores/types';

interface Employer {
  id: string;
  name: string;
  taxId: string;
  status: string;
  createdAt: Date;
}

interface Employee {
  id: string;
  employerId: string;
  customerId: string;
  salaryMinor: bigint;
  currency: CurrencyCode;
}

@Injectable()
export class PayrollService {
  private employers = new Map<string, Employer>();
  private employees = new Map<string, Employee>();
  private employerIdCounter = 1;
  private employeeIdCounter = 1;

  constructor(
    private ledgerService: LedgerService,
    private walletStore: InMemoryWalletStore,
  ) {}

  async createEmployer(input: { name: string; taxId: string }) {
    const employer: Employer = {
      id: `employer_${this.employerIdCounter++}`,
      name: input.name,
      taxId: input.taxId,
      status: 'ACTIVE',
      createdAt: new Date(),
    };
    this.employers.set(employer.id, employer);
    return employer;
  }

  async importEmployees(employerId: string, employees: Array<{
    customerId: string;
    salaryMinor: string;
    currency: string;
  }>) {
    const employer = this.employers.get(employerId);
    if (!employer) {
      throw new Error('Employer not found');
    }

    const imported = [];
    for (const emp of employees) {
      const employee: Employee = {
        id: `employee_${this.employeeIdCounter++}`,
        employerId,
        customerId: emp.customerId,
        salaryMinor: BigInt(emp.salaryMinor),
        currency: emp.currency as CurrencyCode,
      };
      this.employees.set(employee.id, employee);
      imported.push(employee);
    }

    return { imported: imported.length, employees: imported };
  }

  async creditSalary(employerId: string, employeeIds: string[]) {
    const employer = this.employers.get(employerId);
    if (!employer) {
      throw new Error('Employer not found');
    }

    const results = [];
    for (const empId of employeeIds) {
      const employee = this.employees.get(empId);
      if (!employee || employee.employerId !== employerId) {
        continue;
      }

      // Get customer wallet
      const wallets = await this.walletStore.findWalletsByCustomerId(employee.customerId);
      if (wallets.length === 0) continue;

      const pockets = await this.walletStore.findPocketsByWalletId(wallets[0].id);
      const pocket = pockets.find((p) => p.currency === employee.currency);
      if (!pocket) continue;

      // Post salary credit
      const result = await this.ledgerService.postJournal({
        idempotencyKey: `salary-${empId}-${Date.now()}`,
        yoleReference: `SALARY-${empId}`,
        correlationId: employerId,
        actorType: 'system',
        actorId: `employer-${employerId}`,
        currency: employee.currency,
        postings: [
          {
            accountCode: 'EMPLOYER_PAYABLE',
            direction: 'debit',
            amountMinor: employee.salaryMinor,
            currency: employee.currency,
          },
          {
            accountCode: 'CUST_WALLET',
            direction: 'credit',
            amountMinor: employee.salaryMinor,
            currency: employee.currency,
            walletPocketId: pocket.id,
          },
        ],
      });

      results.push({ employeeId: empId, journalId: result.journalId, status: result.status });
    }

    return { credited: results.length, results };
  }

  async listEmployers() {
    return Array.from(this.employers.values());
  }
}
