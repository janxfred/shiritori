'use client';

import { Button } from '@/components/ui/button';
import type { PaginationResponse } from '@/schemas/pagination.schema';
import { ChevronLeft, ChevronRight } from 'lucide-react';

type Props = {
  pagination: PaginationResponse;
  onPageChange: (page: number) => void;
};

export function UserListPagination({ pagination, onPageChange }: Props) {
  return (
    <div className='mt-4 flex items-center justify-between'>
      <p className='text-sm text-muted-foreground'>
        Showing {(pagination.page - 1) * pagination.limit + 1} to{' '}
        {Math.min(pagination.page * pagination.limit, pagination.total)} of{' '}
        {pagination.total} users
      </p>
      <div className='flex items-center gap-2'>
        <Button
          variant='outline'
          size='sm'
          onClick={() => onPageChange(pagination.page - 1)}
          disabled={!pagination.hasPrev}
        >
          <ChevronLeft className='h-4 w-4' />
          Previous
        </Button>
        <span className='text-sm text-muted-foreground'>
          Page {pagination.page} of {pagination.totalPages}
        </span>
        <Button
          variant='outline'
          size='sm'
          onClick={() => onPageChange(pagination.page + 1)}
          disabled={!pagination.hasNext}
        >
          Next
          <ChevronRight className='h-4 w-4' />
        </Button>
      </div>
    </div>
  );
}
