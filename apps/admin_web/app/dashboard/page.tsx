'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';

export default function DashboardPage() {
  const [counts, setCounts] = useState({ 
    agents: '—', 
    pendingKyc: '—', 
    payments: '—', 
    cases: '—',
    cards: '—',
    employers: '—'
  });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadCounts();
  }, []);

  const loadCounts = async () => {
    setLoading(true);
    
    const newCounts = {
      agents: '—',
      pendingKyc: '—',
      payments: '—',
      cases: '—',
      cards: '—',
      employers: '—'
    };

    try {
      const agentsData = await api.listAgents().catch(() => []);
      newCounts.agents = Array.isArray(agentsData) ? String(agentsData.length) : '—';
    } catch (e) {}

    try {
      const kycData = await api.listKycSubmissions('PENDING_REVIEW').catch(() => []);
      newCounts.pendingKyc = Array.isArray(kycData) ? String(kycData.length) : '—';
    } catch (e) {}

    try {
      const paymentsData = await api.searchPayments().catch(() => ({ payments: [] }));
      const payments = Array.isArray(paymentsData) ? paymentsData : (paymentsData.payments || []);
      newCounts.payments = String(payments.length);
    } catch (e) {}

    try {
      const casesData = await api.listCases().catch(() => []);
      const cases = Array.isArray(casesData) ? casesData : (casesData.cases || []);
      newCounts.cases = String(cases.length);
    } catch (e) {}

    try {
      const cardsData = await api.listCards().catch(() => []);
      const cards = Array.isArray(cardsData) ? cardsData : (cardsData.cards || []);
      newCounts.cards = String(cards.length);
    } catch (e) {}

    try {
      const employersData = await api.listEmployers().catch(() => []);
      const employers = Array.isArray(employersData) ? employersData : (employersData.employers || []);
      newCounts.employers = String(employers.length);
    } catch (e) {}

    setCounts(newCounts);
    setLoading(false);
  };

  const kpiCards = [
    { title: 'Total Agents', count: counts.agents, color: 'blue' },
    { title: 'Pending KYC', count: counts.pendingKyc, color: 'yellow' },
    { title: 'Total Payments', count: counts.payments, color: 'green' },
    { title: 'Open Cases', count: counts.cases, color: 'red' },
    { title: 'Virtual Cards', count: counts.cards, color: 'purple' },
    { title: 'Payroll Employers', count: counts.employers, color: 'indigo' },
  ];

  const modules = [
    { title: 'Customer 360', link: '/dashboard/customer360', icon: '👤', description: 'Comprehensive customer view' },
    { title: 'KYC Queue', link: '/dashboard/kyc', icon: '📋', description: 'Review pending KYC submissions' },
    { title: 'Agents', link: '/dashboard/agents', icon: '👥', description: 'Manage agent network' },
    { title: 'Payments Search', link: '/dashboard/payments', icon: '💰', description: 'Search and track payments' },
    { title: 'Virtual Cards', link: '/dashboard/cards', icon: '💳', description: 'Card issuance and management' },
    { title: 'Payroll', link: '/dashboard/payroll', icon: '💼', description: 'Employer salary distribution' },
    { title: 'Reconciliation', link: '/dashboard/recon', icon: '📊', description: 'Daily transaction reconciliation' },
    { title: 'Cases & Support', link: '/dashboard/cases', icon: '🎫', description: 'Customer support cases' },
    { title: 'Fees & Limits', link: '/dashboard/config', icon: '⚙️', description: 'Fee and limit configuration' },
  ];

  return (
    <div>
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {kpiCards.map((card) => (
          <div key={card.title} className="bg-white p-6 rounded-lg shadow">
            <h3 className="text-gray-600 text-sm font-medium">{card.title}</h3>
            <p className="text-3xl font-bold mt-2">
              {loading ? '...' : card.count}
            </p>
          </div>
        ))}
      </div>

      {/* Module Shortcuts */}
      <div>
        <h2 className="text-xl font-bold mb-4 text-gray-900">Quick Access</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {modules.map((module) => (
            <Link key={module.title} href={module.link}>
              <div className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition-shadow h-full">
                <span className="text-3xl mb-3 block">{module.icon}</span>
                <h3 className="font-semibold text-gray-900 mb-1">{module.title}</h3>
                <p className="text-sm text-gray-500">{module.description}</p>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
