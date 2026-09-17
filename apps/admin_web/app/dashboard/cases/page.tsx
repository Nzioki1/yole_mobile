'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';

export default function CasesPage() {
  const [cases, setCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('');
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [formData, setFormData] = useState({
    type: 'DISPUTE',
    description: '',
    customerId: '',
  });
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    loadCases();
  }, []);

  const loadCases = async (status?: string) => {
    setLoading(true);
    try {
      const data = await api.listCases(status);
      setCases(Array.isArray(data) ? data : data.cases || []);
    } catch (err) {
      console.error('Failed to load cases:', err);
      setCases([]);
    } finally {
      setLoading(false);
    }
  };

  const handleFilter = () => {
    loadCases(filterStatus || undefined);
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.type || !formData.description) {
      alert('Please fill in all required fields');
      return;
    }

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
    if (!confirm(`Are you sure you want to set this case status to "${decision}"?`)) {
      return;
    }

    try {
      await api.updateCase(caseId, decision);
      await loadCases(filterStatus || undefined);
    } catch (err: any) {
      alert(`Failed to update case: ${err.message}`);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <div className="mb-6">
        <Link href="/dashboard" className="text-blue-600 hover:underline">
          ← Back to Dashboard
        </Link>
      </div>

      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Cases & Support</h1>
        <button
          onClick={() => setShowCreateForm(!showCreateForm)}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          {showCreateForm ? 'Cancel' : '+ Create Case'}
        </button>
      </div>

      {/* Create Form */}
      {showCreateForm && (
        <div className="bg-white p-6 rounded-lg shadow mb-6">
          <h2 className="text-xl font-bold mb-4">Create New Case</h2>
          <form onSubmit={handleCreate}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-2">Type</label>
                <select
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                  className="w-full px-3 py-2 border rounded-lg"
                  required
                >
                  <option value="DISPUTE">Dispute</option>
                  <option value="INQUIRY">Inquiry</option>
                  <option value="FRAUD">Fraud</option>
                  <option value="OTHER">Other</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Customer ID (Optional)</label>
                <input
                  type="text"
                  value={formData.customerId}
                  onChange={(e) => setFormData({ ...formData, customerId: e.target.value })}
                  placeholder="cust_..."
                  className="w-full px-3 py-2 border rounded-lg"
                />
              </div>
            </div>
            <div className="mt-4">
              <label className="block text-sm font-medium mb-2">Description</label>
              <textarea
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Describe the case..."
                rows={4}
                required
                className="w-full px-3 py-2 border rounded-lg"
              />
            </div>
            <div className="mt-4">
              <button
                type="submit"
                disabled={creating}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
              >
                {creating ? 'Creating...' : 'Create Case'}
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Filter */}
      <div className="bg-white p-6 rounded-lg shadow mb-6">
        <div className="flex gap-4">
          <div className="flex-1">
            <label className="block text-sm font-medium mb-2">Filter by Status</label>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="w-full px-3 py-2 border rounded-lg"
            >
              <option value="">All</option>
              <option value="PENDING">Pending</option>
              <option value="IN_PROGRESS">In Progress</option>
              <option value="RESOLVED">Resolved</option>
              <option value="CLOSED">Closed</option>
            </select>
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
          {filterStatus && (
            <div className="flex items-end">
              <button
                onClick={() => {
                  setFilterStatus('');
                  loadCases();
                }}
                className="px-4 py-2 bg-gray-300 text-gray-700 rounded-lg hover:bg-gray-400"
              >
                Clear
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Cases List */}
      <div className="bg-white rounded-lg shadow">
        <div className="p-4 bg-gray-50 border-b">
          <h2 className="font-semibold">
            {cases.length} {cases.length === 1 ? 'case' : 'cases'} found
          </h2>
        </div>

        {loading ? (
          <div className="p-8 text-center">Loading...</div>
        ) : cases.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <p>No cases found</p>
            {filterStatus && (
              <p className="text-sm mt-2">Try adjusting your filter or clearing it</p>
            )}
          </div>
        ) : (
          <div className="divide-y">
            {cases.map((caseItem) => (
              <div key={caseItem.id} className="p-6 hover:bg-gray-50">
                <div className="flex justify-between items-start">
                  <div className="flex-1">
                    <div className="flex items-center gap-3 mb-2">
                      <span className="text-lg font-bold">{caseItem.type}</span>
                      <span
                        className={`px-2 py-1 rounded text-xs font-medium ${
                          caseItem.status === 'RESOLVED' || caseItem.status === 'CLOSED'
                            ? 'bg-green-100 text-green-800'
                            : caseItem.status === 'IN_PROGRESS'
                            ? 'bg-blue-100 text-blue-800'
                            : 'bg-yellow-100 text-yellow-800'
                        }`}
                      >
                        {caseItem.status}
                      </span>
                    </div>
                    <p className="text-sm text-gray-700 mb-2">{caseItem.description}</p>
                    <div className="flex gap-4 text-xs text-gray-500">
                      <span>ID: {caseItem.id}</span>
                      {caseItem.customerId && (
                        <span>
                          Customer:{' '}
                          <Link
                            href={`/dashboard/customer360?customerId=${caseItem.customerId}`}
                            className="text-blue-600 hover:underline"
                          >
                            {caseItem.customerId}
                          </Link>
                        </span>
                      )}
                      <span>Created: {new Date(caseItem.createdAt).toLocaleString()}</span>
                      {caseItem.decidedAt && (
                        <span>Decided: {new Date(caseItem.decidedAt).toLocaleString()}</span>
                      )}
                    </div>
                  </div>
                  {caseItem.status === 'PENDING' && (
                    <div className="flex gap-2 ml-4">
                      <button
                        onClick={() => handleDecision(caseItem.id, 'IN_PROGRESS')}
                        className="px-3 py-1 bg-blue-600 text-white text-sm rounded hover:bg-blue-700"
                      >
                        In Progress
                      </button>
                      <button
                        onClick={() => handleDecision(caseItem.id, 'RESOLVED')}
                        className="px-3 py-1 bg-green-600 text-white text-sm rounded hover:bg-green-700"
                      >
                        Resolve
                      </button>
                      <button
                        onClick={() => handleDecision(caseItem.id, 'CLOSED')}
                        className="px-3 py-1 bg-gray-600 text-white text-sm rounded hover:bg-gray-700"
                      >
                        Close
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
