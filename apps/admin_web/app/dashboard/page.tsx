'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';

export default function DashboardPage() {
  const [counts, setCounts] = useState({ customers: 0, payments: 0, pendingKyc: 0, agents: 0 });

  useEffect(() => {
    api.getDashboardCounts().then(setCounts).catch(console.error);
  }, []);

  const cards = [
    { title: 'Customers', count: counts.customers, link: '/dashboard/customers', color: 'blue' },
    { title: 'Payments', count: counts.payments, link: '/dashboard/payments', color: 'green' },
    { title: 'Pending KYC', count: counts.pendingKyc, link: '/dashboard/kyc', color: 'yellow' },
    { title: 'Agents', count: counts.agents, link: '/dashboard/agents', color: 'purple' },
  ];

  const modules = [
    { title: 'Customer 360', link: '/dashboard/customer360', icon: '👤' },
    { title: 'KYC Queue', link: '/dashboard/kyc', icon: '📋' },
    { title: 'Agents', link: '/dashboard/agents', icon: '👥' },
    { title: 'Payments Search', link: '/dashboard/payments', icon: '💰' },
    { title: 'Virtual Cards', link: '/dashboard/cards', icon: '💳' },
    { title: 'Fees & Limits', link: '/dashboard/config', icon: '⚙️' },
    { title: 'Payroll', link: '/dashboard/payroll', icon: '💼' },
    { title: 'Reconciliation', link: '/dashboard/recon', icon: '📊' },
    { title: 'Cases & Support', link: '/dashboard/cases', icon: '🎫' },
  ];

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <h1 className="text-3xl font-bold mb-8">YOLE Admin Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
        {cards.map((card) => (
          <Link key={card.title} href={card.link}>
            <div className={`bg-white p-6 rounded-lg shadow hover:shadow-lg transition`}>
              <h3 className="text-gray-600 text-sm">{card.title}</h3>
              <p className="text-3xl font-bold mt-2">{card.count}</p>
            </div>
          </Link>
        ))}
      </div>

      <h2 className="text-xl font-bold mb-4">Modules</h2>
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {modules.map((module) => (
          <Link key={module.title} href={module.link}>
            <div className="bg-white p-6 rounded-lg shadow hover:shadow-lg transition">
              <span className="text-3xl mb-2 block">{module.icon}</span>
              <h3 className="font-semibold">{module.title}</h3>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
