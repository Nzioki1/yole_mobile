'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function ApprovalsPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);
    try {
      const data = await api.listPendingApprovals();
      setRows(Array.isArray(data) ? data : []);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const decide = async (id: string, decision: string) => {
    setBusy(id);
    try {
      await api.approvePending(id, decision);
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
        <PanelHeader>Pending approvals (DEM-02 maker-checker)</PanelHeader>
        <PanelBody className="p-0">
          {loading ? (
            <div className="p-4 text-center">Loading...</div>
          ) : rows.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No pending approvals</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Type</th>
                    <th>Summary</th>
                    <th>Maker</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((a) => (
                    <tr key={a.id}>
                      <td className="font-monospace small">{a.id}</td>
                      <td>
                        <span className="badge bg-secondary">{a.type}</span>
                      </td>
                      <td>{a.summary}</td>
                      <td className="detail-label">{a.makerStaffId}</td>
                      <td>
                        <span
                          className={`badge ${
                            a.status === 'APPROVED'
                              ? 'bg-teal'
                              : a.status === 'REJECTED'
                              ? 'bg-danger'
                              : 'bg-warning'
                          }`}
                        >
                          {a.status}
                        </span>
                      </td>
                      <td>
                        {a.status === 'PENDING' ? (
                          <div className="d-flex gap-1">
                            <button
                              className="btn btn-xs btn-success"
                              disabled={busy === a.id}
                              onClick={() => decide(a.id, 'APPROVE')}
                            >
                              Approve
                            </button>
                            <button
                              className="btn btn-xs btn-default"
                              disabled={busy === a.id}
                              onClick={() => decide(a.id, 'REJECT')}
                            >
                              Reject
                            </button>
                          </div>
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
