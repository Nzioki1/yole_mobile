'use client';

import { useState } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';

export default function Customer360Page() {
  const [customerId, setCustomerId] = useState('');
  const [customer, setCustomer] = useState<any>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSearch = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!customerId) return;

    setLoading(true);
    setError('');
    setCustomer(null);

    try {
      const data = await api.getCustomer360(customerId);
      setCustomer(data);
    } catch (err: any) {
      setError(err.message || 'Failed to load customer');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="mb-6">
        <Link href="/dashboard" className="text-blue-600 hover:underline">
          ← Back to Dashboard
        </Link>
      </div>

      <h1 className="text-3xl font-bold mb-6">Customer 360</h1>

      <form onSubmit={handleSearch} className="bg-white p-6 rounded-lg shadow mb-6">
        <div className="flex gap-4">
          <input
            type="text"
            value={customerId}
            onChange={(e) => setCustomerId(e.target.value)}
            placeholder="Enter Customer ID"
            className="flex-1 px-4 py-2 border rounded-lg"
          />
          <button
            type="submit"
            disabled={loading}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
          >
            {loading ? 'Loading...' : 'Search'}
          </button>
        </div>
        {error && (
          <div className="mt-4 p-3 bg-red-100 text-red-700 rounded">{error}</div>
        )}
      </form>

      {customer && (
        <div className="space-y-6">
          {/* Customer Info */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Customer Information</h2>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="text-sm text-gray-600">Customer ID</label>
                <p className="font-mono">{customer.customer.id}</p>
              </div>
              <div>
                <label className="text-sm text-gray-600">Name</label>
                <p>{customer.customer.firstName} {customer.customer.lastName}</p>
              </div>
              <div>
                <label className="text-sm text-gray-600">Email</label>
                <p>{customer.customer.email || 'N/A'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-600">Phone</label>
                <p>{customer.customer.phoneE164 || 'N/A'}</p>
              </div>
              <div>
                <label className="text-sm text-gray-600">Created</label>
                <p>{new Date(customer.customer.createdAt).toLocaleString()}</p>
              </div>
              <div>
                <label className="text-sm text-gray-600">KYC Status</label>
                <span className={`px-2 py-1 rounded text-sm ${
                  customer.customer.kycStatus === 'APPROVED' ? 'bg-green-100 text-green-800' :
                  customer.customer.kycStatus === 'PENDING' ? 'bg-yellow-100 text-yellow-800' :
                  'bg-gray-100 text-gray-800'
                }`}>
                  {customer.customer.kycStatus}
                </span>
              </div>
            </div>
          </div>

          {/* Wallets */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Wallets & Balances</h2>
            {customer.wallets?.map((wallet: any) => (
              <div key={wallet.id} className="mb-4">
                <h3 className="font-semibold text-sm text-gray-600 mb-2">Wallet: {wallet.id}</h3>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {wallet.pockets?.map((pocket: any) => (
                    <div key={pocket.id} className="border rounded p-3">
                      <div className="text-lg font-bold">{pocket.currency}</div>
                      <div className="text-sm text-gray-600">Available</div>
                      <div className="font-mono">{(parseInt(pocket.availableMinor) / 100).toFixed(2)}</div>
                      <div className="text-xs text-gray-500 mt-1">
                        Ledger: {(parseInt(pocket.ledgerMinor) / 100).toFixed(2)}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>

          {/* Recent Payments */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Recent Payments</h2>
            {customer.recentPayments && customer.recentPayments.length > 0 ? (
              <table className="w-full">
                <thead>
                  <tr className="border-b">
                    <th className="text-left p-2">ID</th>
                    <th className="text-left p-2">Type</th>
                    <th className="text-left p-2">Amount</th>
                    <th className="text-left p-2">Status</th>
                    <th className="text-left p-2">Date</th>
                  </tr>
                </thead>
                <tbody>
                  {customer.recentPayments.map((payment: any) => (
                    <tr key={payment.id} className="border-b hover:bg-gray-50">
                      <td className="p-2 font-mono text-sm">{payment.id}</td>
                      <td className="p-2">{payment.type}</td>
                      <td className="p-2">{payment.currency} {(parseInt(payment.amountMinor) / 100).toFixed(2)}</td>
                      <td className="p-2">
                        <span className={`px-2 py-1 rounded text-xs ${
                          payment.status === 'POSTED' ? 'bg-green-100 text-green-800' :
                          payment.status === 'FAILED' ? 'bg-red-100 text-red-800' :
                          'bg-yellow-100 text-yellow-800'
                        }`}>
                          {payment.status}
                        </span>
                      </td>
                      <td className="p-2 text-sm">{new Date(payment.createdAt).toLocaleDateString()}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="text-gray-500">No recent payments</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
