'use client';

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authService } from '@/lib/auth';
import { DEMO_SEED_ENABLED } from '@/lib/demo-seed';
import { OFFLINE_DEMO } from '@/lib/offline/flags';
import { getOfflineStore } from '@/lib/offline/store';

interface HeaderProps {
  pageTitle: string;
}

export default function Header({ pageTitle }: HeaderProps) {
  const router = useRouter();
  const currentUser = authService.getCurrentUser();
  const [menuOpen, setMenuOpen] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  const handleResetDemo = () => {
    getOfflineStore().reset();
    window.location.reload();
  };

  const handleLogout = () => {
    setMenuOpen(false);
    authService.logout();
    router.push('/login');
  };

  useEffect(() => {
    const onDocClick = (e: MouseEvent) => {
      if (!menuRef.current?.contains(e.target as Node)) {
        setMenuOpen(false);
      }
    };
    document.addEventListener('mousedown', onDocClick);
    return () => document.removeEventListener('mousedown', onDocClick);
  }, []);

  return (
    <div id="header" className="app-header">
      <div className="navbar-header">
        <Link href="/dashboard" className="navbar-brand">
          <span className="navbar-logo"></span>
          <img
            src="/assets/img/brand/poste-finance-logo-header.png"
            alt="Poste Finance"
            style={{ height: 22, width: 'auto', marginRight: 8 }}
          />
          <span>Admin</span>
        </Link>
        <button type="button" className="navbar-mobile-toggler" data-toggle="app-sidebar-mobile">
          <span className="icon-bar"></span>
          <span className="icon-bar"></span>
          <span className="icon-bar"></span>
        </button>
      </div>

      <div className="navbar-nav">
        <div className="navbar-item d-none d-md-flex align-items-center px-3">
          <span className="fw-semibold me-2">{pageTitle}</span>
          {DEMO_SEED_ENABLED && <span className="badge bg-teal text-white">Demo data</span>}
          {OFFLINE_DEMO && (
            <>
              <span className="badge bg-warning text-dark ms-2">Offline demo — no live API</span>
              <button
                type="button"
                className="btn btn-sm btn-outline-warning ms-2"
                onClick={handleResetDemo}
                title="Reset demo data"
              >
                Reset demo
              </button>
            </>
          )}
        </div>

        {/* Always-visible logout control */}
        <div className="navbar-item d-flex align-items-center">
          <button
            type="button"
            className="btn btn-sm btn-theme me-2"
            onClick={handleLogout}
            title="Log out"
          >
            <i className="fa fa-sign-out-alt me-1"></i>
            <span className="d-none d-sm-inline">Logout</span>
          </button>
        </div>

        <div className={`navbar-item navbar-user dropdown${menuOpen ? ' show' : ''}`} ref={menuRef}>
          <a
            href="#/"
            className="navbar-link dropdown-toggle d-flex align-items-center"
            onClick={(e) => {
              e.preventDefault();
              setMenuOpen((open) => !open);
            }}
          >
            <div className="image image-icon bg-gray-800 text-gray-600">
              <i className="fa fa-user"></i>
            </div>
            <span>
              <span className="d-none d-md-inline">{currentUser?.email || 'Staff'}</span>
              <b className="caret"></b>
            </span>
          </a>
          <div
            className={`dropdown-menu dropdown-menu-end me-1${menuOpen ? ' show' : ''}`}
            style={menuOpen ? { display: 'block', position: 'absolute', right: 0 } : undefined}
          >
            <div className="dropdown-item-text small text-gray-500">
              {currentUser?.role || 'STAFF'}
            </div>
            <div className="dropdown-divider"></div>
            <button type="button" className="dropdown-item" onClick={handleLogout}>
              <i className="fa fa-sign-out-alt me-2"></i>
              Log Out
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
