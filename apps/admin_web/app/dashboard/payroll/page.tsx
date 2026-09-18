'use client';

import Link from 'next/link';
import { useState, useEffect, FormEvent } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function PayrollPage() {
  const [employers, setEmployers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [formData, setFormData] = useState({ name: '', taxId: '' });
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    loadEmployers();
  }, []);

  const loadEmployers = async () => {
    setLoading(true);
    try {
      const data = await api.listEmployers();
      setEmployers(Array.isArray(data) ? data : data.employers || []);
    } catch (err) {
      console.error(err);
      setEmployers([]);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    if (!formData.name || !formData.taxId) return;
    setCreating(true);
    try {
      await api.createEmployer(formData);
      setFormData({ name: '', taxId: '' });
      setShowCreateForm(false);
      await loadEmployers();
    } catch (err: any) {
      alert(err.message || 'Failed to create employer');
    } finally {
      setCreating(false);
    }
  };

  return (
    <div>
      <div className="mb-3">
        <button className="btn btn-theme" onClick={() => setShowCreateForm(!showCreateForm)}>
          {showCreateForm ? 'Cancel' : '+ Create Employer'}
        </button>
      </div>

      {showCreateForm && (
        <Panel>
          <PanelHeader>New Employer</PanelHeader>
          <PanelBody>
            <form onSubmit={handleCreate} className="row g-3">
              <div className="col-md-5">
                <label className="form-label">Name</label>
                <input
                  className="form-control"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-5">
                <label className="form-label">Tax ID</label>
                <input
                  className="form-control"
                  value={formData.taxId}
                  onChange={(e) => setFormData({ ...formData, taxId: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-2 d-flex align-items-end">
                <button className="btn btn-success w-100" disabled={creating}>
                  {creating ? 'Saving...' : 'Save'}
                </button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      <Panel>
        <PanelHeader>
          {employers.length} Employers
        </PanelHeader>
        <PanelBody>
          {loading ? (
            <div className="text-center py-4">Loading...</div>
          ) : employers.length === 0 ? (
            <div className="text-center text-gray-500 py-4">No employers found</div>
          ) : (
            <div className="row">
              {employers.map((employer) => (
                <div key={employer.id} className="col-xl-6 mb-3">
                  <Link href={`/dashboard/payroll/${employer.id}`} className="text-decoration-none">
                    <div className="card border-0 shadow-sm h-100">
                      <div className="card-body">
                        <h5 className="card-title text-dark mb-1">{employer.name}</h5>
                        <div className="detail-label mb-2">Tax ID: {employer.taxId}</div>
                        <span className="badge bg-teal">
                          {employer.employeeCount || (employer.employees || []).length} employees
                        </span>
                      </div>
                    </div>
                  </Link>
                </div>
              ))}
            </div>
          )}
        </PanelBody>
      </Panel>
    </div>
  );
}
