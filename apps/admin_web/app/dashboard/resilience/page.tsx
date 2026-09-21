'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function ResiliencePage() {
  const [journals, setJournals] = useState<any[]>([]);
  const [honesty, setHonesty] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    (async () => {
      setLoading(true);
      try {
        const [j, h] = await Promise.all([api.listJournals(), api.getHonesty()]);
        setJournals(Array.isArray(j) ? j : []);
        setHonesty(h);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const debit = journals
    .filter((j) => j.direction === 'DEBIT')
    .reduce((s, j) => s + Number(j.amountMinor), 0);
  const credit = journals
    .filter((j) => j.direction === 'CREDIT')
    .reduce((s, j) => s + Number(j.amountMinor), 0);

  const banner =
    honesty?.resilienceBadge || 'DEMO STORYBOARD — not a live HA failover';

  return (
    <div>
      <div className="alert alert-warning mb-3" role="alert">
        <strong>{banner}</strong>
      </div>

      <Panel>
        <PanelHeader>Resilience storyboard (DEM-10)</PanelHeader>
        <PanelBody>
          <ol className="mb-0">
            <li>Primary node simulated failure (storyboard only)</li>
            <li>Traffic failed over to standby — demo narrative</li>
            <li>Ledger journals remain balanced — integrity check below</li>
            <li>No live HA / DR claim — offline seed only</li>
          </ol>
        </PanelBody>
      </Panel>

      <div className="row">
        <div className="col-md-4 mb-3">
          <div className="widget widget-stats bg-blue">
            <div className="stats-info">
              <h4>JOURNAL DEBITS</h4>
              <p>{(debit / 100).toLocaleString()}</p>
            </div>
          </div>
        </div>
        <div className="col-md-4 mb-3">
          <div className="widget widget-stats bg-teal">
            <div className="stats-info">
              <h4>JOURNAL CREDITS</h4>
              <p>{(credit / 100).toLocaleString()}</p>
            </div>
          </div>
        </div>
        <div className="col-md-4 mb-3">
          <div className="widget widget-stats bg-indigo">
            <div className="stats-info">
              <h4>ENTRIES</h4>
              <p>{journals.length}</p>
            </div>
          </div>
        </div>
      </div>

      <Panel>
        <PanelHeader>Balanced journals</PanelHeader>
        <PanelBody className="p-0">
          {loading ? (
            <div className="p-4 text-center">Loading...</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Type</th>
                    <th>Direction</th>
                    <th>Amount</th>
                    <th>Ref</th>
                    <th>Posted</th>
                  </tr>
                </thead>
                <tbody>
                  {journals.map((j) => (
                    <tr key={j.id}>
                      <td className="font-monospace small">{j.id}</td>
                      <td>{j.type}</td>
                      <td>
                        <span
                          className={`badge ${
                            j.direction === 'CREDIT' ? 'bg-teal' : 'bg-orange'
                          }`}
                        >
                          {j.direction}
                        </span>
                      </td>
                      <td>
                        {j.currency} {(Number(j.amountMinor) / 100).toFixed(2)}
                      </td>
                      <td className="font-monospace small">{j.refId || '—'}</td>
                      <td className="detail-label">
                        {j.postedAt ? new Date(j.postedAt).toLocaleString() : '—'}
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
