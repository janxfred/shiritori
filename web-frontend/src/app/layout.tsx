import type { Metadata } from 'next';
import './globals.css';
import { Toaster } from '@/components/ui/sonner';

export const metadata: Metadata = {
  title: 'Web Frontend',
  description: 'User management application',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang='ja'>
      <body className='bg-background'>
        <main className='min-h-screen'>{children}</main>
        <Toaster closeButton />
      </body>
    </html>
  );
}
