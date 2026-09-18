  }

  listCardAuths(cardId?: string) {
    if (!cardId) return this.u.cardAuths.slice();
    return this.u.cardAuths.filter((a) => a.cardId === cardId);
  }

  listEmployers() {
    return this.u.employers.map((e) => {
      const employees = this.u.employees
        .filter((emp) => emp.employerId === e.id)
        .map((emp) => ({
          customerId: emp.customerId,
          salaryMinor: strMinor(emp.netSalaryCdfMinor),
          currency: 'CDF',
          employeeNumber: emp.employeeNumber,
          jobTitle: emp.jobTitle,
          status: emp.status,
        }));
      return {
        ...e,
        employeeCount: e.employeeCount ?? employees.length,
        employees,
      };
    });
  }

  createEmployer(data: { name: string; taxId: string }) {
    const id = `emp_demo_${Date.now()}`;
    const employer: Employer = {
      id,
      name: data.name,
      taxId: data.taxId,
      employeeCount: 0,
      createdAt: new Date().toISOString(),
    };
    this.u.employers.push(employer);
    return { ...employer, employees: [] as Employee[] };
  }

  importEmployees(
    employerId: string,
    employees: { customerId: string; salaryMinor: string; currency: string }[],
  ) {
    for (const row of employees) {
      const id = `emp_row_demo_${Date.now()}_${row.customerId}`;
      this.u.employees.push({
        id,
        employerId,
        customerId: row.customerId,
        employeeNumber: id,
        grossSalaryCdfMinor: Number(row.salaryMinor),
        netSalaryCdfMinor: Number(row.salaryMinor),
        eligibleAdvanceMaxCdfMinor: Math.floor(Number(row.salaryMinor) / 2),
        status: 'ACTIVE',
        hiredAt: new Date().toISOString().slice(0, 10),
      });
    }
    const employer = this.u.employers.find((e) => e.id === employerId);
    if (employer) {
      employer.employeeCount = this.u.employees.filter((e) => e.employerId === employerId).length;
    }
    return { employerId, imported: employees.length, employees };
  }

  creditSalaries(employerId: string) {
    const employees = this.u.employees.filter((e) => e.employerId === employerId);
    let total = 0;
    for (const emp of employees) {
      total += emp.netSalaryCdfMinor;
      this.u.salaryHistory.push({
        id: `sal_demo_${Date.now()}_${emp.id}`,
        employeeId: emp.id,
        customerId: emp.customerId,
        period: new Date().toISOString().slice(0, 7),
        grossCdfMinor: emp.grossSalaryCdfMinor,
        netCdfMinor: emp.netSalaryCdfMinor,
        paidAt: new Date().toISOString(),
      });
    }
    return {
      employerId,
      credited: true,
      count: employees.length,
      totalMinor: strMinor(total),
      message: 'Offline demo salary credit posted',
    };
  }

  getDailySummary(date: string) {
    const day: ReconDay | undefined =
