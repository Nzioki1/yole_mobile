'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function KycQueuePage() {
  const [submissions, setSubmissions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadSubmissions();
  }, []);

  const loadSubmissions = async () => {
    setLoading(true);
    try {
      const data = await api.listKycSubmissions('PENDING_REVIEW');
      setSubmissions(Array.isArray(data) ? data : data?.submissions || []);
    } catch (error) {
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  const handleDecision = async (id: string, decision: 'APPROVE' | 'REJECT') => {
    try {
      await api.makeKycDecision(id, decision, 'Admin decision');
      loadSubmissions();
    } catch (error) {
      alert(`Error: ${error}`);
    }
  };

  return (
    <div>
      <div className="row mb-3">
        <div className="col-md-4">
          <div className="widget widget-stats bg-orange">
            <div className="stats-icon">
              <i className="fa fa-id-card"></i>
            </div>
            <div className="stats-info">
              <h4>PENDING REVIEW</h4>
              <p>{submissions.length}</p>
            </div>
          </div>
        </div>
      </div>

      <Panel>
        <PanelHeader>Pending KYC Reviews</PanelHeader>
        <PanelBody className="p-0">
          {loading ? (
            <div className="p-4 text-center fw-semibold">Loading...</div>
          ) : submissions.length === 0 ? (
            <div className="p-4 text-center text-gray-500">No pending KYC submissions</div>
          ) : (
            <div className="table-responsive">
              <table className="table table-striped table-hover mb-0 align-middle">
                <thead>
                  <tr>
                    <th>Submission ID</th>
                    <th>Customer</th>
                    <th>ID Number</th>
                    <th>Phone</th>
                    <th>Status</th>
                    <th className="text-end">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {submissions.map((sub) => (
                    <tr key={sub.id}>
                      <td className="fw-bold font-monospace">{sub.id}</td>
                      <td className="fw-semibold">{sub.customerId}</td>
                      <td>{sub.idNumber}</td>
                      <td>{sub.phoneE164}</td>
                      <td>
                        <span className="badge bg-warning">{sub.status}</span>
                      </td>
                      <td className="text-end">
                        <button
                          className="btn btn-success btn-sm me-2"
                          onClick={() => handleDecision(sub.id, 'APPROVE')}
                        >
                          Approve
                        </button>
                        <button
                          className="btn btn-danger btn-sm"
                          onClick={() => handleDecision(sub.id, 'REJECT')}
                        >
                          Reject
                        </button>
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
