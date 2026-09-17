'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';

export default function CardsPage() {
  const [cards, setCards] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterCustomerId, setFilterCustomerId] = useState('');

  useEffect(() => {
    loadCards();
  }, []);

  const loadCards = async (customerId?: string) => {
    setLoading(true);
    try {
      const data = await api.listCards(customerId);
      setCards(Array.isArray(data) ? data : data.cards || []);
    } catch (err) {
      console.error('Failed to load cards:', err);
      setCards([]);
    } finally {
      setLoading(false);
    }
  };

  const handleFilter = () => {
    loadCards(filterCustomerId || undefined);
  };

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="mb-6">
        <Link href="/dashboard" className="text-blue-600 hover:underline">
          ← Back to Dashboard
        </Link>
      </div>

      <h1 className="text-3xl font-bold mb-6">Virtual Cards Overview</h1>

      {/* Filters */}
      <div className="bg-white p-6 rounded-lg shadow mb-6">
        <div className="flex gap-4">
          <div className="flex-1">
            <label className="block text-sm font-medium mb-2">Filter by Customer ID</label>
            <input
              type="text"
              value={filterCustomerId}
              onChange={(e) => setFilterCustomerId(e.target.value)}
              placeholder="cust_..."
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
          <div className="flex items-end">
            <button
              onClick={handleFilter}
              disabled={loading}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
            >
              {loading ? 'Loading...' : 'Filter'}
            </button>
          </div>
          {filterCustomerId && (
            <div className="flex items-end">
              <button
                onClick={() => {
                  setFilterCustomerId('');
                  loadCards();
                }}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400"
              >
                Clear
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Results */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 bg-gray-50 border-b">
          <h2 className="font-semibold">
            {cards.length} {cards.length === 1 ? 'card' : 'cards'} found
          </h2>
        </div>

        {loading ? (
          <div className="p-8 text-center">Loading...</div>
        ) : cards.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <p>No cards found</p>
            {filterCustomerId && (
              <p className="text-sm mt-2">Try adjusting your filter or clearing it</p>
            )}
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="text-left p-3 text-sm font-medium">Card ID</th>
                  <th className="text-left p-3 text-sm font-medium">Customer ID</th>
                  <th className="text-left p-3 text-sm font-medium">Last 4</th>
                  <th className="text-left p-3 text-sm font-medium">Currency</th>
                  <th className="text-left p-3 text-sm font-medium">Status</th>
                  <th className="text-left p-3 text-sm font-medium">Daily Limit</th>
                  <th className="text-left p-3 text-sm font-medium">Monthly Limit</th>
                  <th className="text-left p-3 text-sm font-medium">Created</th>
                </tr>
              </thead>
              <tbody>
                {cards.map((card) => (
                  <tr key={card.id} className="border-b hover:bg-gray-50">
                    <td className="p-3 font-mono text-xs">{card.id}</td>
                    <td className="p-3 font-mono text-xs">
                      <Link
                        href={`/dashboard/customer360?customerId=${card.customerId}`}
                        className="text-blue-600 hover:underline"
                      >
                        {card.customerId}
                      </Link>
                    </td>
                    <td className="p-3 font-mono font-bold">•••• {card.last4}</td>
                    <td className="p-3 text-sm">{card.currency}</td>
                    <td className="p-3">
                      <span
                        className={`px-2 py-1 rounded text-xs font-medium ${
                          card.status === 'ACTIVE'
                            ? 'bg-green-100 text-green-800'
                            : card.status === 'FROZEN'
                            ? 'bg-orange-100 text-orange-800'
                            : 'bg-red-100 text-red-800'
                        }`}
                      >
                        {card.status}
                      </span>
                    </td>
                    <td className="p-3 text-sm">
                      {card.currency} {(parseInt(card.dailyLimitMinor) / 100).toFixed(2)}
                    </td>
                    <td className="p-3 text-sm">
                      {card.currency} {(parseInt(card.monthlyLimitMinor) / 100).toFixed(2)}
                    </td>
                    <td className="p-3 text-sm text-gray-600">
                      {new Date(card.createdAt).toLocaleDateString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Summary Stats */}
      {!loading && cards.length > 0 && (
        <div className="mt-6 grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-white p-6 rounded-lg shadow">
            <div className="text-sm text-gray-600">Active Cards</div>
            <div className="text-3xl font-bold text-green-600 mt-2">
              {cards.filter((c) => c.status === 'ACTIVE').length}
            </div>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <div className="text-sm text-gray-600">Frozen Cards</div>
            <div className="text-3xl font-bold text-orange-600 mt-2">
              {cards.filter((c) => c.status === 'FROZEN').length}
            </div>
          </div>
          <div className="bg-white p-6 rounded-lg shadow">
            <div className="text-sm text-gray-600">Blocked Cards</div>
            <div className="text-3xl font-bold text-red-600 mt-2">
              {cards.filter((c) => c.status === 'BLOCKED').length}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
