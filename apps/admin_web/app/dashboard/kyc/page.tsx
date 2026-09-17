'use client';

import { useEffect, useState } from 'react';
import { mockApi as api } from '@/lib/mockApi';

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
      setSubmissions(data);
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
      {loading ? (
        <p>Loading...</p>
      ) : submissions.length === 0 ? (
        <p className="text-gray-600">No pending KYC submissions</p>
      ) : (
        <div className="space-y-4">
          {submissions.map((sub) => (
            <div key={sub.id} className="bg-white p-6 rounded-lg shadow">
              <div className="flex justify-between items-start">
                <div>
                  <p className="font-semibold">Submission ID: {sub.id}</p>
                  <p className="text-sm text-gray-600">Customer: {sub.customerId}</p>
                  <p className="text-sm text-gray-600">ID Number: {sub.idNumber}</p>
                  <p className="text-sm text-gray-600">Phone: {sub.phoneE164}</p>
                  <p className="text-sm text-gray-600">Status: {sub.status}</p>
                </div>
                <div className="space-x-2">
                  <button
                    onClick={() => handleDecision(sub.id, 'APPROVE')}
                    className="bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700"
                  >
                    Approve
                  </button>
                  <button
                    onClick={() => handleDecision(sub.id, 'REJECT')}
                    className="bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700"
                  >
                    Reject
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
