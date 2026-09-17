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
        </PanelBody>
      </Panel>

      {customer && (
        <>
          <Panel>
            <PanelHeader>Customer Information</PanelHeader>
            <PanelBody>
              <div className="row">
                <div className="col-md-4 mb-3">
                  <div className="detail-label">Customer ID</div>
                  <div className="font-monospace">{customer.customer.id}</div>
                </div>
                <div className="col-md-4 mb-3">
                  <div className="detail-label">Name</div>
                  <div>
                    {customer.customer.firstName} {customer.customer.lastName}
                  </div>
                </div>
                <div className="col-md-4 mb-3">
                  <div className="detail-label">Email</div>
                  <div>{customer.customer.email || 'N/A'}</div>
                </div>
                <div className="col-md-4 mb-3">
                  <div className="detail-label">Phone</div>
                  <div>{customer.customer.phoneE164 || 'N/A'}</div>
                </div>
                <div className="col-md-4 mb-3">
                  <div className="detail-label">Segment</div>
                  <div>{customer.customer.segment || '—'}</div>
                </div>
                <div className="col-md-4 mb-3">
                  <div className="detail-label">KYC Status</div>
                  <span
                    className={`badge ${
                      customer.customer.kycStatus === 'APPROVED'
                        ? 'bg-teal'
                        : customer.customer.kycStatus === 'PENDING'
                        ? 'bg-warning'
                        : 'bg-secondary'
                    }`}
                  >
                    {customer.customer.kycStatus}
                  </span>
                </div>
              </div>
            </PanelBody>
          </Panel>

          <Panel>
            <PanelHeader>Wallets &amp; Balances</PanelHeader>
            <PanelBody>
              {customer.wallets?.map((wallet: any) => (
                <div key={wallet.id} className="mb-3">
                  <div className="detail-label mb-2">
                    Wallet: {wallet.id} ({wallet.currency})
                  </div>
                  <div className="row">
                    {(wallet.pockets || [wallet]).map((pocket: any) => (
                      <div key={pocket.id || wallet.id} className="col-md-6 mb-2">
                        <div className="card border-0 bg-light">
                          <div className="card-body py-3">
                            <div className="fw-semibold">{pocket.currency || wallet.currency}</div>
                            <div>
                              Available:{' '}
                              {(
                                parseInt(pocket.availableMinor || wallet.availableMinor || '0') /
                                100
                              ).toFixed(2)}
                            </div>
                            <div>
                              Ledger:{' '}
                              {(
                                parseInt(pocket.ledgerMinor || wallet.ledgerMinor || '0') / 100
                              ).toFixed(2)}
                            </div>
                            <div className="detail-label">
                              Blocked:{' '}
                              {(
                                parseInt(pocket.blockedMinor || wallet.blockedMinor || '0') / 100
                              ).toFixed(2)}{' '}
                              · Pending:{' '}
                              {(
                                parseInt(
                                  pocket.pendingOutMinor ||
                                    pocket.pendingMinor ||
                                    wallet.pendingMinor ||
                                    '0',
                                ) / 100
                              ).toFixed(2)}
                            </div>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              ))}
            </PanelBody>
          </Panel>

          <Panel>
            <PanelHeader>Loans (DEM-03/04)</PanelHeader>
            <PanelBody className="p-0">
              {!customer.loans?.length ? (
                <div className="p-4 text-center text-gray-500">No loans</div>
              ) : (
                <div className="table-responsive">
                  <table className="table table-striped mb-0 align-middle">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Product</th>
                        <th>Principal</th>
                        <th>Status</th>
                        <th>Receivable</th>
                        <th>Schedule</th>
                      </tr>
                    </thead>
                    <tbody>
                      {customer.loans.map((l: any) => (
                        <tr key={l.id}>
                          <td className="font-monospace small">{l.id}</td>
                          <td>{l.productId}</td>
                          <td>
                            {l.currency} {(Number(l.principalMinor) / 100).toLocaleString()}
                          </td>
                          <td>
                            <span
                              className={`badge ${
                                l.status === 'ACTIVE' ? 'bg-teal' : 'bg-warning'
                              }`}
                            >
                              {l.status}
                            </span>
                          </td>
                          <td>
                            {l.receivableMinor != null
                              ? (Number(l.receivableMinor) / 100).toLocaleString()
                              : '—'}
                          </td>
                          <td className="font-monospace small">{l.scheduleId || '—'}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </PanelBody>
          </Panel>

          <Panel>
            <PanelHeader>Loan schedule / installments</PanelHeader>
            <PanelBody className="p-0">
              {!schedules.length ? (
                <div className="p-4 text-center text-gray-500">
                  No schedules — approve a credit exception or open Amina for DEM-03
                </div>
              ) : (
                schedules.map((sched: any) => (
                  <div key={sched.id} className="mb-3">
                    <div className="px-3 pt-3 detail-label">
                      Schedule {sched.id} · loan {sched.loanId}
                    </div>
                    <div className="table-responsive">
                      <table className="table table-striped mb-0 align-middle">
                        <thead>
                          <tr>
                            <th>Installment</th>
                            <th>Due</th>
                            <th>Principal</th>
                            <th>Interest</th>
                            <th>Status</th>
                            <th>Paid</th>
                          </tr>
                        </thead>
                        <tbody>
                          {(sched.installments || []).map((inst: any) => (
                            <tr key={inst.id}>
                              <td className="font-monospace small">{inst.id}</td>
                              <td>{inst.dueDate}</td>
                              <td>{(Number(inst.principalMinor) / 100).toLocaleString()}</td>
                              <td>{(Number(inst.interestMinor) / 100).toLocaleString()}</td>
                              <td>
                                <span
                                  className={`badge ${
                                    inst.status === 'PAID' ? 'bg-teal' : 'bg-warning'
                                  }`}
                                >
                                  {inst.status}
                                </span>
                              </td>
                              <td className="detail-label">
                                {inst.paidAt ? new Date(inst.paidAt).toLocaleDateString() : '—'}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                ))
              )}
            </PanelBody>
          </Panel>

          <Panel>
            <PanelHeader>Recent Payments</PanelHeader>
            <PanelBody className="p-0">
              {!customer.recentPayments?.length ? (
                <div className="p-4 text-center text-gray-500">No recent payments</div>
              ) : (
                <div className="table-responsive">
                  <table className="table table-striped mb-0 align-middle">
                    <thead>
                      <tr>
                        <th>ID</th>
                        <th>Type</th>
                        <th>Amount</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {customer.recentPayments.map((p: any) => (
                        <tr key={p.id}>
                          <td className="font-monospace small">{p.id}</td>
                          <td>{p.type}</td>
                          <td>
                            {p.currency} {(parseInt(p.amountMinor) / 100).toFixed(2)}
                          </td>
                          <td>
                            <span className="badge bg-teal">{p.status}</span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </PanelBody>
          </Panel>
        </>
      )}
    </div>
  );
}
