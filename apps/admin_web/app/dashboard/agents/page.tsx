'use client';

import { useEffect, useState, FormEvent } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

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
      setAgents(Array.isArray(data) ? data : data?.agents || []);
    } catch (error) {
      console.error(error);
    }
  };

  const handleSubmit = async (e: FormEvent) => {
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
      <div className="mb-3">
        <button className="btn btn-theme" onClick={() => setShowForm(!showForm)}>
          {showForm ? 'Cancel' : '+ Enroll Agent'}
        </button>
      </div>

      {showForm && (
        <Panel>
          <PanelHeader>Enroll New Agent</PanelHeader>
          <PanelBody>
            <form onSubmit={handleSubmit} className="row g-3">
              <div className="col-md-6">
                <input className="form-control" placeholder="First Name" value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })} required />
              </div>
              <div className="col-md-6">
                <input className="form-control" placeholder="Last Name" value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })} required />
              </div>
              <div className="col-md-6">
                <input className="form-control" placeholder="Phone (+243...)" value={formData.phoneE164}
                  onChange={(e) => setFormData({ ...formData, phoneE164: e.target.value })} required />
              </div>
              <div className="col-md-6">
                <input className="form-control" type="email" placeholder="Email" value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })} />
              </div>
              <div className="col-12">
                <button type="submit" className="btn btn-success">Enroll Agent</button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      <Panel>
        <PanelHeader>{agents.length} Agents</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped table-hover mb-0 align-middle">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>ID</th>
                  <th>Phone</th>
                  <th>Float Wallet</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {agents.map((agent) => (
                  <tr key={agent.id}>
                    <td className="fw-semibold">{agent.firstName} {agent.lastName}</td>
                    <td className="font-monospace small">{agent.id}</td>
                    <td>{agent.phoneE164}</td>
                    <td className="font-monospace small">{agent.floatWalletId}</td>
                    <td>
                      <span className={`badge ${agent.status === 'ACTIVE' ? 'bg-teal' : 'bg-warning'}`}>
                        {agent.status}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </PanelBody>
      </Panel>
    </div>
  );
}
