'use client';

import { useState, useEffect } from 'react';
import { api } from '@/lib/api';

export default function PaymentsSearchPage() {
  const [payments, setPayments] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({
    customerId: '',
    status: '',
    type: '',
  });

  const handleSearch = async () => {
    setLoading(true);
    try {
      const activeFilters = Object.fromEntries(
        Object.entries(filters).filter(([_, v]) => v !== '')
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
      {/* Filters */}
      <div className="bg-white p-6 rounded-lg shadow mb-6">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <div>
            <label className="block text-sm font-medium mb-2">Customer ID</label>
            <input
              type="text"
              value={filters.customerId}
              onChange={(e) => setFilters({ ...filters, customerId: e.target.value })}
              placeholder="cust_..."
              className="w-full px-3 py-2 border rounded-lg"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Status</label>
            <select
              value={filters.status}
              onChange={(e) => setFilters({ ...filters, status: e.target.value })}
              className="w-full px-3 py-2 border rounded-lg"
            >
              <option value="">All</option>
              <option value="QUOTED">Quoted</option>
              <option value="CONFIRMED">Confirmed</option>
              <option value="PENDING">Pending</option>
              <option value="POSTED">Posted</option>
              <option value="FAILED">Failed</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">Type</label>
            <select
              value={filters.type}
              onChange={(e) => setFilters({ ...filters, type: e.target.value })}
              className="w-full px-3 py-2 border rounded-lg"
            >
              <option value="">All</option>
              <option value="W2W">Wallet to Wallet</option>
              <option value="MNO_IN">Mobile Money In</option>
              <option value="MNO_OUT">Mobile Money Out</option>
              <option value="BANK_IN">Bank In</option>
              <option value="BANK_OUT">Bank Out</option>
              <option value="BILL_PAY">Bill Payment</option>
              <option value="AIRTIME">Airtime</option>
            </select>
          </div>
          <div className="flex items-end">
            <button
              onClick={handleSearch}
              disabled={loading}
              className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
            >
              {loading ? 'Searching...' : 'Search'}
            </button>
          </div>
        </div>
      </div>

      {/* Results */}
      <div className="bg-white rounded-lg shadow overflow-hidden">
        <div className="p-4 bg-gray-50 border-b">
          <h2 className="font-semibold">
            {payments.length} {payments.length === 1 ? 'payment' : 'payments'} found
          </h2>
        </div>
        
        {loading ? (
          <div className="p-8 text-center">Loading...</div>
        ) : payments.length === 0 ? (
          <div className="p-8 text-center text-gray-500">No payments found</div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 border-b">
                <tr>
                  <th className="text-left p-3 text-sm font-medium">ID</th>
                  <th className="text-left p-3 text-sm font-medium">Customer</th>
                  <th className="text-left p-3 text-sm font-medium">Type</th>
                  <th className="text-left p-3 text-sm font-medium">Amount</th>
                  <th className="text-left p-3 text-sm font-medium">Status</th>
                  <th className="text-left p-3 text-sm font-medium">Created</th>
                </tr>
              </thead>
              <tbody>
                {payments.map((payment) => (
                  <tr key={payment.id} className="border-b hover:bg-gray-50">
                    <td className="p-3 font-mono text-xs">{payment.id}</td>
                    <td className="p-3 font-mono text-xs">{payment.customerId}</td>
                    <td className="p-3 text-sm">{payment.type}</td>
                    <td className="p-3 text-sm">
                      {payment.currency} {(parseInt(payment.amountMinor) / 100).toFixed(2)}
                    </td>
                    <td className="p-3">
                      <span className={`px-2 py-1 rounded text-xs font-medium ${
                        payment.status === 'POSTED' ? 'bg-green-100 text-green-800' :
                        payment.status === 'FAILED' ? 'bg-red-100 text-red-800' :
                        payment.status === 'PENDING' ? 'bg-yellow-100 text-yellow-800' :
                        'bg-blue-100 text-blue-800'
                      }`}>
                        {payment.status}
                      </span>
                    </td>
                    <td className="p-3 text-sm text-gray-600">
                      {new Date(payment.createdAt).toLocaleString()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
