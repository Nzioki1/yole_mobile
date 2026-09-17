'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

const DEMO_KEY = 'idem_replay_demo_001';

export default function IdempotencyPage() {
  const [key, setKey] = useState(DEMO_KEY);
  const [result, setResult] = useState<any>(null);
  const [payments, setPayments] = useState<any[]>([]);
  const [busy, setBusy] = useState(false);

  const loadPayments = async () => {
    const data = await api.searchPayments({ customerId: 'cust_kasee' });
    setPayments(Array.isArray(data) ? data : []);
  };

  useEffect(() => {
    loadPayments();
  }, []);

  const replay = async () => {
    setBusy(true);
    try {
      const r = await api.replayIdempotentConfirm(key);
      setResult(r);
      await loadPayments();
    } catch (e: any) {
      alert(e.message || 'Failed');
    } finally {
      setBusy(false);
    }
  };

  const compensate = async (paymentId: string) => {
    setBusy(true);
    try {
      const r = await api.compensatePayment(paymentId);
      setResult({ compensate: r });
      await loadPayments();
    } catch (e: any) {
      alert(e.message || 'Failed');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <Panel>
        <PanelHeader>Idempotency lab (DEM-05)</PanelHeader>
        <PanelBody>
          <p className="detail-label mb-3">
            Replay the same idempotency key — must return the same payment, no duplicate. Compensate
            posts a reversing journal + notification.
          </p>
          <div className="row g-2 align-items-end mb-3">
            <div className="col-md-8">
              <label className="form-label">Idempotency key</label>
              <input
                className="form-control font-monospace"
                value={key}
                onChange={(e) => setKey(e.target.value)}
              />
            </div>
            <div className="col-md-4">
              <button className="btn btn-theme w-100" disabled={busy} onClick={replay}>
                Replay confirm
              </button>
            </div>
          </div>
          {result && (
            <pre className="bg-light p-3 small mb-0" style={{ maxHeight: 240, overflow: 'auto' }}>
              {JSON.stringify(result, null, 2)}
            </pre>
          )}
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeader>Customer payments (cust_kasee)</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped mb-0 align-middle">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Key</th>
                  <th>Amount</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((p) => (
                  <tr key={p.id}>
                    <td className="font-monospace small">{p.id}</td>
                    <td className="font-monospace small">{p.idempotencyKey || '—'}</td>
                    <td>
                      {p.currency} {(Number(p.amountMinor) / 100).toFixed(2)}
                    </td>
                    <td>
                      <span
                        className={`badge ${
                          p.status === 'COMPENSATED' ? 'bg-orange' : 'bg-teal'
                        }`}
                      >
                        {p.status}
                      </span>
                    </td>
                    <td>
                      {p.status !== 'COMPENSATED' ? (
                        <button
                          className="btn btn-xs btn-warning"
                          disabled={busy}
                          onClick={() => compensate(p.id)}
                        >
                          Compensate
                        </button>
                      ) : (
                        '—'
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </PanelBody>
      </Panel>
    </div>
  );
}
