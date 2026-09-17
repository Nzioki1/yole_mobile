'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function CreditExceptionsPage() {
  const [loans, setLoans] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const all = await api.listLoans();
      const list = (Array.isArray(all) ? all : []).filter(
        (l: any) =>
          l.status === 'PENDING_EXCEPTION' ||
          l.status === 'REJECTED_EXCEPTION' ||
          l.exceptionReason,
      );
      // also include ACTIVE ones that were exceptions if still in listCreditExceptions
      const ex = await api.listCreditExceptions();
      const merged = [...list];
      for (const e of Array.isArray(ex) ? ex : []) {
        if (!merged.find((x) => x.id === e.id)) merged.push(e);
      }
      setLoans(merged);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const decide = async (loanId: string, decision: string) => {
    setBusy(loanId);
    try {
      await api.decideCreditException(loanId, decision);
      await load();
    } catch (e: any) {
      alert(e.message || 'Failed');
    } finally {
      setBusy(null);
    }
  };

  return (
    <div>
      <Panel>
        <PanelHeader>Credit exceptions (DEM-04)</PanelHeader>
        <PanelBody className="p-0">
          {loading ? (
            <div className="p-4 text-center">Loading...</div>
          ) : loans.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No credit exceptions</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>Loan</th>
                    <th>Customer</th>
                    <th>Principal</th>
                    <th>Reason</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {loans.map((l) => (
                    <tr key={l.id}>
                      <td className="font-monospace small">{l.id}</td>
                      <td>
                        <Link href={`/dashboard/customer360?customerId=${l.customerId}`}>
                          {l.customerId}
                        </Link>
                      </td>
                      <td>
                        {l.currency} {(Number(l.principalMinor) / 100).toLocaleString()}
                      </td>
                      <td>{l.exceptionReason || '—'}</td>
                      <td>
                        <span
                          className={`badge ${
                            l.status === 'ACTIVE'
                              ? 'bg-teal'
                              : l.status === 'PENDING_EXCEPTION'
                              ? 'bg-warning'
                              : 'bg-secondary'
                          }`}
                        >
                          {l.status}
                        </span>
                      </td>
                      <td>
                        {l.status === 'PENDING_EXCEPTION' ? (
                          <div className="d-flex gap-1">
                            <button
                              className="btn btn-xs btn-success"
                              disabled={busy === l.id}
                              onClick={() => decide(l.id, 'APPROVE')}
                            >
                              Approve
                            </button>
                            <button
                              className="btn btn-xs btn-default"
                              disabled={busy === l.id}
                              onClick={() => decide(l.id, 'REJECT')}
                            >
                              Reject
                            </button>
                          </div>
                        ) : l.scheduleId ? (
                          <span className="detail-label">schedule {l.scheduleId}</span>
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
    </div>
  );
}
