'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService } from '../../../lib/auth';
import { OfflineDemoStore } from '../../../lib/offline/store';

type KPIData = {
  credit: {
    activeLoans: number;
    totalPortfolioMinor: number;
    arrearsCount: number;
    arrearsMinor: number;
  };
  savings: {
    totalGoals: number;
    totalDepositedMinor: number;
    activeTermDeposits: number;
    termDepositMinor: number;
  };
  employer: {
    totalEmployers: number;
    totalEmployees: number;
    activeEmployees: number;
  };
  salary: {
    lastMonthPayments: number;
    lastMonthTotalMinor: number;
    thisMonthPayments: number;
    thisMonthTotalMinor: number;
  };
};

export default function KPIsPage() {
  const router = useRouter();
  const [kpis, setKpis] = useState<KPIData | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const user = authService.getCurrentUser();
    if (!user) {
      router.push('/login');
      return;
    }

    const store = OfflineDemoStore.createFresh();
    const data = store.getDashboardKPIs();
    setKpis(data);
    setLoading(false);
  }, [router]);

  if (loading || !kpis) {
    return <div className="p-6">Loading...</div>;
  }

  const formatCdf = (minor: number) => `FC ${(minor / 100).toLocaleString()}`;

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Dashboard KPIs</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg border shadow-sm">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Active Loans</h3>
          <p className="text-3xl font-bold text-blue-600">{kpis.credit.activeLoans}</p>
          <p className="text-sm text-gray-500 mt-1">Portfolio: {formatCdf(kpis.credit.totalPortfolioMinor)}</p>
        </div>

        <div className="bg-white p-6 rounded-lg border shadow-sm">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Arrears</h3>
          <p className="text-3xl font-bold text-red-600">{kpis.credit.arrearsCount}</p>
          <p className="text-sm text-gray-500 mt-1">Amount: {formatCdf(kpis.credit.arrearsMinor)}</p>
        </div>

        <div className="bg-white p-6 rounded-lg border shadow-sm">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Savings Goals</h3>
          <p className="text-3xl font-bold text-green-600">{kpis.savings.totalGoals}</p>
          <p className="text-sm text-gray-500 mt-1">Total: {formatCdf(kpis.savings.totalDepositedMinor)}</p>
        </div>

        <div className="bg-white p-6 rounded-lg border shadow-sm">
          <h3 className="text-sm font-medium text-gray-600 mb-2">Term Deposits</h3>
          <p className="text-3xl font-bold text-purple-600">{kpis.savings.activeTermDeposits}</p>
          <p className="text-sm text-gray-500 mt-1">Value: {formatCdf(kpis.savings.termDepositMinor)}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <div className="bg-white p-6 rounded-lg border">
          <h2 className="text-lg font-bold mb-4">Credit Portfolio</h2>
          <div className="space-y-3">
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <span className="font-medium">Active Loans</span>
              <span className="text-lg font-bold">{kpis.credit.activeLoans}</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <span className="font-medium">Total Portfolio</span>
              <span className="text-lg font-bold">{formatCdf(kpis.credit.totalPortfolioMinor)}</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-red-50 rounded">
              <span className="font-medium text-red-800">Arrears Count</span>
              <span className="text-lg font-bold text-red-600">{kpis.credit.arrearsCount}</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-red-50 rounded">
              <span className="font-medium text-red-800">Arrears Amount</span>
              <span className="text-lg font-bold text-red-600">{formatCdf(kpis.credit.arrearsMinor)}</span>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg border">
          <h2 className="text-lg font-bold mb-4">Employer & Salary</h2>
          <div className="space-y-3">
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <span className="font-medium">Total Employers</span>
              <span className="text-lg font-bold">{kpis.employer.totalEmployers}</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-gray-50 rounded">
              <span className="font-medium">Total Employees</span>
              <span className="text-lg font-bold">{kpis.employer.totalEmployees}</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-green-50 rounded">
              <span className="font-medium text-green-800">Active Employees</span>
              <span className="text-lg font-bold text-green-600">{kpis.employer.activeEmployees}</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-blue-50 rounded">
              <span className="font-medium text-blue-800">This Month Salaries</span>
              <span className="text-lg font-bold text-blue-600">
                {kpis.salary.thisMonthPayments} ({formatCdf(kpis.salary.thisMonthTotalMinor)})
              </span>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white p-6 rounded-lg border">
        <h2 className="text-lg font-bold mb-4">Salary Reconciliation</h2>
        <div className="overflow-x-auto">
          <table className="min-w-full">
            <thead>
              <tr className="border-b">
                <th className="px-4 py-2 text-left">Period</th>
                <th className="px-4 py-2 text-right">Payments</th>
                <th className="px-4 py-2 text-right">Total Amount</th>
              </tr>
            </thead>
            <tbody>
              <tr className="border-b hover:bg-gray-50">
                <td className="px-4 py-2">This Month</td>
                <td className="px-4 py-2 text-right">{kpis.salary.thisMonthPayments}</td>
                <td className="px-4 py-2 text-right">{formatCdf(kpis.salary.thisMonthTotalMinor)}</td>
              </tr>
              <tr className="border-b hover:bg-gray-50">
                <td className="px-4 py-2">Last Month</td>
                <td className="px-4 py-2 text-right">{kpis.salary.lastMonthPayments}</td>
                <td className="px-4 py-2 text-right">{formatCdf(kpis.salary.lastMonthTotalMinor)}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
