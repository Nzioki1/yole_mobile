'use client';

import { usePathname } from 'next/navigation';
import Link from 'next/link';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:3000';

const navigationGroups = [
  {
    title: 'Overview',
    items: [
      { name: 'Dashboard', href: '/dashboard' },
    ],
  },
  {
    title: 'Customers',
    items: [
      { name: 'Customer 360', href: '/dashboard/customer360' },
      { name: 'KYC Queue', href: '/dashboard/kyc' },
      { name: 'Agents', href: '/dashboard/agents' },
    ],
  },
  {
    title: 'Money Movement',
    items: [
      { name: 'Payments Search', href: '/dashboard/payments' },
      { name: 'Cards', href: '/dashboard/cards' },
      { name: 'Payroll', href: '/dashboard/payroll' },
    ],
  },
  {
    title: 'Operations',
    items: [
      { name: 'Reconciliation', href: '/dashboard/recon' },
      { name: 'Cases', href: '/dashboard/cases' },
    ],
  },
  {
    title: 'Configuration',
    items: [
      { name: 'Fees & Limits', href: '/dashboard/config' },
    ],
  },
];

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
  
  const pageTitle = pageTitles[pathname] || 'YOLE Admin';

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Left Sidebar */}
      <aside className="w-60 bg-white border-r border-gray-200 flex flex-col">
        {/* Brand */}
        <div className="h-16 flex items-center px-6 border-b border-gray-200">
          <h1 className="text-xl font-bold text-gray-900">YOLE Admin</h1>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-6 px-3">
          {navigationGroups.map((group) => (
            <div key={group.title} className="mb-6">
              <h3 className="px-3 text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2">
                {group.title}
              </h3>
              <ul className="space-y-1">
                {group.items.map((item) => {
                  const isActive = pathname === item.href || 
                    (item.href !== '/dashboard' && pathname.startsWith(item.href));
                  
                  return (
                    <li key={item.href}>
                      <Link
                        href={item.href}
                        className={`
                          block px-3 py-2 text-sm rounded-md transition-colors
                          ${isActive 
                            ? 'bg-slate-100 text-slate-900 font-medium' 
                            : 'text-gray-700 hover:bg-gray-50 hover:text-gray-900'
                          }
                        `}
                      >
                        {item.name}
                      </Link>
                    </li>
                  );
                })}
              </ul>
            </div>
          ))}
        </nav>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top Bar */}
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-8">
          <h2 className="text-xl font-semibold text-gray-900">{pageTitle}</h2>
          
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 px-3 py-1.5 bg-gray-100 rounded-md text-sm">
              <span className="text-gray-600">API:</span>
              <span className="font-mono text-gray-900 text-xs">{API_BASE_URL}</span>
            </div>
            <div className="flex items-center gap-2 px-3 py-1.5 bg-blue-50 rounded-md text-sm">
              <span className="text-blue-600">Auth:</span>
              <span className="font-mono text-blue-900 text-xs">dev-admin-key</span>
            </div>
          </div>
        </header>

        {/* Page Content */}
        <main className="flex-1 overflow-y-auto bg-gray-50">
          <div className="p-8">
            {children}
          </div>
        </main>
      </div>
    </div>
  );
}
