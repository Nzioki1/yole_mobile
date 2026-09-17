import type { Metadata } from 'next';
import 'bootstrap-icons/font/bootstrap-icons.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
import 'react-perfect-scrollbar/dist/css/styles.css';
import './globals.css';

export const metadata: Metadata = {
  title: 'Poste Finance Admin',
  description: 'Poste Finance Admin Portal — Color Admin default + teal',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        {/* Color Admin v5.5.2 default theme (teal) */}
        <link rel="stylesheet" href="/assets/css/default/app.min.css" />
        {children}
      </body>
    </html>
  );
}
