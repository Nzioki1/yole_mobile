'use client';

import { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { authService } from '@/lib/auth';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      const response = await fetch(`${API_BASE_URL}/v1/admin/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, password }),
      });

      if (!response.ok) {
        throw new Error('Invalid credentials');
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

  const quickLogin = (role: string) => {
    const credentials: Record<string, { email: string; password: string }> = {
      admin: { email: 'admin@yole.com', password: 'Password1!' },
      ops: { email: 'ops@yole.com', password: 'Password1!' },
      support: { email: 'support@yole.com', password: 'Password1!' },
      finance: { email: 'finance@yole.com', password: 'Password1!' },
    };
    
    const cred = credentials[role];
    if (cred) {
      setEmail(cred.email);
      setPassword(cred.password);
    }
  };

  return (
    <div className="login login-v2 fw-bold" style={{ minHeight: '100vh', display: 'flex' }}>
      <style jsx global>{`
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        }
        .login-v2 {
          display: flex;
          align-items: stretch;
          width: 100%;
        }
        .login-cover {
          flex: 1;
          position: relative;
          background: linear-gradient(135deg, #00acac 0%, #348fe2 100%);
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .login-cover-content {
          text-align: center;
          color: white;
          padding: 3rem;
        }
        .login-container {
          width: 500px;
          display: flex;
          flex-direction: column;
          justify-content: center;
          padding: 3rem;
          background: white;
        }
        .login-header {
          text-align: center;
          margin-bottom: 2rem;
        }
        .brand {
          font-size: 2rem;
          font-weight: bold;
          color: #00acac;
          margin-bottom: 0.5rem;
        }
        .brand small {
          display: block;
          font-size: 0.875rem;
          color: #6c757d;
          font-weight: normal;
          margin-top: 0.5rem;
        }
        .form-floating {
          position: relative;
          margin-bottom: 1.25rem;
        }
        .form-control {
          width: 100%;
          padding: 1rem 0.75rem;
          font-size: 0.875rem;
          border: 1px solid #dee2e6;
          border-radius: 0.25rem;
          transition: border-color 0.15s ease-in-out;
        }
        .form-control:focus {
          outline: none;
          border-color: #00acac;
          box-shadow: 0 0 0 0.2rem rgba(0, 172, 172, 0.25);
        }
        .form-floating label {
          position: absolute;
          top: 0;
          left: 0.75rem;
          padding: 1rem 0;
          pointer-events: none;
          color: #6c757d;
          font-size: 0.875rem;
          transition: all 0.1s ease;
        }
        .btn-theme {
          background: #00acac;
          color: white;
          border: none;
          padding: 0.75rem;
          font-size: 1rem;
          font-weight: 600;
          border-radius: 0.25rem;
          cursor: pointer;
          transition: background 0.15s ease-in-out;
        }
        .btn-theme:hover {
          background: #009999;
        }
        .btn-theme:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
        .alert {
          padding: 0.75rem 1rem;
          margin-bottom: 1rem;
          border-radius: 0.25rem;
          background: #f8d7da;
          color: #721c24;
          border: 1px solid #f5c6cb;
        }
        .quick-login {
          margin-top: 1.5rem;
          padding-top: 1.5rem;
          border-top: 1px solid #dee2e6;
        }
        .quick-login-btn {
          display: inline-block;
          padding: 0.5rem 1rem;
          margin: 0.25rem;
          font-size: 0.875rem;
          border: 1px solid #00acac;
          color: #00acac;
          border-radius: 0.25rem;
          cursor: pointer;
          background: white;
          transition: all 0.15s;
        }
        .quick-login-btn:hover {
          background: #00acac;
          color: white;
        }
      `}</style>

      <div className="login-cover">
        <div className="login-cover-content">
          <h1 style={{ fontSize: '3rem', marginBottom: '1rem' }}>YOLE</h1>
          <p style={{ fontSize: '1.25rem', opacity: 0.9 }}>
            Staff Admin Portal
          </p>
          <p style={{ marginTop: '2rem', opacity: 0.8 }}>
            Secure access for authorized personnel
          </p>
        </div>
      </div>

      <div className="login-container">
        <div className="login-header">
          <div className="brand">
            YOLE <span style={{ fontWeight: 'normal' }}>Admin</span>
            <small>Staff Portal — Color Admin Teal</small>
          </div>
        </div>

        <div className="login-content">
          {error && (
            <div className="alert">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit}>
            <div className="form-floating">
              <input
                type="email"
                className="form-control"
                placeholder="Email Address"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                disabled={loading}
              />
              <label>Email Address</label>
            </div>

            <div className="form-floating">
              <input
                type="password"
                className="form-control"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={loading}
              />
              <label>Password</label>
            </div>

            <div style={{ marginBottom: '1.25rem' }}>
              <button
                type="submit"
                className="btn-theme"
                style={{ width: '100%', height: '45px' }}
                disabled={loading}
              >
                {loading ? 'Signing in...' : 'Sign me in'}
              </button>
            </div>
          </form>

          <div className="quick-login">
            <p style={{ fontSize: '0.875rem', color: '#6c757d', marginBottom: '0.75rem' }}>
              Quick login (dev):
            </p>
            <button onClick={() => quickLogin('admin')} className="quick-login-btn">
              Admin
            </button>
            <button onClick={() => quickLogin('ops')} className="quick-login-btn">
              Ops
            </button>
            <button onClick={() => quickLogin('support')} className="quick-login-btn">
              Support
            </button>
            <button onClick={() => quickLogin('finance')} className="quick-login-btn">
              Finance
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
