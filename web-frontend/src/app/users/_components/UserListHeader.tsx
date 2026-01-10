'use client';

import { Button } from '@/components/ui/button';
import { Plus, Users } from 'lucide-react';

type Props = {
  onCreateClick: () => void;
};

export function UserListHeader({ onCreateClick }: Props) {
  return (
    <header className='h-16 border-b bg-background'>
      <div className='container mx-auto flex h-full items-center justify-between px-6'>
        <div className='flex items-center gap-2'>
          <Users className='h-5 w-5' />
          <h1 className='text-lg font-semibold'>User Management</h1>
        </div>
        <Button onClick={onCreateClick}>
          <Plus className='h-4 w-4' />
          Create User
        </Button>
      </div>
    </header>
  );
}
