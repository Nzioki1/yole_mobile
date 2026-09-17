'use client';

import { useState } from 'react';
import { api } from '@/lib/api';

export default function ReconPage() {
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [summary, setSummary] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const loadSummary = async (date: string) => {
    setLoading(true);
    try {
      const data = await api.getDailySummary(date);
      setSummary(data);
    } catch (err) {
      console.error('Failed to load summary:', err);
      setSummary(null);
    } finally {
      setLoading(false);
    }
  };

  const handleDateChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const date = e.target.value;
    setSelectedDate(date);
    loadSummary(date);
  };

  return (
    <div>
      {/* Date Picker */}
      <div className="bg-white p-6 rounded-lg shadow mb-6">
        <label className="block text-sm font-medium mb-2">Select Date</label>
        <input
          type="date"
          value={selectedDate}
          onChange={handleDateChange}
          className="px-4 py-2 border rounded-lg"
        />
        <button
          onClick={() => loadSummary(selectedDate)}
          disabled={loading}
          className="ml-4 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
        >
          {loading ? 'Loading...' : 'Load Summary'}
        </button>
      </div>

      {/* Summary Display */}
      {loading ? (
        <div className="text-center py-8">Loading...</div>
      ) : summary ? (
        <div className="space-y-6">
          {/* Overview Cards */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-lg shadow">
              <div className="text-sm text-gray-600">Total Transactions</div>
              <div className="text-3xl font-bold text-blue-600 mt-2">
                {summary.totalTransactions || 0}
              </div>
            </div>
            <div className="bg-white p-6 rounded-lg shadow">
              <div className="text-sm text-gray-600">Total Volume</div>
              <div className="text-3xl font-bold text-green-600 mt-2">
                {summary.totalVolumeMinor
                  ? `${(parseInt(summary.totalVolumeMinor) / 100).toFixed(2)}`
                  : '0.00'}
              </div>
            </div>
            <div className="bg-white p-6 rounded-lg shadow">
              <div className="text-sm text-gray-600">Status</div>
              <div className="text-3xl font-bold text-purple-600 mt-2">
                {summary.status || 'N/A'}
              </div>
            </div>
          </div>

          {/* Details */}
          <div className="bg-white p-6 rounded-lg shadow">
            <h2 className="text-xl font-bold mb-4">Reconciliation Details</h2>
            <div className="space-y-4">
              {summary.details ? (
                <div className="prose">
                  <pre className="bg-gray-50 p-4 rounded overflow-x-auto text-sm">
                    {JSON.stringify(summary.details, null, 2)}
                  </pre>
                </div>
              ) : (
                <div className="text-center py-8 text-gray-500">
                  <p>No detailed reconciliation data available for this date</p>
                  <p className="text-sm mt-2">Daily reconciliation aggregates all transactions and ledger entries</p>
                </div>
              )}
            </div>
          </div>

          {/* Notes */}
          <div className="bg-blue-50 border border-blue-200 p-6 rounded-lg">
            <div className="flex">
              <div className="text-blue-600 text-xl mr-3">ℹ️</div>
              <div>
                <h3 className="font-semibold text-blue-900 mb-2">About Daily Reconciliation</h3>
                <p className="text-sm text-blue-800">
                  Daily reconciliation ensures all transactions, ledger entries, and wallet balances are consistent.
                  This process runs automatically each day and flags any discrepancies for manual review.
                </p>
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className="bg-white p-8 rounded-lg shadow text-center">
          <p className="text-gray-500">Select a date and click "Load Summary" to view reconciliation data</p>
        </div>
      )}
    </div>
  );
}
