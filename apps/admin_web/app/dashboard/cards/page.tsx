'use client';

import Link from 'next/link';
import { useState, useEffect } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function CardsPage() {
  const [cards, setCards] = useState<any[]>([]);
  const [auths, setAuths] = useState<any[]>([]);
  const [honesty, setHonesty] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [filterCustomerId, setFilterCustomerId] = useState('');

  useEffect(() => {
    loadCards();
  }, []);

  const loadCards = async (customerId?: string) => {
    setLoading(true);
    try {
      const [data, a, h] = await Promise.all([
        api.listCards(customerId),
        api.listCardAuths(),
        api.getHonesty(),
      ]);
      setCards(Array.isArray(data) ? data : data.cards || []);
      setAuths(Array.isArray(a) ? a : []);
      setHonesty(h);
    } catch (err) {
      console.error(err);
      setCards([]);
    } finally {
      setLoading(false);
    }
  };

  const banner = honesty?.cardsBadge || 'MOCK — not Visa/Mastercard certified';

  return (
    <div>
      <div className="alert alert-warning mb-3" role="alert">
        <strong>{banner}</strong>
      </div>

      <Panel>
        <PanelHeader>Filter</PanelHeader>
        <PanelBody>
          <div className="row g-2">
            <div className="col-md-8">
              <input
                className="form-control"
                value={filterCustomerId}
                onChange={(e) => setFilterCustomerId(e.target.value)}
                placeholder="Filter by Customer ID (cust_...)"
              />
            </div>
            <div className="col-md-2">
              <button
                className="btn btn-theme w-100"
                disabled={loading}
                onClick={() => loadCards(filterCustomerId || undefined)}
              >
                Filter
              </button>
            </div>
            <div className="col-md-2">
              <button
                className="btn btn-default w-100"
                onClick={() => {
                  setFilterCustomerId('');
                  loadCards();
                }}
              >
                Clear
              </button>
            </div>
          </div>
        </PanelBody>
      </Panel>

      <div className="row mb-3">
        <div className="col-md-4">
          <div className="widget widget-stats bg-teal">
            <div className="stats-icon">
              <i className="fa fa-check"></i>
            </div>
            <div className="stats-info">
              <h4>ACTIVE</h4>
              <p>{cards.filter((c) => c.status === 'ACTIVE').length}</p>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="widget widget-stats bg-orange">
            <div className="stats-icon">
              <i className="fa fa-snowflake"></i>
            </div>
            <div className="stats-info">
              <h4>FROZEN</h4>
              <p>{cards.filter((c) => c.status === 'FROZEN').length}</p>
            </div>
          </div>
        </div>
        <div className="col-md-4">
          <div className="widget widget-stats bg-red">
            <div className="stats-icon">
              <i className="fa fa-ban"></i>
            </div>
            <div className="stats-info">
              <h4>BLOCKED</h4>
              <p>{cards.filter((c) => c.status === 'BLOCKED').length}</p>
            </div>
          </div>
        </div>
      </div>

      <Panel>
        <PanelHeader>
          {cards.length} {cards.length === 1 ? 'card' : 'cards'} found
        </PanelHeader>
        <PanelBody className="p-0">
          {loading ? (
            <div className="p-4 text-center">Loading...</div>
          ) : cards.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No cards found</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped table-hover mb-0 align-middle">
                <thead>
                  <tr>
                    <th>Card ID</th>
                    <th>Customer</th>
                    <th>Last 4</th>
                    <th>Network</th>
                    <th>Currency</th>
                    <th>Status</th>
                    <th>Daily Limit</th>
                    <th>Monthly Limit</th>
                  </tr>
                </thead>
                <tbody>
                  {cards.map((card) => (
                    <tr key={card.id}>
                      <td className="font-monospace small">{card.id}</td>
                      <td>
                        <Link href={`/dashboard/customer360?customerId=${card.customerId}`}>
                          {card.customerId}
                        </Link>
                      </td>
                      <td className="fw-bold">•••• {card.last4}</td>
                      <td>
                        <span className="badge bg-secondary">{card.mockNetwork || 'MOCK'}</span>
                      </td>
                      <td>{card.currency}</td>
                      <td>
                        <span
                          className={`badge ${
                            card.status === 'ACTIVE'
                              ? 'bg-teal'
                              : card.status === 'FROZEN'
                              ? 'bg-orange'
                              : 'bg-danger'
                          }`}
                        >
                          {card.status}
                        </span>
                      </td>
                      <td>
                        {card.currency} {(parseInt(card.dailyLimitMinor) / 100).toFixed(2)}
                      </td>
                      <td>
                        {card.currency} {(parseInt(card.monthlyLimitMinor) / 100).toFixed(2)}
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
        <PanelHeader>Mock 3DS authorizations (DEM-07)</PanelHeader>
        <PanelBody className="p-0">
          {!auths.length ? (
            <div className="p-4 text-center text-gray-500">No mock 3DS auths</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped mb-0 align-middle">
                <thead>
                  <tr>
                    <th>Auth ID</th>
                    <th>Card</th>
                    <th>Merchant</th>
                    <th>Amount</th>
                    <th>Status</th>
                    <th>3DS</th>
                    <th>Dispute</th>
                  </tr>
                </thead>
                <tbody>
                  {auths.map((a) => (
                    <tr key={a.id}>
                      <td className="font-monospace small">{a.id}</td>
                      <td className="font-monospace small">{a.cardId}</td>
                      <td>{a.merchant}</td>
                      <td>
                        {a.currency} {(Number(a.amountMinor) / 100).toFixed(2)}
                      </td>
                      <td>
                        <span className="badge bg-warning">{a.status}</span>
                      </td>
                      <td className="detail-label">
                        {a.threeDs
                          ? `${a.threeDs.version || ''} / ${a.threeDs.result || ''}`
                          : '—'}
                      </td>
                      <td>
                        <Link href="/dashboard/cases">case_card_dispute_001</Link>
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
