'use client';

import { useRouter } from 'next/navigation';
import { authService } from '@/lib/auth';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

interface HeaderProps {
  pageTitle: string;
}

export default function Header({ pageTitle }: HeaderProps) {
  const router = useRouter();
  const currentUser = authService.getCurrentUser();

  const handleLogout = () => {
    authService.logout();
    router.push('/login');
  };

  return (
    <div className="app-header">
      <style jsx global>{`
        .app-header {
          height: 60px;
          background: white;
          border-bottom: 1px solid #e5e5e5;
          display: flex;
          align-items: center;
          justify-content: space-between;
          padding: 0 2rem;
          position: fixed;
          left: 250px;
          right: 0;
          top: 0;
          z-index: 100;
        }
        .page-title {
          font-size: 1.25rem;
          font-weight: 600;
          color: #2d353c;
        }
        .header-actions {
          display: flex;
          align-items: center;
          gap: 1rem;
        }
        .header-badge {
          padding: 0.375rem 0.75rem;
          background: #f5f5f5;
          border-radius: 0.25rem;
          font-size: 0.75rem;
          color: #6c757d;
        }
        .header-badge strong {
          color: #2d353c;
        }
        .header-user {
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }
        .user-avatar {
          width: 36px;
          height: 36px;
          border-radius: 50%;
          background: #00acac;
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
          font-weight: 600;
          font-size: 0.875rem;
        }
        .user-info {
          text-align: right;
        }
        .user-name {
          font-size: 0.875rem;
          font-weight: 600;
          color: #2d353c;
        }
        .user-role {
          font-size: 0.75rem;
          color: #6c757d;
        }
        .btn-logout {
          padding: 0.5rem 1rem;
          background: #dc3545;
          color: white;
          border: none;
          border-radius: 0.25rem;
          font-size: 0.875rem;
          cursor: pointer;
          transition: background 0.15s;
        }
        .btn-logout:hover {
          background: #c82333;
        }
      `}</style>

      <div className="page-title">{pageTitle}</div>

      <div className="header-actions">
        <div className="header-badge">
          API: <strong>{API_BASE_URL}</strong>
        </div>

        {currentUser && (
          <>
            <div className="header-user">
              <div className="user-avatar">
                {currentUser.email.charAt(0).toUpperCase()}
              </div>
              <div className="user-info">
                <div className="user-name">{currentUser.email.split('@')[0]}</div>
                <div className="user-role">{currentUser.role}</div>
              </div>
            </div>

            <button onClick={handleLogout} className="btn-logout">
              Logout
            </button>
          </>
        )}
      </div>
    </div>
  );
}
