'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { api } from '@/lib/api';

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

  useEffect(() => {
    loadEmployer();
  }, [employerId]);

  const loadEmployer = async () => {
    setLoading(true);
    try {
      const data = await api.listEmployers();
      const employers = Array.isArray(data) ? data : data.employers || [];
      const found = employers.find((e: any) => e.id === employerId);
      setEmployer(found || null);
    } catch (err) {
      console.error('Failed to load employer:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleImport = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!importText.trim()) return;

    setImporting(true);
    try {
      // Parse format: customerId,salaryMinor,currency (one per line)
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

      const result = await api.importEmployees(employerId, employees as any);
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
    if (!confirm('Credit salaries to all employees? This will post payments immediately.')) {
      return;
    }

    setCrediting(true);
    setLastCreditResult(null);
    try {
      const result = await api.creditSalaries(employerId);
      setLastCreditResult(result);
      alert(`Salary credit successful! ${result.successCount || 0} payments posted.`);
    } catch (err: any) {
      alert(`Salary credit failed: ${err.message}`);
    } finally {
      setCrediting(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div>Loading...</div>
      </div>
    );
  }

  if (!employer) {
    return (
      <div>
        <div className="bg-white p-8 rounded-lg shadow text-center">
          <h2 className="text-xl font-bold mb-2">Employer Not Found</h2>
          <p className="text-gray-600">The employer ID {employerId} does not exist.</p>
          <Link href="/dashboard/payroll" className="text-blue-600 hover:underline inline-block mt-4">
            ← Back to Payroll
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div>

      <div className="bg-white p-6 rounded-lg shadow mb-6">
        <div className="flex justify-between items-start">
          <div>
            <h1 className="text-3xl font-bold">{employer.name}</h1>
            <p className="text-gray-600 mt-2">Tax ID: {employer.taxId}</p>
            <p className="text-sm text-gray-500 mt-1">
              Created: {new Date(employer.createdAt).toLocaleDateString()}
            </p>
          </div>
          <div className="text-right">
            <div className="text-3xl font-bold text-blue-600">{employer.employeeCount || 0}</div>
            <div className="text-sm text-gray-600">Employees</div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <div className="bg-white p-6 rounded-lg shadow">
          <h2 className="text-xl font-bold mb-4">Actions</h2>
          <div className="space-y-3">
            <button
              onClick={() => setShowImportForm(!showImportForm)}
              className="w-full px-4 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 text-left"
            >
              📋 Import Employees
            </button>
            <button
              onClick={handleCreditSalaries}
              disabled={crediting || (employer.employeeCount || 0) === 0}
              className="w-full px-4 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 text-left disabled:bg-gray-400"
            >
              {crediting ? '⏳ Processing...' : '💰 Credit Salaries to All Employees'}
            </button>
          </div>
        </div>

        {lastCreditResult && (
          <div className="bg-green-50 border border-green-200 p-6 rounded-lg">
            <h3 className="text-lg font-bold text-green-800 mb-2">✅ Last Salary Credit</h3>
            <div className="space-y-2 text-sm">
              <p>
                <span className="font-semibold">Successful:</span> {lastCreditResult.successCount || 0}
              </p>
              <p>
                <span className="font-semibold">Failed:</span> {lastCreditResult.failureCount || 0}
              </p>
              <p className="text-xs text-gray-600 mt-2">
                Check customer wallets via Customer 360 to verify credits
              </p>
            </div>
          </div>
        )}
      </div>

      {showImportForm && (
        <div className="bg-white p-6 rounded-lg shadow mb-6">
          <h2 className="text-xl font-bold mb-4">Import Employees</h2>
          <form onSubmit={handleImport}>
            <div className="mb-4">
              <label className="block text-sm font-medium mb-2">
                Paste employee data (one per line: customerId,salaryMinor,currency)
              </label>
              <textarea
                value={importText}
                onChange={(e) => setImportText(e.target.value)}
                placeholder="cust_abc123,50000,USD&#10;cust_def456,75000,USD&#10;cust_ghi789,100000,CDF"
                rows={8}
                className="w-full px-3 py-2 border rounded-lg font-mono text-sm"
              />
              <p className="text-xs text-gray-500 mt-2">
                Example: cust_abc123,50000,USD (salary in minor units, e.g., 50000 = $500.00)
              </p>
            </div>
            <div className="flex gap-3">
              <button
                type="submit"
                disabled={importing}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
              >
                {importing ? 'Importing...' : 'Import Employees'}
              </button>
              <button
                type="button"
                onClick={() => {
                  setShowImportForm(false);
                  setImportText('');
                }}
                className="px-6 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400"
              >
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="bg-white p-6 rounded-lg shadow">
        <h2 className="text-xl font-bold mb-4">How to Verify Salary Credits</h2>
        <div className="prose text-sm text-gray-700">
          <ol className="list-decimal ml-5 space-y-2">
            <li>Navigate to <Link href="/dashboard/customer360" className="text-blue-600 hover:underline">Customer 360</Link></li>
            <li>Enter a customer ID from the import list</li>
            <li>Check wallet balances and recent payments</li>
            <li>Look for payment type: <code className="bg-gray-100 px-2 py-1 rounded">SALARY_CREDIT</code></li>
            <li>Verify the amount matches the imported salary</li>
          </ol>
          <p className="mt-4 text-xs text-gray-500">
            Note: All salary credits are instant and appear immediately in customer wallets.
          </p>
        </div>
      </div>
    </div>
  );
}
