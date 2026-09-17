'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

export default function AgentsPage() {
  const [agents, setAgents] = useState<any[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    phoneE164: '',
    email: '',
  });

  useEffect(() => {
    loadAgents();
  }, []);

  const loadAgents = async () => {
    try {
      const data = await api.listAgents();
      setAgents(data);
    } catch (error) {
      console.error(error);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      await api.enrollAgent(formData);
      setShowForm(false);
      setFormData({ firstName: '', lastName: '', phoneE164: '', email: '' });
      loadAgents();
    } catch (error) {
      alert(`Error: ${error}`);
    }
  };

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <button
          onClick={() => setShowForm(!showForm)}
          className="bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
        >
          {showForm ? 'Cancel' : '+ Enroll Agent'}
        </button>
      </div>

      {showForm && (
        <div className="bg-white p-6 rounded-lg shadow mb-8">
          <h2 className="text-xl font-bold mb-4">Enroll New Agent</h2>
          <form onSubmit={handleSubmit} className="space-y-4">
            <input
              type="text"
              placeholder="First Name"
              value={formData.firstName}
              onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
              className="w-full px-3 py-2 border rounded"
              required
            />
            <input
              type="text"
              placeholder="Last Name"
              value={formData.lastName}
              onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
              className="w-full px-3 py-2 border rounded"
              required
            />
            <input
              type="text"
              placeholder="Phone (+243...)"
              value={formData.phoneE164}
              onChange={(e) => setFormData({ ...formData, phoneE164: e.target.value })}
              className="w-full px-3 py-2 border rounded"
              required
            />
            <input
              type="email"
              placeholder="Email"
              value={formData.email}
              onChange={(e) => setFormData({ ...formData, email: e.target.value })}
              className="w-full px-3 py-2 border rounded"
            />
            <button type="submit" className="bg-green-600 text-white px-6 py-2 rounded hover:bg-green-700">
              Enroll Agent
            </button>
          </form>
        </div>
      )}

      <div className="grid gap-4">
        {agents.map((agent) => (
          <div key={agent.id} className="bg-white p-6 rounded-lg shadow">
            <p className="font-semibold">{agent.firstName} {agent.lastName}</p>
            <p className="text-sm text-gray-600">ID: {agent.id}</p>
            <p className="text-sm text-gray-600">Phone: {agent.phoneE164}</p>
            <p className="text-sm text-gray-600">Float Wallet: {agent.floatWalletId}</p>
            <p className="text-sm text-gray-600">Status: {agent.status}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
