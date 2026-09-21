'use client';

import { FormEvent, useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { authService } from '@/lib/auth';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';
import Link from 'next/link';

export default function ConfigPage() {
  const [fees, setFees] = useState<any[]>([]);
  const [limits, setLimits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showFeeForm, setShowFeeForm] = useState(false);
  const [showLimitForm, setShowLimitForm] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [feeForm, setFeeForm] = useState({
    paymentType: 'W2W',
    feePercent: '',
    minFeeMinor: '',
    maxFeeMinor: '',
    currency: 'USD',
    effectiveFrom: '',
  });

  const [limitForm, setLimitForm] = useState({
    limitType: 'CUSTOMER_DAILY',
    currency: 'USD',
    dailyLimitMinor: '',
    monthlyLimitMinor: '',
    effectiveFrom: '',
  });

  useEffect(() => {
    const today = new Date().toISOString().slice(0, 10);
    setFeeForm((f) => (f.effectiveFrom ? f : { ...f, effectiveFrom: today }));
    setLimitForm((f) => (f.effectiveFrom ? f : { ...f, effectiveFrom: today }));
  }, []);

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const [feesData, limitsData] = await Promise.all([
        api.listFeeConfigs().catch(() => []),
        api.listLimitConfigs().catch(() => []),
      ]);
      setFees(Array.isArray(feesData) ? feesData : feesData.fees || []);
      setLimits(Array.isArray(limitsData) ? limitsData : limitsData.limits || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const handleFeeSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setMessage(null);
    try {
      const currentUser = authService.getCurrentUser();
      const result = await api.proposeFeeRule({
        paymentType: feeForm.paymentType,
        feePercent: Number(feeForm.feePercent),
        minFeeMinor: Number(feeForm.minFeeMinor),
        maxFeeMinor: Number(feeForm.maxFeeMinor),
        currency: feeForm.currency,
        effectiveFrom: feeForm.effectiveFrom,
        makerStaffId: currentUser?.id,
      });
      setMessage(`Fee rule proposed: ${result.approval.id}`);
      setShowFeeForm(false);
      setFeeForm({
        paymentType: 'W2W',
        feePercent: '',
        minFeeMinor: '',
        maxFeeMinor: '',
        currency: 'USD',
        effectiveFrom: new Date().toISOString().slice(0, 10),
      });
      await loadData();
    } catch (err) {
      setError(String(err));
    }
  };

  const handleLimitSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    setMessage(null);
    try {
      const currentUser = authService.getCurrentUser();
      const result = await api.proposeLimitRule({
        limitType: limitForm.limitType,
        currency: limitForm.currency,
        dailyLimitMinor: Number(limitForm.dailyLimitMinor),
        monthlyLimitMinor: Number(limitForm.monthlyLimitMinor),
        effectiveFrom: limitForm.effectiveFrom,
        makerStaffId: currentUser?.id,
      });
      setMessage(`Limit rule proposed: ${result.approval.id}`);
      setShowLimitForm(false);
      setLimitForm({
        limitType: 'CUSTOMER_DAILY',
        currency: 'USD',
        dailyLimitMinor: '',
        monthlyLimitMinor: '',
        effectiveFrom: new Date().toISOString().slice(0, 10),
      });
      await loadData();
    } catch (err) {
      setError(String(err));
    }
  };

  if (loading) {
    return <Panel><PanelBody className="text-center py-4">Loading...</PanelBody></Panel>;
  }

  return (
    <div>
      <p className="text-muted small mb-3">
        Offline demo — fee/limit changes are session-only until Reset demo
      </p>

      {message && (
        <div className="alert alert-success py-2 mb-3" role="alert">
          {message} — <Link href="/dashboard/approvals">Go to Approvals</Link>
        </div>
      )}

      {error && (
        <div className="alert alert-danger py-2 mb-3" role="alert">
          {error}
        </div>
      )}

      <div className="mb-3 d-flex gap-2">
        <button
          className="btn btn-theme"
          type="button"
          onClick={() => {
            setShowFeeForm(!showFeeForm);
            setShowLimitForm(false);
          }}
        >
          {showFeeForm ? 'Cancel' : '+ Fee rule'}
        </button>
        <button
          className="btn btn-theme"
          type="button"
          onClick={() => {
            setShowLimitForm(!showLimitForm);
            setShowFeeForm(false);
          }}
        >
          {showLimitForm ? 'Cancel' : '+ Limit rule'}
        </button>
      </div>

      {showFeeForm && (
        <Panel>
          <PanelHeader>Propose Fee Rule</PanelHeader>
          <PanelBody>
            <form onSubmit={handleFeeSubmit} className="row g-3">
              <div className="col-md-6">
                <label className="form-label">Payment Type</label>
                <select
                  className="form-select"
                  value={feeForm.paymentType}
                  onChange={(e) => setFeeForm({ ...feeForm, paymentType: e.target.value })}
                  required
                >
                  <option value="W2W">W2W</option>
                  <option value="MNO">MNO</option>
                  <option value="BANK">BANK</option>
                  <option value="BILL">BILL</option>
                </select>
              </div>
              <div className="col-md-6">
                <label className="form-label">Fee Percent</label>
                <input
                  className="form-control"
                  type="number"
                  step="0.01"
                  placeholder="e.g. 1.5"
                  value={feeForm.feePercent}
                  onChange={(e) => setFeeForm({ ...feeForm, feePercent: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-4">
                <label className="form-label">Min Fee (minor)</label>
                <input
                  className="form-control"
                  type="number"
                  placeholder="e.g. 50"
                  value={feeForm.minFeeMinor}
                  onChange={(e) => setFeeForm({ ...feeForm, minFeeMinor: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-4">
                <label className="form-label">Max Fee (minor)</label>
                <input
                  className="form-control"
                  type="number"
                  placeholder="e.g. 5000"
                  value={feeForm.maxFeeMinor}
                  onChange={(e) => setFeeForm({ ...feeForm, maxFeeMinor: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-4">
                <label className="form-label">Currency</label>
                <select
                  className="form-select"
                  value={feeForm.currency}
                  onChange={(e) => setFeeForm({ ...feeForm, currency: e.target.value })}
                  required
                >
                  <option value="USD">USD</option>
                  <option value="CDF">CDF</option>
                </select>
              </div>
              <div className="col-md-6">
                <label className="form-label">Effective From</label>
                <input
                  className="form-control"
                  type="date"
                  value={feeForm.effectiveFrom}
                  onChange={(e) => setFeeForm({ ...feeForm, effectiveFrom: e.target.value })}
                  required
                />
              </div>
              <div className="col-12">
                <button type="submit" className="btn btn-success">
                  Propose Fee Rule
                </button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      {showLimitForm && (
        <Panel>
          <PanelHeader>Propose Limit Rule</PanelHeader>
          <PanelBody>
            <form onSubmit={handleLimitSubmit} className="row g-3">
              <div className="col-md-6">
                <label className="form-label">Limit Type</label>
                <select
                  className="form-select"
                  value={limitForm.limitType}
                  onChange={(e) => setLimitForm({ ...limitForm, limitType: e.target.value })}
                  required
                >
                  <option value="CUSTOMER_DAILY">CUSTOMER_DAILY</option>
                </select>
              </div>
              <div className="col-md-6">
                <label className="form-label">Currency</label>
                <select
                  className="form-select"
                  value={limitForm.currency}
                  onChange={(e) => setLimitForm({ ...limitForm, currency: e.target.value })}
                  required
                >
                  <option value="USD">USD</option>
                  <option value="CDF">CDF</option>
                </select>
              </div>
              <div className="col-md-6">
                <label className="form-label">Daily Limit (minor)</label>
                <input
                  className="form-control"
                  type="number"
                  placeholder="e.g. 200000"
                  value={limitForm.dailyLimitMinor}
                  onChange={(e) => setLimitForm({ ...limitForm, dailyLimitMinor: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <label className="form-label">Monthly Limit (minor)</label>
                <input
                  className="form-control"
                  type="number"
                  placeholder="e.g. 2000000"
                  value={limitForm.monthlyLimitMinor}
                  onChange={(e) => setLimitForm({ ...limitForm, monthlyLimitMinor: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <label className="form-label">Effective From</label>
                <input
                  className="form-control"
                  type="date"
                  value={limitForm.effectiveFrom}
                  onChange={(e) => setLimitForm({ ...limitForm, effectiveFrom: e.target.value })}
                  required
                />
              </div>
              <div className="col-12">
                <button type="submit" className="btn btn-success">
                  Propose Limit Rule
                </button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      <Panel>
        <PanelHeader>Fee Configurations</PanelHeader>
        <PanelBody className="p-0">
          {fees.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No fee configurations found</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Payment Type</th>
                    <th>Fee %</th>
                    <th>Min (minor)</th>
                    <th>Max (minor)</th>
                    <th>Currency</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {fees.map((fee: any) => (
                    <tr key={fee.id}>
                      <td className="font-monospace small">{fee.id}</td>
                      <td>{fee.paymentType}</td>
                      <td>{fee.feePercent}%</td>
                      <td>{fee.minFeeMinor}</td>
                      <td>{fee.maxFeeMinor}</td>
                      <td>{fee.currency}</td>
                      <td>
                        <span
                          className={`badge ${
                            fee.status === 'ACTIVE'
                              ? 'bg-teal'
                              : fee.status === 'PENDING_APPROVAL'
                              ? 'bg-warning'
                              : fee.status === 'SUPERSEDED'
                              ? 'bg-secondary'
                              : 'bg-danger'
                          }`}
                        >
                          {fee.status}
                        </span>
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
        <PanelHeader>Limit Configurations</PanelHeader>
        <PanelBody className="p-0">
          {limits.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No limit configurations found</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Limit Type</th>
                    <th>Currency</th>
                    <th>Daily (minor)</th>
                    <th>Monthly (minor)</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  {limits.map((limit: any) => (
                    <tr key={limit.id}>
                      <td className="font-monospace small">{limit.id}</td>
                      <td>{limit.limitType}</td>
                      <td>{limit.currency}</td>
                      <td>{limit.dailyLimitMinor}</td>
                      <td>{limit.monthlyLimitMinor}</td>
                      <td>
                        <span
                          className={`badge ${
                            limit.status === 'ACTIVE'
                              ? 'bg-teal'
                              : limit.status === 'PENDING_APPROVAL'
                              ? 'bg-warning'
                              : limit.status === 'SUPERSEDED'
                              ? 'bg-secondary'
                              : 'bg-danger'
                          }`}
                        >
                          {limit.status}
                        </span>
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
