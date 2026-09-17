'use client';

import { useEffect } from 'react';
import { usePathname, useRouter } from 'next/navigation';
import Sidebar from '@/components/sidebar/Sidebar';
import Header from '@/components/header/Header';
import { authService } from '@/lib/auth';
import { canAccessRoute } from '@/lib/rbac';

const pageTitles: Record<string, string> = {
  '/dashboard': 'Overview',
  '/dashboard/customer360': 'Customer 360',
  '/dashboard/kyc': 'KYC Queue',
  '/dashboard/agents': 'Agents',
  '/dashboard/payments': 'Payments Search',
  '/dashboard/cards': 'Virtual Cards',
  '/dashboard/payroll': 'Payroll',
  '/dashboard/recon': 'Reconciliation',
  '/dashboard/cases': 'Cases & Support',
  '/dashboard/config': 'Fees & Limits',
};

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const pathname = usePathname();
  const router = useRouter();
  const pageTitle =
    pageTitles[pathname] ||
    (pathname.startsWith('/dashboard/payroll/') ? 'Employer Detail' : 'YOLE Admin');

  useEffect(() => {
    const currentUser = authService.getCurrentUser();
    if (!currentUser) {
      router.push('/login');
      return;
    }
    if (!canAccessRoute(currentUser.role, pathname)) {
      router.push('/dashboard');
    }
  }, [pathname, router]);

  return (
    <div className="app app-header-fixed app-sidebar-fixed">
      <Header pageTitle={pageTitle} />
      <Sidebar />
      <div className="app-content">
        <ol className="breadcrumb float-xl-end">
          <li className="breadcrumb-item">
            <a href="/dashboard">Home</a>
          </li>
          <li className="breadcrumb-item active">{pageTitle}</li>
        </ol>
        <h1 className="page-header">
          {pageTitle} <small>YOLE operations</small>
        </h1>
        {children}
      </div>
    </div>
  );
}
