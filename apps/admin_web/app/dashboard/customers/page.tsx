'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api } from '@/lib/api';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

export default function CustomersPage() {
  const [customers, setCustomers] = useState<any[]>([]);

  useEffect(() => {
    loadCustomers();
  }, []);

  const loadCustomers = async () => {
    try {
      const data = await api.listCustomers();
      setCustomers(Array.isArray(data) ? data : []);
    } catch (error) {
      console.error(error);
    }
  };

  return (
    <div>
      <Panel>
        <PanelHeader>{customers.length} Customers</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped table-hover mb-0 align-middle">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Phone</th>
                  <th>Segment</th>
                  <th>KYC</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {customers.map((c) => (
                  <tr key={c.id}>
                    <td className="font-monospace small">{c.id}</td>
                    <td className="fw-semibold">
                      {c.firstName} {c.lastName}
                    </td>
                    <td>{c.email}</td>
                    <td>{c.phoneE164 || '—'}</td>
                    <td>
                      <span className="badge bg-info">{c.segment}</span>
                    </td>
                    <td>
                      <span
                        className={`badge ${
                          c.kycStatus === 'VERIFIED'
                            ? 'bg-success'
                            : c.kycStatus === 'PENDING'
                            ? 'bg-warning'
                            : 'bg-secondary'
                        }`}
                      >
                        {c.kycStatus}
                      </span>
                    </td>
                    <td>
                      <span
                        className={`badge ${
                          c.status === 'ACTIVE' ? 'bg-teal' : 'bg-secondary'
                        }`}
                      >
                        {c.status || 'ACTIVE'}
                      </span>
                    </td>
                    <td>
                      <Link
                        href={`/dashboard/customer360?customerId=${c.id}`}
                        className="btn btn-sm btn-theme"
                      >
                        Open 360
                      </Link>
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
