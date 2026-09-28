'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService, StaffRole } from '../../../lib/auth';
import { OfflineDemoStore } from '../../../lib/offline/store';

type AuditLog = {
  id: string;
  userId: string;
  userEmail: string;
  action: string;
  resourceType: string;
  resourceId: string;
  changes: any;
  timestamp: string;
};

export default function AuditLogPage() {
  const router = useRouter();
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const user = authService.getCurrentUser();
    if (!user || user.role !== StaffRole.ADMIN) {
      router.push('/login');
      return;
    }

    const store = OfflineDemoStore.createFresh();
    const auditLogs = store.listAuditLogs();
    setLogs(auditLogs);
    setLoading(false);
  }, [router]);

  if (loading) {
    return <div className="p-6">Loading...</div>;
  }

  return (
    <div className="p-6">
      <h1 className="text-2xl font-bold mb-6">Audit Log</h1>

      <div className="mb-4 p-4 bg-yellow-50 border border-yellow-200 rounded">
        <p className="text-sm text-yellow-800">
          <strong>Audit Trail:</strong> All system actions are logged with maker and approver details. Offline demo shows sample audit entries.
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="min-w-full bg-white border">
          <thead>
            <tr className="bg-gray-100">
              <th className="px-4 py-2 border text-left">Timestamp</th>
              <th className="px-4 py-2 border text-left">User</th>
              <th className="px-4 py-2 border text-left">Action</th>
              <th className="px-4 py-2 border text-left">Resource Type</th>
              <th className="px-4 py-2 border text-left">Resource ID</th>
              <th className="px-4 py-2 border text-left">Changes</th>
            </tr>
          </thead>
          <tbody>
            {logs.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-4 py-8 text-center text-gray-500">
                  No audit logs yet
                </td>
              </tr>
            ) : (
              logs.map((log) => (
                <tr key={log.id} className="hover:bg-gray-50">
                  <td className="px-4 py-2 border">
                    {new Date(log.timestamp).toLocaleString()}
                  </td>
                  <td className="px-4 py-2 border">{log.userEmail}</td>
                  <td className="px-4 py-2 border">
                    <span className="px-2 py-1 bg-blue-100 text-blue-800 rounded text-xs font-mono">
                      {log.action}
                    </span>
                  </td>
                  <td className="px-4 py-2 border">{log.resourceType}</td>
                  <td className="px-4 py-2 border">
                    <span className="font-mono text-sm">{log.resourceId}</span>
                  </td>
                  <td className="px-4 py-2 border">
                    <pre className="text-xs">{JSON.stringify(log.changes, null, 2)}</pre>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
