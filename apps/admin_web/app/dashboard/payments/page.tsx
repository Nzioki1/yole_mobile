'use client';

import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function PaymentsSearchPage() {
  const [payments, setPayments] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({ customerId: '', status: '', type: '' });

  const handleSearch = async () => {
    setLoading(true);
    try {
      const activeFilters = Object.fromEntries(
        Object.entries(filters).filter(([_, v]) => v !== ''),
      );
      const data = await api.searchPayments(activeFilters);
      setPayments(Array.isArray(data) ? data : data.payments || []);
    } catch (err) {
      console.error('Failed to search payments:', err);
      setPayments([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    handleSearch();
  }, []);

  return (
    <div>
      <Panel>
        <PanelHeader>Search Filters</PanelHeader>
        <PanelBody>
          <div className="row gy-2">
            <div className="col-md-3">
              <label className="form-label">Customer ID</label>
              <input
                className="form-control"
                value={filters.customerId}
                onChange={(e) => setFilters({ ...filters, customerId: e.target.value })}
                placeholder="cust_..."
              />
            </div>
            <div className="col-md-3">
              <label className="form-label">Status</label>
              <select
                className="form-select"
                value={filters.status}
                onChange={(e) => setFilters({ ...filters, status: e.target.value })}
              >
                <option value="">All</option>
                <option value="QUOTED">Quoted</option>
                <option value="CONFIRMED">Confirmed</option>
                <option value="PENDING">Pending</option>
                <option value="POSTED">Posted</option>
                <option value="FAILED">Failed</option>
              </select>
            </div>
            <div className="col-md-3">
              <label className="form-label">Type</label>
              <select
                className="form-select"
                value={filters.type}
                onChange={(e) => setFilters({ ...filters, type: e.target.value })}
              >
                <option value="">All</option>
                <option value="W2W">Wallet to Wallet</option>
                <option value="MNO_IN">Mobile Money In</option>
                <option value="MNO_OUT">Mobile Money Out</option>
                <option value="BANK_IN">Bank In</option>
                <option value="BANK_OUT">Bank Out</option>
                <option value="BILL">Bill Payment</option>
                <option value="AIRTIME">Airtime</option>
              </select>
            </div>
            <div className="col-md-3 d-flex align-items-end">
              <button className="btn btn-theme w-100" onClick={handleSearch} disabled={loading}>
                {loading ? 'Searching...' : 'Search'}
              </button>
            </div>
          </div>
        </PanelBody>
      </Panel>

      <Panel>
        <PanelHeader>
          {payments.length} {payments.length === 1 ? 'payment' : 'payments'} found
        </PanelHeader>
        <PanelBody className="p-0">
          {loading ? (
            <div className="p-4 text-center">Loading...</div>
          ) : payments.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No payments found</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped table-hover mb-0 align-middle">
                <thead>
                  <tr>
                    <th>ID</th>
                    <th>Customer</th>
                    <th>Type</th>
                    <th>Amount</th>
                    <th>Status</th>
                    <th>Created</th>
                  </tr>
                </thead>
                <tbody>
                  {payments.map((payment) => (
                    <tr key={payment.id}>
                      <td className="font-monospace small">{payment.id}</td>
                      <td className="font-monospace small">{payment.customerId}</td>
                      <td>{payment.type}</td>
                      <td>
                        {payment.currency} {(parseInt(payment.amountMinor) / 100).toFixed(2)}
                      </td>
                      <td>
                        <span
                          className={`badge ${
                            payment.status === 'POSTED'
                              ? 'bg-teal'
                              : payment.status === 'FAILED'
                              ? 'bg-danger'
                              : payment.status === 'PENDING'
                              ? 'bg-warning'
                              : 'bg-primary'
                          }`}
                        >
                          {payment.status}
                        </span>
                      </td>
                      <td className="detail-label">
                        {new Date(payment.createdAt).toLocaleString()}
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
