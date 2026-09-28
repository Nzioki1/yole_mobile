'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService } from '../../../lib/auth';
import { OfflineDemoStore } from '../../../lib/offline/store';

type Employee = {
  employeeId: string;
  customerId: string | null;
  employeeNumber: string;
  displayName: string;
  jobTitle?: string;
  grossSalaryCdfMinor: number;
  netSalaryCdfMinor: number;
  eligibleAdvanceMaxCdfMinor: number;
  status: string;
  salaryMinor: string;
  currency: string;
};

type Employer = {
  id: string;
  name: string;
  taxId: string;
  employeeCount: number;
  employees: Employee[];
};

type SalaryRecord = {
  id: string;
  employeeId: string;
  customerId: string | null;
  period: string;
  grossCdfMinor: number;
  netCdfMinor: number;
  paidAt: string;
  displayName: string;
};

export default function EmployerPortalPage() {
  const router = useRouter();
  const [employer, setEmployer] = useState<Employer | null>(null);
  const [salaryHistory, setSalaryHistory] = useState<SalaryRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingEmployee, setEditingEmployee] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<{
    jobTitle: string;
    grossSalaryCdfMinor: string;
    netSalaryCdfMinor: string;
    status: string;
  }>({ jobTitle: '', grossSalaryCdfMinor: '', netSalaryCdfMinor: '', status: 'ACTIVE' });

  const [addingEmployee, setAddingEmployee] = useState(false);
  const [addForm, setAddForm] = useState<{
    customerId: string;
    employeeNumber: string;
    jobTitle: string;
    grossSalaryCdfMinor: string;
    netSalaryCdfMinor: string;
  }>({ customerId: '', employeeNumber: '', jobTitle: '', grossSalaryCdfMinor: '', netSalaryCdfMinor: '' });

  useEffect(() => {
    const user = authService.getCurrentUser();
    if (!user || user.role !== 'EMPLOYER' || !user.employerId) {
      router.push('/login');
      return;
    }

    const store = OfflineDemoStore.createFresh();
    const empData = store.getEmployer(user.employerId);
    if (!empData) {
      alert('Employer not found');
      router.push('/dashboard');
      return;
    }

    setEmployer(empData);
    setSalaryHistory(store.listSalaryHistory(user.employerId));
    setLoading(false);
  }, [router]);

  const handleEditEmployee = (emp: Employee) => {
    setEditingEmployee(emp.employeeId);
    setEditForm({
      jobTitle: emp.jobTitle || '',
      grossSalaryCdfMinor: emp.grossSalaryCdfMinor.toString(),
      netSalaryCdfMinor: emp.netSalaryCdfMinor.toString(),
      status: emp.status,
    });
  };

  const handleSaveEdit = async () => {
    if (!editingEmployee || !employer) return;

    try {
      const store = OfflineDemoStore.createFresh();
      store.updateEmployee(editingEmployee, {
        jobTitle: editForm.jobTitle,
        grossSalaryCdfMinor: Number(editForm.grossSalaryCdfMinor),
        netSalaryCdfMinor: Number(editForm.netSalaryCdfMinor),
        status: editForm.status,
      });

      const updated = store.getEmployer(employer.id);
      if (updated) {
        setEmployer(updated);
      }
      setEditingEmployee(null);
      alert('Employee updated successfully');
    } catch (error) {
      alert(`Failed to update employee: ${error}`);
    }
  };

  const handleAddEmployee = async () => {
    if (!employer) return;

    try {
      const store = OfflineDemoStore.createFresh();
      store.addEmployee(employer.id, {
        customerId: addForm.customerId || undefined,
        employeeNumber: addForm.employeeNumber,
        jobTitle: addForm.jobTitle,
        grossSalaryCdfMinor: Number(addForm.grossSalaryCdfMinor),
        netSalaryCdfMinor: Number(addForm.netSalaryCdfMinor),
      });

      const updated = store.getEmployer(employer.id);
      if (updated) {
        setEmployer(updated);
      }
      setAddingEmployee(false);
      setAddForm({ customerId: '', employeeNumber: '', jobTitle: '', grossSalaryCdfMinor: '', netSalaryCdfMinor: '' });
      alert('Employee added successfully');
    } catch (error) {
      alert(`Failed to add employee: ${error}`);
    }
  };

  if (loading) {
    return (
      <div className="p-6">
        <p>Loading...</p>
      </div>
    );
  }

  if (!employer) {
    return (
      <div className="p-6">
        <p>Employer not found</p>
      </div>
    );
  }

  const formatCdf = (minor: number) => `FC ${(minor / 100).toLocaleString()}`;

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold">{employer.name}</h1>
        <p className="text-gray-600">Tax ID: {employer.taxId}</p>
        <p className="text-gray-600">Total Employees: {employer.employeeCount}</p>
      </div>

      <div className="mb-6">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">Employees</h2>
          <button
            onClick={() => setAddingEmployee(true)}
            className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            + Add Employee
          </button>
        </div>

        {addingEmployee && (
          <div className="mb-4 p-4 border rounded bg-gray-50">
            <h3 className="font-bold mb-2">Add New Employee</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-1">Employee Number *</label>
                <input
                  type="text"
                  value={addForm.employeeNumber}
                  onChange={(e) => setAddForm({ ...addForm, employeeNumber: e.target.value })}
                  className="w-full px-3 py-2 border rounded"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Customer ID (optional)</label>
                <input
                  type="text"
                  value={addForm.customerId}
                  onChange={(e) => setAddForm({ ...addForm, customerId: e.target.value })}
                  className="w-full px-3 py-2 border rounded"
                  placeholder="e.g. cust_kasee"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Job Title</label>
                <input
                  type="text"
                  value={addForm.jobTitle}
                  onChange={(e) => setAddForm({ ...addForm, jobTitle: e.target.value })}
                  className="w-full px-3 py-2 border rounded"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Gross Salary (CDF minor) *</label>
                <input
                  type="number"
                  value={addForm.grossSalaryCdfMinor}
                  onChange={(e) => setAddForm({ ...addForm, grossSalaryCdfMinor: e.target.value })}
                  className="w-full px-3 py-2 border rounded"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-1">Net Salary (CDF minor) *</label>
                <input
                  type="number"
                  value={addForm.netSalaryCdfMinor}
                  onChange={(e) => setAddForm({ ...addForm, netSalaryCdfMinor: e.target.value })}
                  className="w-full px-3 py-2 border rounded"
                />
              </div>
            </div>
            <div className="mt-4 flex gap-2">
              <button
                onClick={handleAddEmployee}
                disabled={!addForm.employeeNumber || !addForm.grossSalaryCdfMinor || !addForm.netSalaryCdfMinor}
                className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 disabled:bg-gray-400"
              >
                Save
              </button>
              <button
                onClick={() => {
                  setAddingEmployee(false);
                  setAddForm({ customerId: '', employeeNumber: '', jobTitle: '', grossSalaryCdfMinor: '', netSalaryCdfMinor: '' });
                }}
                className="px-4 py-2 bg-gray-300 rounded hover:bg-gray-400"
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        <div className="overflow-x-auto">
          <table className="min-w-full bg-white border">
            <thead>
              <tr className="bg-gray-100">
                <th className="px-4 py-2 border text-left">Employee #</th>
                <th className="px-4 py-2 border text-left">Name / Title</th>
                <th className="px-4 py-2 border text-left">Customer ID</th>
                <th className="px-4 py-2 border text-right">Gross Salary</th>
                <th className="px-4 py-2 border text-right">Net Salary</th>
                <th className="px-4 py-2 border text-center">Status</th>
                <th className="px-4 py-2 border text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {employer.employees.map((emp) => (
                <tr key={emp.employeeId} className="hover:bg-gray-50">
                  {editingEmployee === emp.employeeId ? (
                    <>
                      <td className="px-4 py-2 border">{emp.employeeNumber}</td>
                      <td className="px-4 py-2 border">
                        <input
                          type="text"
                          value={editForm.jobTitle}
                          onChange={(e) => setEditForm({ ...editForm, jobTitle: e.target.value })}
                          className="w-full px-2 py-1 border rounded"
                        />
                      </td>
                      <td className="px-4 py-2 border">{emp.customerId || '-'}</td>
                      <td className="px-4 py-2 border">
                        <input
                          type="number"
                          value={editForm.grossSalaryCdfMinor}
                          onChange={(e) => setEditForm({ ...editForm, grossSalaryCdfMinor: e.target.value })}
                          className="w-full px-2 py-1 border rounded text-right"
                        />
                      </td>
                      <td className="px-4 py-2 border">
                        <input
                          type="number"
                          value={editForm.netSalaryCdfMinor}
                          onChange={(e) => setEditForm({ ...editForm, netSalaryCdfMinor: e.target.value })}
                          className="w-full px-2 py-1 border rounded text-right"
                        />
                      </td>
                      <td className="px-4 py-2 border">
                        <select
                          value={editForm.status}
                          onChange={(e) => setEditForm({ ...editForm, status: e.target.value })}
                          className="w-full px-2 py-1 border rounded"
                        >
                          <option value="ACTIVE">ACTIVE</option>
                          <option value="SUSPENDED">SUSPENDED</option>
                          <option value="TERMINATED">TERMINATED</option>
                        </select>
                      </td>
                      <td className="px-4 py-2 border text-center">
                        <button
                          onClick={handleSaveEdit}
                          className="px-2 py-1 bg-green-600 text-white rounded text-sm hover:bg-green-700 mr-1"
                        >
                          Save
                        </button>
                        <button
                          onClick={() => setEditingEmployee(null)}
                          className="px-2 py-1 bg-gray-300 rounded text-sm hover:bg-gray-400"
                        >
                          Cancel
                        </button>
                      </td>
                    </>
                  ) : (
                    <>
                      <td className="px-4 py-2 border">{emp.employeeNumber}</td>
                      <td className="px-4 py-2 border">{emp.displayName}</td>
                      <td className="px-4 py-2 border">{emp.customerId || '-'}</td>
                      <td className="px-4 py-2 border text-right">{formatCdf(emp.grossSalaryCdfMinor)}</td>
                      <td className="px-4 py-2 border text-right">{formatCdf(emp.netSalaryCdfMinor)}</td>
                      <td className="px-4 py-2 border text-center">
                        <span
                          className={`px-2 py-1 rounded text-xs ${
                            emp.status === 'ACTIVE'
                              ? 'bg-green-100 text-green-800'
                              : emp.status === 'SUSPENDED'
                              ? 'bg-yellow-100 text-yellow-800'
                              : 'bg-red-100 text-red-800'
                          }`}
                        >
                          {emp.status}
                        </span>
                      </td>
                      <td className="px-4 py-2 border text-center">
                        <button
                          onClick={() => handleEditEmployee(emp)}
                          className="px-2 py-1 bg-blue-600 text-white rounded text-sm hover:bg-blue-700"
                        >
                          Edit
                        </button>
                      </td>
                    </>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mb-6">
        <h2 className="text-xl font-bold mb-4">Salary Payment History</h2>
        <div className="overflow-x-auto">
          <table className="min-w-full bg-white border">
            <thead>
              <tr className="bg-gray-100">
                <th className="px-4 py-2 border text-left">Employee</th>
                <th className="px-4 py-2 border text-left">Period</th>
                <th className="px-4 py-2 border text-right">Gross</th>
                <th className="px-4 py-2 border text-right">Net</th>
                <th className="px-4 py-2 border text-left">Paid At</th>
              </tr>
            </thead>
            <tbody>
              {salaryHistory.length === 0 ? (
                <tr>
                  <td colSpan={5} className="px-4 py-8 text-center text-gray-500">
                    No salary history yet
                  </td>
                </tr>
              ) : (
                salaryHistory.map((sal) => (
                  <tr key={sal.id} className="hover:bg-gray-50">
                    <td className="px-4 py-2 border">{sal.displayName}</td>
                    <td className="px-4 py-2 border">{sal.period}</td>
                    <td className="px-4 py-2 border text-right">{formatCdf(sal.grossCdfMinor)}</td>
                    <td className="px-4 py-2 border text-right">{formatCdf(sal.netCdfMinor)}</td>
                    <td className="px-4 py-2 border">{new Date(sal.paidAt).toLocaleString()}</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      <div className="mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded">
        <p className="text-sm text-yellow-800">
          <strong>Note:</strong> This is the employer portal in offline demo mode. Changes are session-only and do not persist across reloads.
        </p>
      </div>
    </div>
  );
}
