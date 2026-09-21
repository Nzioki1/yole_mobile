'use client';

import { useEffect, useState, FormEvent } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

interface AmlBanEntry {
  id: string;
  fullName: string;
  idRef?: string;
  matchType: 'NAME' | 'ID' | 'ENTITY';
  reason: string;
  sourceList: string;
  status: 'BANNED' | 'LIFTED';
  notes?: string;
  createdAt: string;
}

export default function AmlBanListPage() {
  const [entries, setEntries] = useState<AmlBanEntry[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [formData, setFormData] = useState({
    fullName: '',
    idRef: '',
    matchType: 'NAME' as 'NAME' | 'ID' | 'ENTITY',
    reason: '',
    sourceList: 'DEMO_SANCTIONS',
  });

  useEffect(() => {
    loadEntries();
  }, []);

  const loadEntries = async () => {
    try {
      const data = await api.listAmlBanList();
      setEntries(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error(error);
    }
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    try {
      await api.addAmlBanEntry({
        fullName: formData.fullName,
        idRef: formData.idRef || undefined,
        matchType: formData.matchType,
        reason: formData.reason,
        sourceList: formData.sourceList,
      });
      setShowForm(false);
      setFormData({ 
        fullName: '', 
        idRef: '', 
        matchType: 'NAME', 
        reason: '', 
        sourceList: 'DEMO_SANCTIONS' 
      });
      loadEntries();
    } catch (error) {
      alert(`Error: ${error}`);
    }
  };

  const handleLift = async (id: string) => {
    try {
      await api.liftAmlBanEntry(id);
      loadEntries();
    } catch (error) {
      alert(`Error: ${error}`);
    }
  };

  return (
    <div>
      <div className="alert alert-warning mb-3">
        <i className="fa fa-info-circle me-2"></i>
        Offline demo — not a live sanctions feed
      </div>

      <div className="mb-3">
        <button className="btn btn-theme" onClick={() => setShowForm(!showForm)}>
          {showForm ? 'Cancel' : '+ Add to ban list'}
        </button>
      </div>

      {showForm && (
        <Panel>
          <PanelHeader>Add AML Ban Entry</PanelHeader>
          <PanelBody>
            <form onSubmit={handleSubmit} className="row g-3">
              <div className="col-md-6">
                <label className="form-label">Full Name</label>
                <input 
                  className="form-control" 
                  placeholder="Full Name" 
                  value={formData.fullName}
                  onChange={(e) => setFormData({ ...formData, fullName: e.target.value })} 
                  required 
                />
              </div>
              <div className="col-md-6">
                <label className="form-label">ID/Reference (optional)</label>
                <input 
                  className="form-control" 
                  placeholder="ID or Reference" 
                  value={formData.idRef}
                  onChange={(e) => setFormData({ ...formData, idRef: e.target.value })} 
                />
              </div>
              <div className="col-md-6">
                <label className="form-label">Match Type</label>
                <select 
                  className="form-select" 
                  value={formData.matchType}
                  onChange={(e) => setFormData({ ...formData, matchType: e.target.value as 'NAME' | 'ID' | 'ENTITY' })}
                  required
                >
                  <option value="NAME">NAME</option>
                  <option value="ID">ID</option>
                  <option value="ENTITY">ENTITY</option>
                </select>
              </div>
              <div className="col-md-6">
                <label className="form-label">Source List</label>
                <input 
                  className="form-control" 
                  placeholder="Source List" 
                  value={formData.sourceList}
                  onChange={(e) => setFormData({ ...formData, sourceList: e.target.value })} 
                  required 
                />
              </div>
              <div className="col-12">
                <label className="form-label">Reason</label>
                <textarea 
                  className="form-control" 
                  placeholder="Reason for ban" 
                  value={formData.reason}
                  onChange={(e) => setFormData({ ...formData, reason: e.target.value })} 
                  rows={3}
                  required 
                />
              </div>
              <div className="col-12">
                <button type="submit" className="btn btn-success">Add Entry</button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      <Panel>
        <PanelHeader>{entries.length} AML Ban List Entries</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped table-hover mb-0 align-middle">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>ID/Ref</th>
                  <th>Match</th>
                  <th>Reason</th>
                  <th>Source</th>
                  <th>Status</th>
                  <th>Added</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {entries.map((entry) => (
                  <tr key={entry.id}>
                    <td className="fw-semibold">{entry.fullName}</td>
                    <td className="font-monospace small">{entry.idRef || '—'}</td>
                    <td><span className="badge bg-secondary">{entry.matchType}</span></td>
                    <td className="text-truncate" style={{ maxWidth: '200px' }}>{entry.reason}</td>
                    <td className="small">{entry.sourceList}</td>
                    <td>
                      <span className={`badge ${entry.status === 'BANNED' ? 'bg-danger' : 'bg-secondary'}`}>
                        {entry.status}
                      </span>
                    </td>
                    <td className="small">{new Date(entry.createdAt).toLocaleDateString()}</td>
                    <td>
                      {entry.status === 'BANNED' && (
                        <button 
                          className="btn btn-sm btn-outline-success"
                          onClick={() => handleLift(entry.id)}
                        >
                          Lift
                        </button>
                      )}
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
