'use client';

import { usePathname } from 'next/navigation';
import Link from 'next/link';
import { authService, StaffRole } from '@/lib/auth';
import { getAuthorizedRoutes } from '@/lib/rbac';

const navigationGroups = [
  {
    title: 'Overview',
    items: [
      { name: 'Dashboard', href: '/dashboard', icon: '📊' },
    ],
  },
  {
    title: 'Customers',
    items: [
      { name: 'Customer 360', href: '/dashboard/customer360', icon: '👤' },
      { name: 'KYC Queue', href: '/dashboard/kyc', icon: '📋' },
      { name: 'Agents', href: '/dashboard/agents', icon: '👥' },
    ],
  },
  {
    title: 'Money Movement',
    items: [
      { name: 'Payments', href: '/dashboard/payments', icon: '💰' },
      { name: 'Cards', href: '/dashboard/cards', icon: '💳' },
      { name: 'Payroll', href: '/dashboard/payroll', icon: '💼' },
    ],
  },
  {
    title: 'Operations',
    items: [
      { name: 'Reconciliation', href: '/dashboard/recon', icon: '📊' },
      { name: 'Cases', href: '/dashboard/cases', icon: '🎫' },
    ],
  },
  {
    title: 'Configuration',
    items: [
      { name: 'Fees & Limits', href: '/dashboard/config', icon: '⚙️' },
    ],
  },
];

export default function Sidebar() {
  const pathname = usePathname();
  const currentUser = authService.getCurrentUser();
  const authorizedRoutes = currentUser ? getAuthorizedRoutes(currentUser.role) : [];

  const canAccess = (href: string) => {
    return authorizedRoutes.some(r => href === r || href.startsWith(r + '/'));
  };

  return (
    <div className="app-sidebar" data-bs-theme="dark">
      <style jsx global>{`
        .app-sidebar {
          width: 250px;
          background: #2d353c;
          color: #b6c2c9;
          display: flex;
          flex-direction: column;
          height: 100vh;
          position: fixed;
          left: 0;
          top: 0;
          overflow-y: auto;
        }
        .sidebar-header {
          padding: 1rem 1.5rem;
          border-bottom: 1px solid rgba(255, 255, 255, 0.1);
        }
        .sidebar-brand {
          font-size: 1.25rem;
          font-weight: 700;
          color: #00acac;
        }
        .sidebar-user {
          padding: 1.5rem;
          border-bottom: 1px solid rgba(255, 255, 255, 0.1);
          text-align: center;
        }
        .sidebar-user-avatar {
          width: 60px;
          height: 60px;
          border-radius: 50%;
          background: #00acac;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 0.75rem;
          font-size: 1.5rem;
          color: white;
          font-weight: 600;
        }
        .sidebar-user-name {
          font-weight: 600;
          color: white;
          margin-bottom: 0.25rem;
        }
        .sidebar-user-role {
          font-size: 0.75rem;
          color: #b6c2c9;
          text-transform: uppercase;
        }
        .sidebar-nav {
          flex: 1;
          padding: 1rem 0;
        }
        .nav-group-title {
          padding: 0.75rem 1.5rem 0.5rem;
          font-size: 0.75rem;
          font-weight: 600;
          text-transform: uppercase;
          color: #7a8288;
        }
        .nav-item {
          margin: 0.125rem 0.75rem;
        }
        .nav-link {
          display: flex;
          align-items: center;
          padding: 0.625rem 0.75rem;
          color: #b6c2c9;
          text-decoration: none;
          border-radius: 0.25rem;
          transition: all 0.15s;
          font-size: 0.875rem;
        }
        .nav-link:hover {
          background: rgba(255, 255, 255, 0.05);
          color: white;
        }
        .nav-link.active {
          background: #00acac;
          color: white;
        }
        .nav-link .icon {
          margin-right: 0.75rem;
          font-size: 1.125rem;
        }
        .nav-link.disabled {
          opacity: 0.4;
          pointer-events: none;
        }
      `}</style>

      <div className="sidebar-header">
        <div className="sidebar-brand">YOLE Admin</div>
      </div>

      {currentUser && (
        <div className="sidebar-user">
          <div className="sidebar-user-avatar">
            {currentUser.email.charAt(0).toUpperCase()}
          </div>
          <div className="sidebar-user-name">{currentUser.email.split('@')[0]}</div>
          <div className="sidebar-user-role">{currentUser.role}</div>
        </div>
      )}

      <div className="sidebar-nav">
        {navigationGroups.map((group) => {
          const visibleItems = group.items.filter(item => canAccess(item.href));
          if (visibleItems.length === 0) return null;

          return (
            <div key={group.title}>
              <div className="nav-group-title">{group.title}</div>
              <div>
                {visibleItems.map((item) => {
                  const isActive = pathname === item.href || 
                    (item.href !== '/dashboard' && pathname.startsWith(item.href));
                  
                  return (
                    <div key={item.href} className="nav-item">
                      <Link
                        href={item.href}
                        className={`nav-link ${isActive ? 'active' : ''}`}
                      >
                        <span className="icon">{item.icon}</span>
                        <span>{item.name}</span>
                      </Link>
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
