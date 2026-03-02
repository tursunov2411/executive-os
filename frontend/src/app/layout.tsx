import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Executive OS - Mission Control',
  description: 'Closed-loop human optimization system.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
