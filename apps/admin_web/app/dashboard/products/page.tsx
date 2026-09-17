'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function ProductsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [fees, setFees] = useState<any[]>([]);
  const [limits, setLimits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      setLoading(true);
      try {
        const [p, f, l] = await Promise.all([
          api.listProducts(),
          api.listFeeConfigs(),
          api.listLimitConfigs(),
        ]);
        setProducts(Array.isArray(p) ? p : []);
        setFees(Array.isArray(f) ? f : []);
        setLimits(Array.isArray(l) ? l : []);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  if (loading) {
    return (
      <Panel>
        <PanelBody className="text-center py-4">Loading...</PanelBody>
      </Panel>
    );
  }

  return (
    <div>
      <Panel>
        <PanelHeader>Products &amp; rules (DEM-02)</PanelHeader>
        <PanelBody className="p-0">
          {products.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No products</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>Code</th>
                    <th>Name</th>
                    <th>Segment</th>
                    <th>Status</th>
                    <th>Rules</th>
                  </tr>
                </thead>
                <tbody>
                  {products.map((p) => (
                    <tr key={p.id}>
                      <td className="font-monospace small">{p.code}</td>
                      <td>{p.name}</td>
                      <td>{p.segment}</td>
                      <td>
                        <span className="badge bg-teal">{p.status}</span>
                      </td>
                      <td className="detail-label">
                        {p.maxAdvancePct != null && `maxAdvance ${p.maxAdvancePct}% `}
                        {p.autoApproveMaxMinor != null &&
                          `autoApprove ≤ ${p.autoApproveMaxMinor}`}
                        {p.currencies && p.currencies.join(', ')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeader>Fee limits</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped mb-0 align-middle">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Type</th>
                  <th>Value</th>
                  <th>Effective</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {fees.map((f) => (
                  <tr key={f.id}>
                    <td className="font-monospace small">{f.id}</td>
                    <td>{f.paymentType}</td>
                    <td>{f.value}</td>
                    <td>{f.effectiveFrom}</td>
                    <td>
                      <span
                        className={`badge ${
                          f.status === 'ACTIVE'
                            ? 'bg-teal'
                            : f.status === 'PENDING_APPROVAL'
                            ? 'bg-warning'
                            : 'bg-secondary'
                        }`}
                      >
                        {f.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeader>Limits</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped mb-0 align-middle">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Currency</th>
                  <th>Daily</th>
                  <th>Monthly</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {limits.map((l) => (
                  <tr key={l.id}>
                    <td className="font-monospace small">{l.id}</td>
                    <td>{l.currency}</td>
                    <td>{l.dailyLimit}</td>
                    <td>{l.monthlyLimit}</td>
                    <td>
                      <span className="badge bg-teal">{l.status}</span>
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
