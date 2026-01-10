import type { User } from '@/schemas/user/user.schema';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import dayjs from 'dayjs';
import { Mail, User as UserIcon, Calendar, Clock } from 'lucide-react';

type Props = {
  user: User;
};

export function UserInfoCard({ user }: Props) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>User Information</CardTitle>
      </CardHeader>
      <CardContent className='space-y-6'>
        <div className='grid gap-6 sm:grid-cols-2'>
          <div className='flex items-start gap-3'>
            <div className='rounded-md bg-muted p-2'>
              <UserIcon className='h-4 w-4 text-muted-foreground' />
            </div>
            <div>
              <p className='text-sm text-muted-foreground'>Name</p>
              <p className='font-medium'>{user.name}</p>
            </div>
          </div>

          <div className='flex items-start gap-3'>
            <div className='rounded-md bg-muted p-2'>
              <Mail className='h-4 w-4 text-muted-foreground' />
            </div>
            <div>
              <p className='text-sm text-muted-foreground'>Email</p>
              <p className='font-medium'>{user.email}</p>
            </div>
          </div>

          <div className='flex items-start gap-3'>
            <div className='rounded-md bg-muted p-2'>
              <Calendar className='h-4 w-4 text-muted-foreground' />
            </div>
            <div>
              <p className='text-sm text-muted-foreground'>Created</p>
              <p className='font-medium'>
                {dayjs(user.createdAt).format('YYYY/MM/DD HH:mm')}
              </p>
            </div>
          </div>

          <div className='flex items-start gap-3'>
            <div className='rounded-md bg-muted p-2'>
              <Clock className='h-4 w-4 text-muted-foreground' />
            </div>
            <div>
              <p className='text-sm text-muted-foreground'>Updated</p>
              <p className='font-medium'>
                {dayjs(user.updatedAt).format('YYYY/MM/DD HH:mm')}
              </p>
            </div>
          </div>
        </div>

        <div className='border-t pt-4'>
          <p className='text-sm text-muted-foreground'>ID</p>
          <p className='font-mono text-sm'>{user.id}</p>
        </div>
      </CardContent>
    </Card>
  );
}
