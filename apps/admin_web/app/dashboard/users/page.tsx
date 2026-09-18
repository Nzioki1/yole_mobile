'use client';

import { FormEvent, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import { authService, StaffRole } from '@/lib/auth';
import { Panel, PanelHeader, PanelBody } from '@/components/panel/Panel';

const ROLES: StaffRole[] = [
  StaffRole.ADMIN,
  StaffRole.OPS,
  StaffRole.SUPPORT,
  StaffRole.FINANCE,
];

type StaffRow = {
  id: string;
  email: string;
  role: string;
  firstName?: string;
  lastName?: string;
};

export default function UsersPage() {
  const router = useRouter();
  const [currentUser, setCurrentUser] = useState<ReturnType<typeof authService.getCurrentUser>>(null);
  const [staff, setStaff] = useState<StaffRow[]>([]);
  const [showForm, setShowForm] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    password: 'Password1!',
    role: StaffRole.OPS as string,
  });

  const isAdmin = currentUser?.role === StaffRole.ADMIN;

  useEffect(() => {
    const user = authService.getCurrentUser();
    if (!user) {
      router.replace('/login');
      return;
    }
    setCurrentUser(user);
    loadStaff();
  }, [router]);

  const loadStaff = async () => {
    try {
      const data = await api.listStaff();
      setStaff(Array.isArray(data) ? data : []);
      setError(null);
    } catch (e) {
      setError(String(e));
    }
  };

  const handleCreate = async (e: FormEvent) => {
    e.preventDefault();
    try {
      await api.createStaff(formData);
      setShowForm(false);
      setFormData({
        firstName: '',
        lastName: '',
        email: '',
        password: 'Password1!',
        role: StaffRole.OPS,
      });
      await loadStaff();
    } catch (err) {
      setError(String(err));
    }
  };

  const handleRoleChange = async (staffId: string, role: string) => {
    try {
      await api.updateStaffRole(staffId, role);
      await loadStaff();
    } catch (err) {
      setError(String(err));
      await loadStaff();
    }
  };

  return (
    <div>
      <p className="text-muted small mb-3">
        Offline demo staff. Role changes apply to login on next sign-in.
        Cannot demote the last ADMIN. Reset demo restores seed users.
      </p>
      {error && (
        <div className="alert alert-danger py-2" role="alert">
          {error}
        </div>
      )}
      {!isAdmin && (
        <p className="text-muted small mb-3">
          View only — ask an ADMIN to create users or change roles.
        </p>
      )}
      {isAdmin && (
        <div className="mb-3">
          <button className="btn btn-theme" type="button" onClick={() => setShowForm(!showForm)}>
            {showForm ? 'Cancel' : '+ Create staff'}
          </button>
        </div>
      )}

      {showForm && (
        <Panel>
          <PanelHeader>Create staff</PanelHeader>
          <PanelBody>
            <form onSubmit={handleCreate} className="row g-3">
              <div className="col-md-6">
                <input
                  className="form-control"
                  placeholder="First name"
                  value={formData.firstName}
                  onChange={(e) => setFormData({ ...formData, firstName: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <input
                  className="form-control"
                  placeholder="Last name"
                  value={formData.lastName}
                  onChange={(e) => setFormData({ ...formData, lastName: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <input
                  className="form-control"
                  type="email"
                  placeholder="Email"
                  value={formData.email}
                  onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <input
                  className="form-control"
                  type="text"
                  placeholder="Password"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  required
                />
              </div>
              <div className="col-md-6">
                <select
                  className="form-select"
                  value={formData.role}
                  onChange={(e) => setFormData({ ...formData, role: e.target.value })}
                >
                  {ROLES.map((r) => (
                    <option key={r} value={r}>
                      {r}
                    </option>
                  ))}
                </select>
              </div>
              <div className="col-12">
                <button type="submit" className="btn btn-success">
                  Create staff
                </button>
              </div>
            </form>
          </PanelBody>
        </Panel>
      )}

      <Panel>
        <PanelHeader>{staff.length} Staff</PanelHeader>
        <PanelBody className="p-0">
          <div className="table-responsive">
            <table className="table table-striped table-hover mb-0 align-middle">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>ID</th>
                </tr>
              </thead>
              <tbody>
                {staff.map((row) => (
                  <tr key={row.id}>
                    <td className="fw-semibold">
                      {row.firstName} {row.lastName}
                    </td>
                    <td>{row.email}</td>
                    <td style={{ minWidth: 140 }}>
                      {isAdmin ? (
                        <select
                          className="form-select form-select-sm"
                          value={row.role}
                          onChange={(e) => handleRoleChange(row.id, e.target.value)}
                        >
                          {ROLES.map((r) => (
                            <option key={r} value={r}>
                              {r}
                            </option>
                          ))}
                        </select>
                      ) : (
                        <span className="badge bg-secondary">{row.role}</span>
                      )}
                    </td>
                    <td className="font-monospace small">{row.id}</td>
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
