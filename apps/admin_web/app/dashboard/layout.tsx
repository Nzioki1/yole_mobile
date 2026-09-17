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
  const pageTitle = pageTitles[pathname] || 'YOLE Admin';

  useEffect(() => {
    const currentUser = authService.getCurrentUser();
    
    if (!currentUser) {
      router.push('/login');
      return;
    }

    if (!canAccessRoute(currentUser.role, pathname)) {
      router.push('/dashboard');
      return;
    }
  }, [pathname, router]);

  return (
    <div className="app">
      <style jsx global>{`
        * {
          margin: 0;
          padding: 0;
          box-sizing: border-box;
        }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          background: #f5f5f5;
          color: #2d353c;
        }
        .app {
          display: flex;
          min-height: 100vh;
        }
        .app-content {
          flex: 1;
          margin-left: 250px;
          margin-top: 60px;
          padding: 2rem;
          min-height: calc(100vh - 60px);
        }
        .panel {
          background: white;
          border-radius: 0.5rem;
          box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
          margin-bottom: 1.5rem;
        }
        .panel-heading {
          padding: 1rem 1.5rem;
          border-bottom: 1px solid #e5e5e5;
          font-weight: 600;
          color: #2d353c;
        }
        .panel-body {
          padding: 1.5rem;
        }
      `}</style>

      <Sidebar />
      <Header pageTitle={pageTitle} />

      <div className="app-content">
        {children}
      </div>
    </div>
  );
}
