'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

function money(minor?: string | number, currency = '') {
  const n = typeof minor === 'string' ? parseInt(minor || '0', 10) : minor || 0;
  const formatted = (n / 100).toLocaleString(undefined, {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return currency ? `${currency} ${formatted}` : formatted;
}

export default function ReconPage() {
  const [selectedDate, setSelectedDate] = useState('2026-09-16');
  const [summary, setSummary] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [eodResult, setEodResult] = useState<any>(null);
  const [running, setRunning] = useState(false);

  useEffect(() => {
    loadSummary(selectedDate);
  }, []);

  const loadSummary = async (date: string) => {
    setLoading(true);
    try {
      const data = await api.getDailySummary(date);
      setSummary(data);
    } catch (err) {
      console.error(err);
      setSummary(null);
    } finally {
      setLoading(false);
    }
  };

  const runEod = async () => {
    setRunning(true);
    try {
      const r = await api.runEod(selectedDate);
      setEodResult(r);
      await loadSummary(selectedDate);
    } catch (e: any) {
      alert(e.message || 'EOD failed');
    } finally {
      setRunning(false);
    }
  };

  const exceptions = Array.isArray(summary?.details?.exceptions)
    ? summary.details.exceptions
    : Array.isArray(summary?.details?.unmatched)
    ? summary.details.unmatched
    : [];
  const eod = summary?.details?.eodSnapshot || eodResult?.eodSnapshot || {};
  const suspense = summary?.details?.suspenseMinor ?? eod.suspenseMinor ?? 0;
  const glBalanced = summary?.details?.glBalanced ?? eod.glBalanced ?? false;

  return (
    <div>
      <Panel>
        <PanelHeader>Select Date — EOD / BOD (DEM-11)</PanelHeader>
        <PanelBody>
          <div className="row g-2 align-items-end">
            <div className="col-md-4">
              <input
                type="date"
                className="form-control"
                value={selectedDate}
                onChange={(e) => {
                  setSelectedDate(e.target.value);
                  loadSummary(e.target.value);
                }}
              />
            </div>
            <div className="col-md-3">
              <button
                className="btn btn-theme"
                disabled={loading}
                onClick={() => loadSummary(selectedDate)}
              >
                {loading ? 'Loading...' : 'Load Summary'}
              </button>
            </div>
            <div className="col-md-3">
              <button className="btn btn-success" disabled={running} onClick={runEod}>
                {running ? 'Running EOD...' : 'Run EOD'}
              </button>
            </div>
          </div>
        </PanelBody>
      </Panel>

      {loading ? (
        <Panel>
          <PanelBody className="text-center py-4">Loading...</PanelBody>
        </Panel>
      ) : summary ? (
        <>
          <div className="row">
            <div className="col-md-3 mb-3">
              <div className="widget widget-stats bg-blue">
                <div className="stats-info">
                  <h4>TOTAL TRANSACTIONS</h4>
                  <p>{summary.totalTransactions || 0}</p>
                </div>
              </div>
            </div>
            <div className="col-md-3 mb-3">
              <div className="widget widget-stats bg-teal">
                <div className="stats-info">
                  <h4>TOTAL VOLUME</h4>
                  <p>{money(summary.totalVolumeMinor)}</p>
                </div>
              </div>
            </div>
            <div className="col-md-3 mb-3">
              <div className="widget widget-stats bg-indigo">
                <div className="stats-info">
                  <h4>STATUS</h4>
                  <p>{summary.status || 'N/A'}</p>
                </div>
              </div>
            </div>
            <div className="col-md-3 mb-3">
              <div className={`widget widget-stats ${exceptions.length ? 'bg-orange' : 'bg-green'}`}>
                <div className="stats-info">
                  <h4>EXCEPTIONS</h4>
                  <p>{exceptions.length || summary.exceptionCount || 0}</p>
                </div>
              </div>
            </div>
          </div>

          <div className="row">
            <div className="col-xl-6 mb-3">
              <Panel className="h-100">
                <PanelHeader>GL / EOD snapshot</PanelHeader>
                <PanelBody>
                  <div className="mb-3">
                    <div className="detail-label">GL balanced</div>
                    <div>
                      <span className={`badge ${glBalanced ? 'bg-teal' : 'bg-warning'}`}>
                        {glBalanced ? 'BALANCED' : 'OPEN'}
                      </span>
                    </div>
                  </div>
                  <div className="mb-3">
                    <div className="detail-label">Suspense</div>
                    <div className="fs-5 fw-semibold">
                      {money(suspense, (eod as any).currency || 'CDF')}
                    </div>
                  </div>
                  <div className="mb-3">
                    <div className="detail-label">EOD runAt</div>
                    <div>{(eod as any).runAt || 'Not run yet'}</div>
                  </div>
                  <div>
                    <div className="detail-label">BOD ready</div>
                    <div>{(eod as any).bodReady ? 'Yes' : 'Pending EOD'}</div>
                  </div>
                  {(eod as any).notes && (
                    <div className="mt-3 detail-label">{(eod as any).notes}</div>
                  )}
                </PanelBody>
              </Panel>
            </div>
            <div className="col-xl-6 mb-3">
              <Panel className="h-100">
                <PanelHeader>Matched / exceptions</PanelHeader>
                <PanelBody>
                  <div className="mb-2">
                    Matched: <strong>{summary.matchedCount ?? '—'}</strong>
                  </div>
                  <div>
                    Exception count: <strong>{summary.exceptionCount ?? exceptions.length}</strong>
                  </div>
                </PanelBody>
              </Panel>
            </div>
          </div>

          <Panel>
            <PanelHeader>
              Suspense / Exceptions
              {exceptions.length > 0 && (
                <span className="badge bg-orange ms-2">{exceptions.length}</span>
              )}
            </PanelHeader>
            <PanelBody className="p-0">
              {exceptions.length === 0 ? (
                <div className="p-4 text-center text-gray-500">No open exceptions</div>
              ) : (
                <div className="table-responsive">
                  <table className="table table-striped mb-0 align-middle">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Rail</th>
                        <th>Partner</th>
                        <th className="text-end">Amount</th>
                        <th>Reason</th>
                      </tr>
                    </thead>
                    <tbody>
                      {exceptions.map((exc: any) => (
                        <tr key={exc.id}>
                          <td className="font-monospace small">{exc.id}</td>
                          <td>{exc.rail}</td>
                          <td>{exc.partner || '—'}</td>
                          <td className="text-end">
                            {exc.amountMinor != null
                              ? money(exc.amountMinor, exc.currency)
                              : '—'}
                          </td>
                          <td>{exc.reason}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </PanelBody>
          </Panel>
        </>
      ) : (
        <Panel>
          <PanelBody className="text-center text-gray-500 py-4">
            Pick a date to load reconciliation
          </PanelBody>
        </Panel>
      )}
    </div>
  );
}
