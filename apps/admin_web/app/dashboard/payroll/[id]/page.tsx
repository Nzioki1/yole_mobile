'use client';

import Link from 'next/link';
import { useState, useEffect, FormEvent } from 'react';
import { useParams } from 'next/navigation';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function EmployerDetailPage() {
  const params = useParams();
  const employerId = params.id as string;

  const [employer, setEmployer] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [showImportForm, setShowImportForm] = useState(false);
  const [importText, setImportText] = useState('');
  const [importing, setImporting] = useState(false);
  const [crediting, setCrediting] = useState(false);
  const [lastCreditResult, setLastCreditResult] = useState<any>(null);
  const [salaryHistory, setSalaryHistory] = useState<any[]>([]);

  useEffect(() => {
    loadEmployer();
    loadSalaryHistory();
  }, [employerId]);

  const loadEmployer = async () => {
    setLoading(true);
    try {
      const data = await api.listEmployers();
      const employers = Array.isArray(data) ? data : data.employers || [];
      const found = employers.find((e: any) => e.id === employerId);
      setEmployer(found || null);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const loadSalaryHistory = async () => {
    try {
      const history = await api.listSalaryHistory(employerId);
      setSalaryHistory(Array.isArray(history) ? history : []);
    } catch (err) {
      console.error('Failed to load salary history:', err);
    }
  };

  const handleImport = async (e: FormEvent) => {
    e.preventDefault();
    if (!importText.trim()) return;
    setImporting(true);
    try {
      const lines = importText.trim().split('\n');
      const employees = lines
        .map((line) => {
          const [customerId, salaryMinor, currency] = line.split(',').map((s) => s.trim());
          if (customerId && salaryMinor && currency) {
            return { customerId, salaryMinor, currency };
          }
          return null;
        })
        .filter((e) => e !== null);

      if (employees.length === 0) {
        alert('No valid employees found. Format: customerId,salaryMinor,currency');
        return;
      }

      await api.importEmployees(employerId, employees as any);
      setImportText('');
      setShowImportForm(false);
      await loadEmployer();
      alert(`Imported ${employees.length} employees successfully`);
    } catch (err: any) {
      alert(`Import failed: ${err.message}`);
    } finally {
      setImporting(false);
    }
  };

  const handleCreditSalaries = async () => {
    if (!confirm('Credit salaries to all employees?')) return;
    setCrediting(true);
    setLastCreditResult(null);
    try {
      const result = await api.creditSalaries(employerId);
      setLastCreditResult(result);
      await loadEmployer();
    } catch (err: any) {
      alert(`Credit failed: ${err.message}`);
    } finally {
      setCrediting(false);
    }
  };

  if (loading) {
    return <Panel><PanelBody className="text-center py-4">Loading...</PanelBody></Panel>;
  }

  if (!employer) {
    return (
      <Panel>
        <PanelBody className="text-center py-4">
          <div className="mb-3">Employer not found</div>
          <Link href="/dashboard/payroll" className="btn btn-theme btn-sm">Back to Payroll</Link>
        </PanelBody>
      </Panel>
    );
  }

  const employeeCount = employer.employeeCount || (employer.employees || []).length;

  return (
    <div>
      <div className="mb-3">
        <Link href="/dashboard/payroll" className="btn btn-default btn-sm">
          <i className="fa fa-arrow-left me-1"></i> Back
        </Link>
      </div>

      <Panel>
        <PanelHeader>{employer.name}</PanelHeader>
        <PanelBody>
          <div className="row align-items-center">
            <div className="col-md-8">
              <div className="detail-label">Tax ID: {employer.taxId}</div>
              <div className="detail-label">
                Created: {employer.createdAt ? new Date(employer.createdAt).toLocaleDateString() : '—'}
              </div>
            </div>
            <div className="col-md-4 text-md-end">
              <div className="fs-2 fw-bold text-theme">{employeeCount}</div>
              <div className="detail-label">Employees</div>
            </div>
          </div>
          <div className="mt-3 d-flex gap-2 flex-wrap">
            <button className="btn btn-default btn-sm" onClick={() => setShowImportForm(!showImportForm)}>
              {showImportForm ? 'Cancel Import' : 'Import Employees'}
            </button>
            <button
              className="btn btn-theme btn-sm"
              disabled={crediting || employeeCount === 0}
              onClick={handleCreditSalaries}
            >
              {crediting ? 'Crediting...' : 'Credit Salaries'}
            </button>
          </div>
        </PanelBody>
      </Panel>

      {lastCreditResult && (
        <div className="alert alert-success">
          Salary credit posted: {JSON.stringify(lastCreditResult)}
        </div>
      )}

      <Panel>
        <PanelHeader>{(employer.employees || []).length} employees</PanelHeader>
        <PanelBody className="p-0">
          {(employer.employees || []).length === 0 ? (
            <div className="p-4 text-center text-gray-500">No employees imported yet.</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Emp #</th>
                    <th>Job</th>
                    <th>Gross CDF</th>
                    <th>Net CDF</th>
                    <th>Advance max</th>
                    <th>Status</th>
                    <th>Open 360</th>
                  </tr>
                </thead>
                <tbody>
                  {(employer.employees || []).map((emp: any, idx: number) => (
                    <tr key={`${emp.employeeId || emp.customerId}-${idx}`}>
                      <td>{emp.displayName}</td>
                      <td className="font-monospace small">{emp.employeeNumber}</td>
                      <td>{emp.jobTitle || '—'}</td>
                      <td>{(emp.grossSalaryCdfMinor / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                      <td>{(emp.netSalaryCdfMinor / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                      <td>{(emp.eligibleAdvanceMaxCdfMinor / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                      <td><span className="badge bg-success">{emp.status}</span></td>
                      <td>
                        {emp.customerId ? (
                          <Link href={`/dashboard/customer360?customerId=${emp.customerId}`} className="btn btn-default btn-xs">
                            <i className="fa fa-user"></i>
                          </Link>
                        ) : (
                          '—'
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeader>Salary History</PanelHeader>
        <PanelBody className="p-0">
          {salaryHistory.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No salary history yet.</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>Period</th>
                    <th>Employee</th>
                    <th>Gross</th>
                    <th>Net</th>
                    <th>Paid at</th>
                  </tr>
                </thead>
                <tbody>
                  {salaryHistory.map((entry: any, idx: number) => (
                    <tr key={`${entry.id || idx}`}>
                      <td>{entry.period}</td>
                      <td>{entry.displayName}</td>
                      <td>{(entry.grossCdfMinor / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                      <td>{(entry.netCdfMinor / 100).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</td>
                      <td>{new Date(entry.paidAt).toLocaleString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </PanelBody>
      </Panel>

      {showImportForm && (
        <Panel>
          <PanelHeader>Import Employees</PanelHeader>
          <PanelBody>
            <form onSubmit={handleImport}>
              <label className="form-label">One per line: customerId,salaryMinor,currency</label>
              <textarea
                className="form-control mb-2"
                rows={5}
                value={importText}
                onChange={(e) => setImportText(e.target.value)}
                placeholder="cust_kasee,85000,USD"
              />
              <button className="btn btn-success" disabled={importing}>
                {importing ? 'Importing...' : 'Import'}
              </button>
            </form>
          </PanelBody>
        </Panel>
      )}
    </div>
  );
}
