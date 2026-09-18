import type { Metadata } from 'next';
import 'bootstrap-icons/font/bootstrap-icons.css';
import '@fortawesome/fontawesome-free/css/all.min.css';
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
      <head>
        <link rel="stylesheet" href="/assets/css/default/app.min.css" />
        <link rel="icon" href="/assets/img/brand/poste-finance-mark.png" />
      </head>
      <body>{children}</body>
    </html>
  );
}
