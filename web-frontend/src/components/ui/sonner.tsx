'use client';

import { Toaster as Sonner, ToasterProps } from 'sonner';

const Toaster = ({ ...props }: ToasterProps) => {
  return (
    <Sonner
      className='toaster group'
      position='top-center'
      expand={true}
      richColors
      toastOptions={{
        style: {
          padding: '16px',
          fontSize: '16px',
          fontWeight: '500',
          minWidth: '400px',
          maxWidth: '600px',
        },
        classNames: {
          success: 'bg-green-50 text-green-900 border-green-200',
          error: 'bg-red-50 text-red-900 border-red-200',
          warning: 'bg-yellow-50 text-yellow-900 border-yellow-200',
          info: 'bg-blue-50 text-blue-900 border-blue-200',
        },
      }}
      style={
        {
          '--normal-bg': 'var(--popover)',
          '--normal-text': 'var(--popover-foreground)',
          '--normal-border': 'var(--border)',
        } as React.CSSProperties
      }
      {...props}
    />
  );
};

export { Toaster };
