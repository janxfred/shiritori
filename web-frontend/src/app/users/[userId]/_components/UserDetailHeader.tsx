'use client';

import { useRouter } from 'next/navigation';
import type { User } from '@/schemas/user/user.schema';
import { Button } from '@/components/ui/button';
import { ArrowLeft, Pencil, Trash2 } from 'lucide-react';

type Props = {
  user: User;
  onEditClick: () => void;
  onDeleteClick: () => void;
};

export function UserDetailHeader({ user, onEditClick, onDeleteClick }: Props) {
  const router = useRouter();

  return (
    <header className='h-16 border-b bg-background'>
      <div className='container mx-auto flex h-full items-center justify-between px-6'>
        <div className='flex items-center gap-4'>
          <Button
            variant='ghost'
            size='icon'
            onClick={() => router.push('/users')}
          >
            <ArrowLeft className='h-4 w-4' />
          </Button>
          <h1 className='text-lg font-semibold'>{user.name}</h1>
        </div>
        <div className='flex items-center gap-2'>
          <Button variant='outline' onClick={onEditClick}>
            <Pencil className='h-4 w-4' />
            Edit
          </Button>
          <Button variant='destructive' onClick={onDeleteClick}>
            <Trash2 className='h-4 w-4' />
            Delete
          </Button>
        </div>
      </div>
    </header>
  );
}
