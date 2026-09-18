'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import {
  PieChart,
  Pie,
  BarChart,
  Bar,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

const COLORS = {
  teal: '#00acac',
  blue: '#348fe2',
  green: '#32a932',
  yellow: '#f59c1a',
  red: '#ff5b57',
  purple: '#727cb6',
  orange: '#f59c1a',
  info: '#49b6d6',
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
      const data = await api.getDashboardSummary();
      setSummary(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <Panel>
        <PanelBody className="text-center py-5">Loading dashboard...</PanelBody>
      </Panel>
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
    POSTED: COLORS.green,
    COMPLETED: COLORS.green,
    PENDING: COLORS.yellow,
    CONFIRMED: COLORS.blue,
    QUOTED: COLORS.purple,
    FAILED: COLORS.red,
  };

  const kpiCards = [
    {
      label: 'PENDING KYC',
      value: kpis.pendingKyc,
      bg: 'bg-orange',
      icon: 'fa fa-id-card',
      href: '/dashboard/kyc',
    },
    {
      label: 'OPEN CASES',
      value: kpis.openCases,
      bg: 'bg-red',
      icon: 'fa fa-ticket',
      href: '/dashboard/cases',
    },
    {
      label: 'PAYMENTS TODAY',
      value: kpis.paymentsToday,
      bg: 'bg-teal',
      icon: 'fa fa-money-bill',
      href: '/dashboard/payments',
    },
    {
      label: 'ACTIVE AGENTS',
      value: kpis.activeAgents,
      bg: 'bg-blue',
      icon: 'fa fa-users',
      href: '/dashboard/agents',
    },
    {
      label: 'VIRTUAL CARDS',
      value: kpis.totalCards,
      bg: 'bg-indigo',
      icon: 'fa fa-credit-card',
      href: '/dashboard/cards',
    },
  ];

  return (
    <div>
      <div className="row">
        {kpiCards.map((kpi) => (
          <div key={kpi.label} className="col-xl col-md-4 col-sm-6 mb-3">
            <div
              className={`widget widget-stats ${kpi.bg}`}
              style={{ cursor: 'pointer' }}
              onClick={() => router.push(kpi.href)}
            >
              <div className="stats-icon">
                <i className={kpi.icon}></i>
              </div>
              <div className="stats-info">
                <h4>{kpi.label}</h4>
                <p>{kpi.value}</p>
              </div>
              <div className="stats-link">
                <a
                  href={kpi.href}
                  onClick={(e) => {
                    e.preventDefault();
                    router.push(kpi.href);
                  }}
                >
                  View Detail <i className="fa fa-arrow-alt-circle-right"></i>
                </a>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="row">
        <div className="col-xl-6">
          <Panel>
            <PanelHeader>Payment Status Distribution</PanelHeader>
            <PanelBody>
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
                      onClick={(data: any) =>
                        router.push(`/dashboard/payments?status=${data.status}`)
                      }
                      style={{ cursor: 'pointer' }}
                    >
                      {summary.paymentsByStatus.map((entry, index) => (
                        <Cell
                          key={`cell-${index}`}
                          fill={statusColors[entry.status] || COLORS.blue}
                        />
                      ))}
                    </Pie>
                    <Tooltip />
                    <Legend />
                  </PieChart>
                </ResponsiveContainer>
              ) : (
                <div className="text-center text-gray-500 py-5">No payment data available</div>
              )}
            </PanelBody>
          </Panel>
        </div>

        <div className="col-xl-6">
          <Panel>
            <PanelHeader>Payments by Type (Last 7 Days)</PanelHeader>
            <PanelBody>
              {summary && summary.paymentsByType.length > 0 ? (
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={summary.paymentsByType}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="type" />
                    <YAxis allowDecimals={false} />
                    <Tooltip />
                    <Bar
                      dataKey="count"
                      fill={COLORS.teal}
                      onClick={(data: any) =>
                        router.push(`/dashboard/payments?type=${data.type}`)
                      }
                      style={{ cursor: 'pointer' }}
                    />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <div className="text-center text-gray-500 py-5">No payment type data available</div>
              )}
            </PanelBody>
          </Panel>
        </div>
      </div>
    </div>
  );
}
