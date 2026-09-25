'use client';

import { useState, useEffect, FormEvent } from 'react';
import { useSearchParams } from 'next/navigation';
import { api } from '@/lib/api';
import { DEMO_CUSTOMERS, DEMO_SEED_ENABLED } from '@/lib/demo-seed';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function Customer360Page() {
  const searchParams = useSearchParams();
  const [customerId, setCustomerId] = useState('');
  const [customer, setCustomer] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const loadCustomer = async (id: string) => {
    if (!id) return;
    setLoading(true);
    setError('');
    setCustomer(null);
    try {
      const data = await api.getCustomer360(id);
      setCustomer(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load customer');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    const q = searchParams?.get('customerId');
    if (q) {
      setCustomerId(q);
      loadCustomer(q);
      return;
    }
    if (DEMO_SEED_ENABLED && DEMO_CUSTOMERS.length > 0) {
      const first = DEMO_CUSTOMERS[0].id;
      setCustomerId(first);
      loadCustomer(first);
    }
  }, [searchParams]);

  const handleSearch = async (e: FormEvent) => {
    e.preventDefault();
    await loadCustomer(customerId);
  };

  const schedules = customer?.loanSchedules || [];

  return (
    <div>
      <Panel>
        <PanelHeader>Lookup Customer</PanelHeader>
        <PanelBody>
          {DEMO_SEED_ENABLED && (
            <div className="mb-3 d-flex flex-wrap gap-2 align-items-center">
              <span className="detail-label">Demo customers:</span>
              {DEMO_CUSTOMERS.map((cust) => (
                <button
                  key={cust.id}
                  type="button"
                  className="btn btn-xs btn-outline-theme"
                  onClick={() => {
                    setCustomerId(cust.id);
                    loadCustomer(cust.id);
                  }}
                >
                  {cust.firstName} {cust.lastName}
                </button>
              ))}
            </div>
          )}
          <form onSubmit={handleSearch} className="row g-2">
            <div className="col-md-9">
              <input
                className="form-control"
                value={customerId}
                onChange={(e) => setCustomerId(e.target.value)}
                placeholder="Enter Customer ID"
              />
            </div>
            <div className="col-md-3">
              <button type="submit" className="btn btn-theme w-100" disabled={loading}>
                {loading ? 'Loading...' : 'Search'}
              </button>
            </div>
          </form>
          {error && <div className="alert alert-danger mt-3 mb-0">{error}</div>}
