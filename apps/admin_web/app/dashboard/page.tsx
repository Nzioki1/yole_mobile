'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { PieChart, Pie, BarChart, Bar, Cell, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { authService } from '@/lib/auth';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

const COLORS = {
  teal: '#00acac',
  blue: '#348fe2',
  green: '#00acac',
  yellow: '#f59c1a',
  red: '#ff5b57',
  purple: '#727cb6',
};

interface DashboardSummary {
  kpis: {
    pendingKyc: number;
    openCases: number;
    paymentsToday: number;
    activeAgents: number;
    totalCards: number;
  };
  paymentsByStatus: Array<{ status: string; count: number }>;
  paymentsByType: Array<{ type: string; count: number }>;
}

export default function DashboardPage() {
  const router = useRouter();
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadDashboardSummary();
  }, []);

  const loadDashboardSummary = async () => {
    setLoading(true);
    try {
      const token = authService.getToken();
      
      // Try the new dashboard summary endpoint
      try {
        const response = await fetch(`${API_BASE_URL}/v1/admin/dashboard/summary`, {
          headers: {
            'X-Admin-API-Key': 'dev-admin-key',
            ...(token && { 'Authorization': `Bearer ${token}` }),
          },
        });

        if (response.ok) {
          const data = await response.json();
          setSummary(data);
          setLoading(false);
          return;
        }
      } catch (e) {
        console.warn('Dashboard summary endpoint not available, using fallback');
      }

      // Fallback: aggregate from individual endpoints
      const [agentsRes, kycRes, paymentsRes, casesRes, cardsRes] = await Promise.all([
        fetch(`${API_BASE_URL}/v1/admin/agents`, {
          headers: { 'X-Admin-API-Key': 'dev-admin-key', ...(token && { 'Authorization': `Bearer ${token}` }) },
        }).catch(() => null),
        fetch(`${API_BASE_URL}/v1/admin/kyc/submissions?status=PENDING_REVIEW`, {
          headers: { 'X-Admin-API-Key': 'dev-admin-key', ...(token && { 'Authorization': `Bearer ${token}` }) },
        }).catch(() => null),
        fetch(`${API_BASE_URL}/v1/admin/payments/search`, {
          headers: { 'X-Admin-API-Key': 'dev-admin-key', ...(token && { 'Authorization': `Bearer ${token}` }) },
        }).catch(() => null),
        fetch(`${API_BASE_URL}/v1/admin/cases?status=OPEN`, {
          headers: { 'X-Admin-API-Key': 'dev-admin-key', ...(token && { 'Authorization': `Bearer ${token}` }) },
        }).catch(() => null),
        fetch(`${API_BASE_URL}/v1/admin/cards`, {
          headers: { 'X-Admin-API-Key': 'dev-admin-key', ...(token && { 'Authorization': `Bearer ${token}` }) },
        }).catch(() => null),
      ]);

      const agents = agentsRes?.ok ? await agentsRes.json() : [];
      const kyc = kycRes?.ok ? await kycRes.json() : [];
      const payments = paymentsRes?.ok ? await paymentsRes.json() : [];
      const cases = casesRes?.ok ? await casesRes.json() : [];
      const cards = cardsRes?.ok ? await cardsRes.json() : [];

      // Process payments for charts
      const paymentsByStatus: Record<string, number> = {};
      const paymentsByType: Record<string, number> = {};

      (Array.isArray(payments) ? payments : []).forEach((p: any) => {
        paymentsByStatus[p.status] = (paymentsByStatus[p.status] || 0) + 1;
        paymentsByType[p.type] = (paymentsByType[p.type] || 0) + 1;
      });

      setSummary({
        kpis: {
          pendingKyc: Array.isArray(kyc) ? kyc.length : 0,
          openCases: Array.isArray(cases) ? cases.length : 0,
          paymentsToday: Array.isArray(payments) ? payments.length : 0,
          activeAgents: Array.isArray(agents) ? agents.length : 0,
          totalCards: Array.isArray(cards) ? cards.length : 0,
        },
        paymentsByStatus: Object.entries(paymentsByStatus).map(([status, count]) => ({ status, count })),
        paymentsByType: Object.entries(paymentsByType).map(([type, count]) => ({ type, count })),
      });
    } catch (error) {
      console.error('Failed to load dashboard summary:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleKpiClick = (route: string, query?: string) => {
    const url = query ? `${route}?${query}` : route;
    router.push(url);
  };

  const handleChartClick = (data: any, field: string) => {
    if (field === 'status') {
      router.push(`/dashboard/payments?status=${data.status}`);
    } else if (field === 'type') {
      router.push(`/dashboard/payments?type=${data.type}`);
    }
  };

  if (loading) {
    return (
      <div className="panel">
        <div className="panel-body" style={{ textAlign: 'center', padding: '3rem' }}>
          <div>Loading dashboard...</div>
        </div>
      </div>
    );
  }

  const kpis = summary?.kpis || {
    pendingKyc: 0,
    openCases: 0,
    paymentsToday: 0,
    activeAgents: 0,
    totalCards: 0,
  };

  const statusColors: Record<string, string> = {
    COMPLETED: COLORS.green,
    PENDING: COLORS.yellow,
    FAILED: COLORS.red,
  };

  return (
    <div>
      <style jsx>{`
        .kpi-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
          gap: 1.5rem;
          margin-bottom: 2rem;
        }
        .kpi-card {
          background: white;
          border-radius: 0.5rem;
          padding: 1.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          cursor: pointer;
          transition: all 0.15s;
          border-left: 4px solid;
        }
        .kpi-card:hover {
          box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
          transform: translateY(-2px);
        }
        .kpi-card.teal {
          border-color: #00acac;
        }
        .kpi-card.yellow {
          border-color: #f59c1a;
        }
        .kpi-card.red {
          border-color: #ff5b57;
        }
        .kpi-card.blue {
          border-color: #348fe2;
        }
        .kpi-card.purple {
          border-color: #727cb6;
        }
        .kpi-label {
          font-size: 0.875rem;
          color: #6c757d;
          margin-bottom: 0.5rem;
          font-weight: 500;
        }
        .kpi-value {
          font-size: 2rem;
          font-weight: 700;
          color: #2d353c;
        }
        .chart-grid {
          display: grid;
          grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
          gap: 1.5rem;
        }
      `}</style>

      <div className="kpi-grid">
        <div
          className="kpi-card yellow"
          onClick={() => handleKpiClick('/dashboard/kyc', 'status=PENDING_REVIEW')}
        >
          <div className="kpi-label">Pending KYC</div>
          <div className="kpi-value">{kpis.pendingKyc}</div>
        </div>

        <div
          className="kpi-card red"
          onClick={() => handleKpiClick('/dashboard/cases', 'status=OPEN')}
        >
          <div className="kpi-label">Open Cases</div>
          <div className="kpi-value">{kpis.openCases}</div>
        </div>

        <div
          className="kpi-card teal"
          onClick={() => handleKpiClick('/dashboard/payments')}
        >
          <div className="kpi-label">Payments Today</div>
          <div className="kpi-value">{kpis.paymentsToday}</div>
        </div>

        <div
          className="kpi-card blue"
          onClick={() => handleKpiClick('/dashboard/agents')}
        >
          <div className="kpi-label">Active Agents</div>
          <div className="kpi-value">{kpis.activeAgents}</div>
        </div>

        <div
          className="kpi-card purple"
          onClick={() => handleKpiClick('/dashboard/cards')}
        >
          <div className="kpi-label">Virtual Cards</div>
          <div className="kpi-value">{kpis.totalCards}</div>
        </div>
      </div>

      <div className="chart-grid">
        <div className="panel">
          <div className="panel-heading">Payment Status Distribution</div>
          <div className="panel-body">
            {summary && summary.paymentsByStatus.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <PieChart>
                  <Pie
                    data={summary.paymentsByStatus}
                    dataKey="count"
                    nameKey="status"
                    cx="50%"
                    cy="50%"
                    outerRadius={100}
                    label
                    onClick={(data) => handleChartClick(data, 'status')}
                    style={{ cursor: 'pointer' }}
                  >
                    {summary.paymentsByStatus.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={statusColors[entry.status] || COLORS.blue} />
                    ))}
                  </Pie>
                  <Tooltip />
                  <Legend />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div style={{ textAlign: 'center', padding: '3rem', color: '#6c757d' }}>
                No payment data available
              </div>
            )}
          </div>
        </div>

        <div className="panel">
          <div className="panel-heading">Payments by Type (Last 7 Days)</div>
          <div className="panel-body">
            {summary && summary.paymentsByType.length > 0 ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={summary.paymentsByType}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="type" />
                  <YAxis />
                  <Tooltip />
                  <Bar
                    dataKey="count"
                    fill={COLORS.teal}
                    onClick={(data) => handleChartClick(data, 'type')}
                    style={{ cursor: 'pointer' }}
                  />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div style={{ textAlign: 'center', padding: '3rem', color: '#6c757d' }}>
                No payment type data available
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
