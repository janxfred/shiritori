'use client';

import { useRouter } from 'next/navigation';
import type { User } from '@/schemas/user/user.schema';
import { Input } from '@/components/ui/input';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import dayjs from 'dayjs';
import { Search } from 'lucide-react';

type Props = {
  users: User[];
  searchValue: string;
  onSearchChange: (value: string) => void;
};

export function UserListTable({ users, searchValue, onSearchChange }: Props) {
  const router = useRouter();

  return (
    <div className='space-y-4'>
      <div className='flex justify-end'>
        <div className='relative max-w-xs'>
          <Search className='absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground' />
          <Input
            value={searchValue}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder='Search by name or email'
            className='pl-9'
          />
        </div>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Email</TableHead>
            <TableHead>Created</TableHead>
            <TableHead>Updated</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {users.map((user) => (
            <TableRow
              key={user.id}
              className='cursor-pointer hover:bg-muted/50'
              onClick={() => router.push(`/users/${user.id}`)}
            >
              <TableCell className='font-medium'>{user.name}</TableCell>
              <TableCell>{user.email}</TableCell>
              <TableCell>
                {dayjs(user.createdAt).format('YYYY/MM/DD HH:mm')}
              </TableCell>
              <TableCell>
                {dayjs(user.updatedAt).format('YYYY/MM/DD HH:mm')}
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  );
}
