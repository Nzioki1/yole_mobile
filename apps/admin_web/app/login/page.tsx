'use client';

import { useEffect, useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { authService } from '@/lib/auth';
import { DEMO_SEED_ENABLED, mintDemoStaffToken } from '@/lib/demo-seed';
import { OFFLINE_DEMO } from '@/lib/offline/flags';
import { getOfflineStore } from '@/lib/offline/store';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

const LOGIN_BGS = [
  '/assets/img/login-bg/login-bg-17.jpg',
  '/assets/img/login-bg/login-bg-16.jpg',
  '/assets/img/login-bg/login-bg-15.jpg',
  '/assets/img/login-bg/login-bg-14.jpg',
  '/assets/img/login-bg/login-bg-13.jpg',
  '/assets/img/login-bg/login-bg-12.jpg',
];

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [activeBg, setActiveBg] = useState(LOGIN_BGS[0]);

  useEffect(() => {
    document.body.classList.add('bg-white');
    return () => {
      document.body.classList.remove('bg-white');
    };
  }, []);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      if (OFFLINE_DEMO) {
        const staff = getOfflineStore().authenticateStaff(email, password);
        if (!staff) {
          throw new Error('Invalid email or password');
        }
        authService.setToken(
          mintDemoStaffToken({ id: staff.id, email: staff.email, role: staff.role }),
        );
        router.push('/dashboard');
        return;
      }

      if (DEMO_SEED_ENABLED) {
        const staff = getOfflineStore().authenticateStaff(email, password);
        if (!staff) {
          throw new Error('Invalid email or password');
        }
        authService.setToken(
          mintDemoStaffToken({ id: staff.id, email: staff.email, role: staff.role }),
        );
        router.push('/dashboard');
        return;
      }

      const response = await fetch(`${API_BASE_URL}/v1/admin/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        const data = await response.json().catch(() => ({}));
        throw new Error(data.message || 'Invalid email or password');
      }

      const data = await response.json();
      authService.setToken(data.accessToken);
      router.push('/dashboard');
    } catch (err: any) {
      setError(err.message || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const quickLogin = async (role: 'admin' | 'ops' | 'support' | 'finance') => {
    const credentials = {
      admin: { email: 'admin@postefinance.com', password: 'Password1!' },
      ops: { email: 'ops@postefinance.com', password: 'Password1!' },
      support: { email: 'support@postefinance.com', password: 'Password1!' },
      finance: { email: 'finance@postefinance.com', password: 'Password1!' },
    };
    const cred = credentials[role];
    setEmail(cred.email);
    setPassword(cred.password);
    setError('');
    setLoading(true);
    try {
      const staff = getOfflineStore().authenticateStaff(cred.email, cred.password);
      if (!staff) throw new Error('Invalid email or password');
      authService.setToken(
        mintDemoStaffToken({ id: staff.id, email: staff.email, role: staff.role }),
      );
      router.push('/dashboard');
    } catch (err: any) {
      setError(err.message || 'Login failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const showQuickLogin = OFFLINE_DEMO || DEMO_SEED_ENABLED;

  return (
    <>
      <div className="login login-v2 fw-bold">
        <div className="login-cover">
          <div
            className="login-cover-img"
            style={{ backgroundImage: `url(${activeBg})` }}
          ></div>
          <div className="login-cover-bg"></div>
        </div>

        <div className="login-container">
          <div className="login-header">
            <div className="brand">
              <div className="d-flex align-items-center gap-2">
                <img
                  src="/assets/img/brand/poste-finance-logo-header.png"
                  alt="Poste Finance"
                  style={{ height: 36, width: 'auto' }}
                />
                <span className="ms-1">Admin</span>
              </div>
              <small>Poste Finance neo-bank operations console</small>
            </div>
            <div className="icon">
              <i className="fa fa-lock"></i>
            </div>
          </div>

          <div className="login-content">
            <form onSubmit={handleSubmit}>
              {error && (
                <div className="alert alert-danger py-2 mb-3" role="alert">
                  {error}
                </div>
              )}

              {OFFLINE_DEMO && (
                <div className="alert alert-info py-2 mb-3" role="status">
                  Offline demo — no live API
                </div>
              )}

              <div className="form-floating mb-20px">
                <input
                  type="email"
                  className="form-control fs-13px h-45px"
                  id="emailAddress"
                  placeholder="Email Address"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  autoComplete="username"
                  required
                />
                <label htmlFor="emailAddress" className="d-flex align-items-center fs-13px">
                  Email Address
                </label>
              </div>

              <div className="form-floating mb-20px">
                <input
                  type="password"
                  className="form-control fs-13px h-45px"
                  id="password"
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  autoComplete="current-password"
                  required
                />
                <label htmlFor="password" className="d-flex align-items-center fs-13px">
                  Password
                </label>
              </div>

              <div className="mb-20px">
                <button
                  type="submit"
                  className="btn btn-theme d-block w-100 h-45px btn-lg"
                  disabled={loading}
                >
                  {loading ? 'Signing in...' : 'Sign me in'}
                </button>
              </div>

              {showQuickLogin && (
                <div className="login-quick">
                  <div className="mb-2 fw-semibold text-white">Quick demo login</div>
                  <div className="d-flex flex-wrap gap-2">
                    <button type="button" className="btn btn-sm btn-default" onClick={() => quickLogin('admin')}>
                      Admin
                    </button>
                    <button type="button" className="btn btn-sm btn-default" onClick={() => quickLogin('ops')}>
                      Ops
                    </button>
                    <button type="button" className="btn btn-sm btn-default" onClick={() => quickLogin('support')}>
                      Support
                    </button>
                    <button type="button" className="btn btn-sm btn-default" onClick={() => quickLogin('finance')}>
                      Finance
                    </button>
                  </div>
                  <div className="mt-2 small text-white-50">
                    Password for all: <strong className="text-white">Password1!</strong>
                  </div>
                </div>
              )}
            </form>
          </div>
        </div>
      </div>

      <div className="login-bg-list clearfix">
        {LOGIN_BGS.map((bg) => (
          <div
            key={bg}
            className={`login-bg-list-item${activeBg === bg ? ' active' : ''}`}
          >
            <a
              href="#/"
              onClick={(e) => {
                e.preventDefault();
                setActiveBg(bg);
              }}
              style={{ backgroundImage: `url(${bg})` }}
              className="login-bg-list-link"
            ></a>
          </div>
        ))}
      </div>

      <style jsx global>{`
        /* Ensure Color Admin login-v2 form stays readable */
        .login.login-v2 .login-content .form-control {
          background: #fff !important;
          color: #2d353c !important;
          border: 1px solid rgba(255, 255, 255, 0.35) !important;
        }
        .login.login-v2 .login-content .form-floating > label {
          color: #5f6b76 !important;
        }
        .login.login-v2 .login-content .form-control:focus {
          border-color: #00acac !important;
          box-shadow: 0 0 0 0.2rem rgba(0, 172, 172, 0.25) !important;
        }
        .login.login-v2 .brand,
        .login.login-v2 .brand small,
        .login.login-v2 .login-header .icon {
          color: #fff !important;
        }
        .login.login-v2 .login-quick {
          margin-top: 1rem;
          padding-top: 1rem;
          border-top: 1px solid rgba(255, 255, 255, 0.2);
        }
        .login.login-v2 .alert-danger {
          background: #ffecec;
          border: 1px solid #ffb3b0;
          color: #9b1c1c;
          font-weight: 600;
        }
        .login.login-v2 .alert-info {
          background: rgba(0, 172, 172, 0.15);
          border: 1px solid rgba(0, 172, 172, 0.45);
          color: #fff;
          font-weight: 600;
        }
      `}</style>
    </>
  );
}
