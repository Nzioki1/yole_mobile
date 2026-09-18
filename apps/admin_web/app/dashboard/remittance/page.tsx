'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function RemittancePage() {
  const [rows, setRows] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState<string | null>(null);
  const [recon, setRecon] = useState<any>(null);

  const load = async () => {
    setLoading(true);
    try {
      const data = await api.listRemittances();
      setRows(Array.isArray(data) ? data : []);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const act = async (id: string, action: string) => {
    setBusy(id + action);
    try {
      const r = await api.remittanceAction(id, action);
      if (action === 'PARTNER_RECON') setRecon(r);
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
        <PanelHeader>Remittance admin (DEM-08)</PanelHeader>
        <PanelBody className="p-0">
          {loading ? (
            <div className="p-4 text-center">Loading...</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Customer</th>
                    <th>Partner</th>
                    <th>Send → Receive</th>
                    <th>Status</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((r) => (
                    <tr key={r.id}>
                      <td className="font-monospace small">{r.id}</td>
                      <td>
                        <Link href={`/dashboard/customer360?customerId=${r.customerId}`}>
                          {r.customerId}
                        </Link>
                      </td>
                      <td>{r.partner}</td>
                      <td>
                        {r.sendCurrency} {(Number(r.sendAmountMinor) / 100).toFixed(2)} →{' '}
                        {r.receiveCurrency} {(Number(r.receiveAmountMinor) / 100).toFixed(2)}
                      </td>
                      <td>
                        <span
                          className={`badge ${
                            r.status === 'CLEAR' || r.status === 'CLEARED'
                              ? 'bg-teal'
                              : r.status === 'SCREENING_HIT'
                              ? 'bg-warning'
                              : r.status === 'REFUNDED'
                              ? 'bg-orange'
                              : 'bg-secondary'
                          }`}
                        >
                          {r.status}
                        </span>
                        {r.screeningHit && (
                          <span className="badge bg-danger ms-1">{r.screeningHit}</span>
                        )}
                      </td>
                      <td>
                        <div className="d-flex flex-wrap gap-1">
                          {r.status === 'SCREENING_HIT' && (
                            <>
                              <button
                                className="btn btn-xs btn-success"
                                disabled={!!busy}
                                onClick={() => act(r.id, 'CLEAR')}
                              >
                                Clear
                              </button>
                              <button
                                className="btn btn-xs btn-warning"
                                disabled={!!busy}
                                onClick={() => act(r.id, 'REFUND')}
                              >
                                Refund
                              </button>
                            </>
                          )}
                          <button
                            className="btn btn-xs btn-default"
                            disabled={!!busy}
                            onClick={() => act(r.id, 'PARTNER_RECON')}
                          >
                            Partner recon
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </PanelBody>
      </Panel>

      {recon && (
        <Panel>
          <PanelHeader>Partner recon stub</PanelHeader>
          <PanelBody>
            <pre className="bg-light p-3 small mb-0">{JSON.stringify(recon, null, 2)}</pre>
          </PanelBody>
        </Panel>
      )}
    </div>
  );
}
