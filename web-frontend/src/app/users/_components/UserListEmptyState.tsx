'use client';

import { Button } from '@/components/ui/button';
import { Users, X } from 'lucide-react';

type Props = {
  hasSearch: boolean;
  onClearSearch: () => void;
};

export function UserListEmptyState({ hasSearch, onClearSearch }: Props) {
  return (
    <div className='flex flex-col items-center justify-center py-12'>
      <Users className='h-12 w-12 text-muted-foreground' />
      <h3 className='mt-4 text-lg font-semibold'>No users found</h3>
      <p className='mt-2 text-sm text-muted-foreground'>
        {hasSearch
          ? 'No users match your search criteria.'
          : 'Get started by creating a new user.'}
      </p>
      {hasSearch && (
        <Button variant='outline' className='mt-4' onClick={onClearSearch}>
          <X className='h-4 w-4' />
          Clear search
        </Button>
      )}
    </div>
  );
}
