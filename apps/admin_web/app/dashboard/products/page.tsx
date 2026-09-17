'use client';

import { FormEvent, useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { authService } from '@/lib/auth';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function ProductsPage() {
  const [products, setProducts] = useState<any[]>([]);
  const [fees, setFees] = useState<any[]>([]);
  const [limits, setLimits] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  
  const [showFeeForm, setShowFeeForm] = useState(false);
  const [showLimitForm, setShowLimitForm] = useState(false);
  const [editingFee, setEditingFee] = useState<any | null>(null);
  const [editingLimit, setEditingLimit] = useState<any | null>(null);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const [feeForm, setFeeForm] = useState({
    paymentType: 'W2W',
    feePercent: '',
    minFeeMinor: '',
    maxFeeMinor: '',
    currency: 'USD',
    effectiveFrom: new Date().toISOString().slice(0, 10),
  });

  const [limitForm, setLimitForm] = useState({
    limitType: 'CUSTOMER_DAILY',
    currency: 'USD',
    dailyLimitMinor: '',
    monthlyLimitMinor: '',
    effectiveFrom: new Date().toISOString().slice(0, 10),
  });

  useEffect(() => {
    loadData();
  }, []);

  const loadData = async () => {
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
        supersedesId: editingFee?.id,
      });
      setMessage(`Fee rule proposed: ${result.approval.id}`);
      setShowFeeForm(false);
      setEditingFee(null);
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
        supersedesId: editingLimit?.id,
      });
      setMessage(`Limit rule proposed: ${result.approval.id}`);
      setShowLimitForm(false);
      setEditingLimit(null);
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

  const handleEditFee = (fee: any) => {
    setEditingFee(fee);
    setFeeForm({
      paymentType: fee.paymentType || 'W2W',
      feePercent: fee.feePercent?.toString() || '',
      minFeeMinor: fee.minFeeMinor?.toString() || '',
      maxFeeMinor: fee.maxFeeMinor?.toString() || '',
      currency: fee.currency || 'USD',
      effectiveFrom: fee.effectiveFrom || new Date().toISOString().slice(0, 10),
    });
    setShowFeeForm(true);
    setShowLimitForm(false);
  };

  const handleEditLimit = (limit: any) => {
    setEditingLimit(limit);
    setLimitForm({
      limitType: limit.limitType || 'CUSTOMER_DAILY',
      currency: limit.currency || 'USD',
      dailyLimitMinor: limit.dailyLimitMinor?.toString() || '',
      monthlyLimitMinor: limit.monthlyLimitMinor?.toString() || '',
      effectiveFrom: limit.effectiveFrom || new Date().toISOString().slice(0, 10),
    });
    setShowLimitForm(true);
    setShowFeeForm(false);
  };

  const handleCancelFee = () => {
    setShowFeeForm(false);
    setEditingFee(null);
    setFeeForm({
      paymentType: 'W2W',
      feePercent: '',
      minFeeMinor: '',
      maxFeeMinor: '',
      currency: 'USD',
      effectiveFrom: new Date().toISOString().slice(0, 10),
    });
  };

  const handleCancelLimit = () => {
    setShowLimitForm(false);
    setEditingLimit(null);
    setLimitForm({
      limitType: 'CUSTOMER_DAILY',
      currency: 'USD',
      dailyLimitMinor: '',
      monthlyLimitMinor: '',
      effectiveFrom: new Date().toISOString().slice(0, 10),
    });
  };

  if (loading) {
    return (
      <Panel>
        <PanelBody className="text-center py-4">Loading...</PanelBody>
      </Panel>
    );
  }

  return (
    <div>
      <p className="text-muted small mb-3">
        New and edited rules go to Pending approvals. Approve there to activate. Reset demo restores seed.
      </p>

      {message && (
        <div className="alert alert-success py-2 mb-3" role="alert">
          {message}
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
            setEditingFee(null);
            if (showFeeForm) handleCancelFee();
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
            setEditingLimit(null);
            if (showLimitForm) handleCancelLimit();
          }}
        >
          {showLimitForm ? 'Cancel' : '+ Limit rule'}
        </button>
      </div>

      {showFeeForm && (
        <Panel>
          <PanelHeader>{editingFee ? 'Edit Fee Rule' : 'Create Fee Rule'}</PanelHeader>
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
                  {editingFee ? 'Propose Edit' : 'Propose Fee Rule'}
                </button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      {showLimitForm && (
        <Panel>
          <PanelHeader>{editingLimit ? 'Edit Limit Rule' : 'Create Limit Rule'}</PanelHeader>
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
                  {editingLimit ? 'Propose Edit' : 'Propose Limit Rule'}
                </button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

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
        <PanelHeader>Fee rules</PanelHeader>
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
                  <th>Actions</th>
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
                            : f.status === 'SUPERSEDED'
                            ? 'bg-secondary'
                            : 'bg-danger'
                        }`}
                      >
                        {f.status}
                      </span>
                    </td>
                    <td>
                      {f.status === 'ACTIVE' && (
                        <button
                          className="btn btn-sm btn-outline-primary"
                          onClick={() => handleEditFee(f)}
                        >
                          Edit
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeader>Limit rules</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped mb-0 align-middle">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Type</th>
                  <th>Currency</th>
                  <th>Daily</th>
                  <th>Monthly</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {limits.map((l) => (
                  <tr key={l.id}>
                    <td className="font-monospace small">{l.id}</td>
                    <td>{l.limitType || 'CUSTOMER_DAILY'}</td>
                    <td>{l.currency}</td>
                    <td>{l.dailyLimit}</td>
                    <td>{l.monthlyLimit}</td>
                    <td>
                      <span
                        className={`badge ${
                          l.status === 'ACTIVE'
                            ? 'bg-teal'
                            : l.status === 'PENDING_APPROVAL'
                            ? 'bg-warning'
                            : l.status === 'SUPERSEDED'
                            ? 'bg-secondary'
                            : 'bg-danger'
                        }`}
                      >
                        {l.status}
                      </span>
                    </td>
                    <td>
                      {l.status === 'ACTIVE' && (
                        <button
                          className="btn btn-sm btn-outline-primary"
                          onClick={() => handleEditLimit(l)}
                        >
                          Edit
                        </button>
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
