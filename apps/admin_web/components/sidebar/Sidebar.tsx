'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { authService } from '@/lib/auth';
import { getAuthorizedRoutes } from '@/lib/rbac';

type NavItem = { name: string; href: string; icon: string };
type NavGroup = { title: string; items: NavItem[] };

const NAV: NavGroup[] = [
  {
    title: 'Overview',
    items: [{ name: 'Dashboard', href: '/dashboard', icon: 'fa fa-sitemap' }],
  },
  {
    title: 'Customers',
    items: [
      { name: 'Customer 360', href: '/dashboard/customer360', icon: 'fa fa-user' },
      { name: 'KYC Queue', href: '/dashboard/kyc', icon: 'fa fa-id-card' },
      { name: 'Agents', href: '/dashboard/agents', icon: 'fa fa-users' },
    ],
  },
  {
    title: 'Money Movement',
    items: [
      { name: 'Payments', href: '/dashboard/payments', icon: 'fa fa-money-bill' },
      { name: 'Cards', href: '/dashboard/cards', icon: 'fa fa-credit-card' },
      { name: 'Payroll', href: '/dashboard/payroll', icon: 'fa fa-briefcase' },
      { name: 'Remittance', href: '/dashboard/remittance', icon: 'fa fa-globe' },
      { name: 'Idempotency lab', href: '/dashboard/idempotency', icon: 'fa fa-redo' },
    ],
  },
  {
    title: 'Credit & Products',
    items: [
      { name: 'Products & rules', href: '/dashboard/products', icon: 'fa fa-box' },
      { name: 'Pending approvals', href: '/dashboard/approvals', icon: 'fa fa-check-double' },
      { name: 'Credit exceptions', href: '/dashboard/credit-exceptions', icon: 'fa fa-exclamation-circle' },
    ],
  },
  {
    title: 'Operations',
    items: [
      { name: 'Reconciliation', href: '/dashboard/recon', icon: 'fa fa-balance-scale' },
      { name: 'Cases', href: '/dashboard/cases', icon: 'fa fa-ticket' },
      { name: 'Resilience (demo)', href: '/dashboard/resilience', icon: 'fa fa-server' },
      { name: 'Export pack', href: '/dashboard/export', icon: 'fa fa-download' },
    ],
  },
  {
    title: 'Configuration',
    items: [{ name: 'Fees & Limits', href: '/dashboard/config', icon: 'fa fa-cog' }],
  },
];

export default function Sidebar() {
  const pathname = usePathname();
  const user = authService.getCurrentUser();
  const authorizedRoutes = user ? getAuthorizedRoutes(user.role) : [];

  const canAccess = (href: string) =>
    authorizedRoutes.some((r) => href === r || href.startsWith(r + '/'));

  return (
    <>
      <div id="sidebar" className="app-sidebar" data-bs-theme="dark">
        <div className="app-sidebar-content" data-scrollbar="true" data-height="100%">
          <div className="menu">
            <div className="menu-profile">
              <div className="menu-profile-link">
                <div className="menu-profile-cover with-shadow"></div>
                <div className="menu-profile-image menu-profile-image-icon bg-gray-900 text-gray-600">
                  <i className="fa fa-user"></i>
                </div>
                <div className="menu-profile-info">
                  <div className="d-flex align-items-center">
                    <div className="flex-grow-1">{user?.email || 'Staff'}</div>
                  </div>
                  <small>{user?.role || 'YOLE'}</small>
                </div>
              </div>
            </div>

            {NAV.map((group) => {
              const items = group.items.filter((item) => canAccess(item.href));
              if (!items.length) return null;
              return (
                <div key={group.title}>
                  <div className="menu-header">{group.title}</div>
                  {items.map((item) => {
                    const active =
                      pathname === item.href ||
                      (item.href !== '/dashboard' && pathname.startsWith(item.href));
                    return (
                      <div key={item.href} className={`menu-item${active ? ' active' : ''}`}>
                        <Link href={item.href} className="menu-link">
                          <div className="menu-icon">
                            <i className={item.icon}></i>
                          </div>
                          <div className="menu-text">{item.name}</div>
                        </Link>
                      </div>
                    );
                  })}
                </div>
              );
            })}
          </div>
        </div>
      </div>
      <div className="app-sidebar-bg" data-bs-theme="dark"></div>
      <div className="app-sidebar-mobile-backdrop">
        <a href="#/" data-dismiss="app-sidebar-mobile" className="stretched-link"></a>
      </div>
    </>
  );
}
