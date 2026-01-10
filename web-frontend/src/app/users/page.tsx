'use client';

import { useState } from 'react';
import useSWR from 'swr';
import { createSwrFetcher } from '@/lib/fetcher';
import {
  listUsersResponseSchema,
  type ListUsersQuery,
} from '@/schemas/user/list-users.schema';
import { UserListHeader } from './_components/UserListHeader';
import { UserListTable } from './_components/UserListTable';
import { UserListEmptyState } from './_components/UserListEmptyState';
import { UserListPagination } from './_components/UserListPagination';
import { CreateUserDialog } from './_components/CreateUserDialog';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Users } from 'lucide-react';

function useUsers(query?: ListUsersQuery) {
  const params = new URLSearchParams();
  if (query?.page) params.set('page', String(query.page));
  if (query?.limit) params.set('limit', String(query.limit));
  if (query?.search) params.set('search', query.search);

  const queryString = params.toString();
  const path = `/api/users${queryString ? `?${queryString}` : ''}`;

  return useSWR(path, createSwrFetcher(listUsersResponseSchema), {
    revalidateOnFocus: false,
  });
}

export default function UsersPage() {
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [createDialogOpen, setCreateDialogOpen] = useState(false);

  const { data, isLoading, mutate } = useUsers({
    page,
    limit: 20,
    search: search || undefined,
  });

  const handleSearchChange = (value: string) => {
    setSearch(value);
    setPage(1);
  };

  const handleCreateSuccess = () => {
    setCreateDialogOpen(false);
    mutate();
  };

  return (
    <div className='min-h-screen bg-background'>
      <UserListHeader onCreateClick={() => setCreateDialogOpen(true)} />

      <main className='container mx-auto px-6 py-8'>
        <Card>
          <CardHeader>
            <div className='flex items-center space-x-2'>
              <Users className='h-5 w-5 text-primary' />
              <CardTitle className='text-lg font-semibold'>User List</CardTitle>
            </div>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className='space-y-4'>
                <Skeleton className='h-10 w-full' />
                <Skeleton className='h-64 w-full' />
              </div>
            ) : data?.data.length === 0 ? (
              <UserListEmptyState
                hasSearch={!!search}
                onClearSearch={() => setSearch('')}
              />
            ) : (
              <>
                <UserListTable
                  users={data?.data ?? []}
                  searchValue={search}
                  onSearchChange={handleSearchChange}
                />
                {data?.pagination && (
                  <UserListPagination
                    pagination={data.pagination}
                    onPageChange={setPage}
                  />
                )}
              </>
            )}
          </CardContent>
        </Card>
      </main>

      <CreateUserDialog
        open={createDialogOpen}
        onOpenChange={setCreateDialogOpen}
        onSuccess={handleCreateSuccess}
      />
    </div>
  );
}
