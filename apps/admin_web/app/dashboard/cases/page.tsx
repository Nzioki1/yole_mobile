'use client';

import Link from 'next/link';
import { useState, useEffect, FormEvent } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function CasesPage() {
  const [cases, setCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [formData, setFormData] = useState({ type: 'DISPUTE', description: '', customerId: '' });
  const [creating, setCreating] = useState(false);
  const [busy, setBusy] = useState<string | null>(null);

  useEffect(() => {
    loadCases();
  }, []);

  const loadCases = async (status?: string) => {
    setLoading(true);
    try {
      const data = await api.listCases(status);
      setCases(Array.isArray(data) ? data : data.cases || []);
    } catch (err) {
      console.error(err);
      setCases([]);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    if (!formData.type || !formData.description) return;
    setCreating(true);
    try {
      await api.createCase(formData);
      setFormData({ type: 'DISPUTE', description: '', customerId: '' });
      setShowCreateForm(false);
      await loadCases(filterStatus || undefined);
    } catch (err: any) {
      alert(`Failed to create case: ${err.message}`);
    } finally {
      setCreating(false);
    }
  };

  const handleDecision = async (caseId: string, decision: string) => {
    if (!confirm(`Set this case status to "${decision}"?`)) return;
    try {
      await api.updateCase(caseId, decision);
      await loadCases(filterStatus || undefined);
    } catch (err: any) {
      alert(`Failed to update case: ${err.message}`);
    }
  };

  const advanceAml = async (caseId: string, action: string) => {
    setBusy(caseId + action);
    try {
      await api.advanceAmlCase(caseId, action, {
        approverRole: 'ADMIN',
        recommendation: action === 'RECOMMEND' ? 'ESCALATE' : undefined,
      });
      await loadCases(filterStatus || undefined);
    } catch (e: any) {
      alert(e.message || 'Failed');
    } finally {
      setBusy(null);
    }
  };

  return (
    <div>
      <div className="mb-3 d-flex gap-2">
        <button className="btn btn-theme" onClick={() => setShowCreateForm(!showCreateForm)}>
          {showCreateForm ? 'Cancel' : '+ Create Case'}
        </button>
      </div>

      {showCreateForm && (
        <Panel>
          <PanelHeader>Create Case</PanelHeader>
          <PanelBody>
            <form onSubmit={handleCreate} className="row g-3">
              <div className="col-md-4">
                <label className="form-label">Type</label>
                <select
                  className="form-select"
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                >
                  <option value="DISPUTE">Dispute</option>
                  <option value="INQUIRY">Inquiry</option>
                  <option value="FRAUD">Fraud</option>
                  <option value="AML">AML</option>
                </select>
              </div>
              <div className="col-md-4">
                <label className="form-label">Customer ID</label>
                <input
                  className="form-control"
                  value={formData.customerId}
                  onChange={(e) => setFormData({ ...formData, customerId: e.target.value })}
                  placeholder="cust_..."
                />
              </div>
              <div className="col-md-12">
                <label className="form-label">Description</label>
                <textarea
                  className="form-control"
                  rows={3}
                  required
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                />
              </div>
              <div className="col-12">
                <button className="btn btn-success" disabled={creating}>
                  {creating ? 'Creating...' : 'Create Case'}
                </button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      <Panel>
        <PanelHeader>Filter</PanelHeader>
        <PanelBody>
          <div className="row g-2">
            <div className="col-md-6">
              <select
                className="form-select"
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <option value="">All statuses</option>
                <option value="PENDING">Pending</option>
                <option value="OPEN">Open</option>
                <option value="INVESTIGATION">Investigation</option>
                <option value="PENDING_APPROVAL">Pending approval</option>
                <option value="IN_PROGRESS">In Progress</option>
                <option value="RESOLVED">Resolved</option>
                <option value="CLOSED">Closed</option>
                <option value="APPROVED">Approved</option>
              </select>
            </div>
            <div className="col-md-3">
              <button
                className="btn btn-theme w-100"
                onClick={() => loadCases(filterStatus || undefined)}
              >
                Filter
              </button>
            </div>
            <div className="col-md-3">
              <button
                className="btn btn-default w-100"
                onClick={() => {
                  setFilterStatus('');
                  loadCases();
                }}
              >
                Clear
              </button>
            </div>
          </div>
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeader>{cases.length} Cases — AML confidential workflow (DEM-09)</PanelHeader>
        <PanelBody>
          {loading ? (
            <div className="text-center py-4">Loading...</div>
          ) : cases.length === 0 ? (
            <div className="text-center text-gray-500 py-4">No cases found</div>
          ) : (
            <div className="list-group list-group-flush">
              {cases.map((caseItem) => (
                <div key={caseItem.id} className="list-group-item px-0">
                  <div className="d-flex justify-content-between gap-3">
                    <div>
                      <div className="d-flex align-items-center gap-2 mb-1 flex-wrap">
                        <span className="badge bg-secondary">{caseItem.type}</span>
                        {caseItem.confidential && (
                          <span className="badge bg-danger">CONFIDENTIAL</span>
                        )}
                        <span
                          className={`badge ${
                            caseItem.status === 'RESOLVED' ||
                            caseItem.status === 'CLOSED' ||
                            caseItem.status === 'APPROVED'
                              ? 'bg-teal'
                              : caseItem.status === 'INVESTIGATION' ||
                                caseItem.status === 'IN_PROGRESS'
                              ? 'bg-primary'
                              : 'bg-warning'
                          }`}
                        >
                          {caseItem.status}
                        </span>
                        {caseItem.currentStep && (
                          <span className="badge bg-indigo">step: {caseItem.currentStep}</span>
                        )}
                        {caseItem.approverRole && (
                          <span className="badge bg-dark">approverRole: {caseItem.approverRole}</span>
                        )}
                      </div>
                      <div className="detail-label mb-1">
                        ID: {caseItem.id}
                        {caseItem.customerId && (
                          <>
                            {' · '}
                            <Link href={`/dashboard/customer360?customerId=${caseItem.customerId}`}>
                              {caseItem.customerId}
                            </Link>
                          </>
                        )}
                      </div>
                      <div>{caseItem.description}</div>
                      {caseItem.steps && (
                        <div className="detail-label mt-1">
                          Workflow: {(caseItem.steps || []).join(' → ')}
                        </div>
                      )}
                    </div>
                    <div className="d-flex flex-column gap-1">
                      {caseItem.type === 'AML' && caseItem.confidential ? (
                        <>
                          <button
                            className="btn btn-xs btn-primary"
                            disabled={!!busy}
                            onClick={() => advanceAml(caseItem.id, 'INVESTIGATE')}
                          >
                            Investigate
                          </button>
                          <button
                            className="btn btn-xs btn-warning"
                            disabled={!!busy}
                            onClick={() => advanceAml(caseItem.id, 'RECOMMEND')}
                          >
                            Recommend
                          </button>
                          <button
                            className="btn btn-xs btn-success"
                            disabled={!!busy}
                            onClick={() => advanceAml(caseItem.id, 'APPROVE')}
                          >
                            Maker-checker approve
                          </button>
                          <button
                            className="btn btn-xs btn-default"
                            disabled={!!busy}
                            onClick={() => advanceAml(caseItem.id, 'REJECT')}
                          >
                            Deny
                          </button>
                        </>
                      ) : caseItem.status === 'PENDING' || caseItem.status === 'OPEN' ? (
                        <>
                          <button
                            className="btn btn-xs btn-primary"
                            onClick={() => handleDecision(caseItem.id, 'IN_PROGRESS')}
                          >
                            In Progress
                          </button>
                          <button
                            className="btn btn-xs btn-success"
                            onClick={() => handleDecision(caseItem.id, 'RESOLVED')}
                          >
                            Resolve
                          </button>
                          <button
                            className="btn btn-xs btn-default"
                            onClick={() => handleDecision(caseItem.id, 'CLOSED')}
                          >
                            Close
                          </button>
                        </>
                      ) : null}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </PanelBody>
      </Panel>
    </div>
  );
}
