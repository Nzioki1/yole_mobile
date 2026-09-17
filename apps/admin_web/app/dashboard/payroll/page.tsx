'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';

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
      console.error('Failed to load employers:', err);
      setEmployers([]);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.name || !formData.taxId) return;

    setCreating(true);
    try {
      await api.createEmployer(formData);
      setFormData({ name: '', taxId: '' });
      setShowCreateForm(false);
      await loadEmployers();
    } catch (err: any) {
      alert(`Failed to create employer: ${err.message}`);
    } finally {
      setCreating(false);
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
        <h1 className="text-3xl font-bold">Payroll Management</h1>
        <button
          onClick={() => setShowCreateForm(!showCreateForm)}
          className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          {showCreateForm ? 'Cancel' : '+ Create Employer'}
        </button>
      </div>

      {showCreateForm && (
        <div className="bg-white p-6 rounded-lg shadow mb-6">
          <h2 className="text-xl font-bold mb-4">Create New Employer</h2>
          <form onSubmit={handleCreate}>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium mb-2">Company Name</label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                  placeholder="ACME Corp"
                  required
                  className="w-full px-3 py-2 border rounded-lg"
                />
              </div>
              <div>
                <label className="block text-sm font-medium mb-2">Tax ID</label>
                <input
                  type="text"
                  value={formData.taxId}
                  onChange={(e) => setFormData({ ...formData, taxId: e.target.value })}
                  placeholder="TAX12345"
                  required
                  className="w-full px-3 py-2 border rounded-lg"
                />
              </div>
            </div>
            <div className="mt-4">
              <button
                type="submit"
                disabled={creating}
                className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400"
              >
                {creating ? 'Creating...' : 'Create Employer'}
              </button>
            </div>
          </form>
        </div>
      )}

      <div className="bg-white rounded-lg shadow">
        <div className="p-4 bg-gray-50 border-b">
          <h2 className="font-semibold">
            {employers.length} {employers.length === 1 ? 'Employer' : 'Employers'}
          </h2>
        </div>

        {loading ? (
          <div className="p-8 text-center">Loading...</div>
        ) : employers.length === 0 ? (
          <div className="p-8 text-center text-gray-500">
            <p>No employers found</p>
            <p className="text-sm mt-2">Create your first employer to get started</p>
          </div>
        ) : (
          <div className="divide-y">
            {employers.map((employer) => (
              <Link
                key={employer.id}
                href={`/dashboard/payroll/${employer.id}`}
                className="block p-6 hover:bg-gray-50 transition"
              >
                <div className="flex justify-between items-start">
                  <div>
                    <h3 className="text-lg font-bold">{employer.name}</h3>
                    <p className="text-sm text-gray-600 mt-1">Tax ID: {employer.taxId}</p>
                    <p className="text-sm text-gray-500 mt-1">
                      {employer.employeeCount || 0} employees
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-sm text-gray-600">Created</p>
                    <p className="text-sm font-mono">
                      {new Date(employer.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
