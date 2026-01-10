'use client';

import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import useSWRMutation from 'swr/mutation';
import { toast } from 'sonner';
import type { User } from '@/schemas/user/user.schema';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { fetcher } from '@/lib/fetcher';
import {
  updateUserRequestSchema,
  commandResponseSchema,
  type UpdateUserRequest,
} from '@/schemas/user/update-user.schema';
import { ApiError } from '@/lib/api-error';

function useUpdateUser(userId: string) {
  return useSWRMutation(
    `/api/users/${userId}`,
    async (path: string, { arg }: { arg: UpdateUserRequest }) => {
      return fetcher(path, commandResponseSchema, {
        method: 'PUT',
        body: arg,
      });
    }
  );
}

type Props = {
  user: User;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess: () => void;
};

export function EditUserDialog({ user, open, onOpenChange, onSuccess }: Props) {
  const { trigger, isMutating } = useUpdateUser(user.id);

  const form = useForm<UpdateUserRequest>({
    resolver: zodResolver(updateUserRequestSchema),
    defaultValues: {
      email: user.email,
      name: user.name,
    },
  });

  useEffect(() => {
    if (open) {
      form.reset({
        email: user.email,
        name: user.name,
      });
    }
  }, [open, user, form]);

  const onSubmit = async (data: UpdateUserRequest) => {
    try {
      await trigger(data);
      toast.success('User updated successfully');
      onSuccess();
    } catch (error) {
      if (error instanceof ApiError) {
        if (error.isConflict()) {
          form.setError('email', {
            type: 'manual',
            message: 'This email is already registered',
          });
          return;
        }
        toast.error(error.message);
      } else {
        toast.error('Failed to update user');
      }
    }
  };

  const handleOpenChange = (newOpen: boolean) => {
    if (!newOpen) {
      form.reset();
    }
    onOpenChange(newOpen);
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Edit User</DialogTitle>
          <DialogDescription>
            Update the user information below.
          </DialogDescription>
        </DialogHeader>

        <Form {...form}>
          <form onSubmit={form.handleSubmit(onSubmit)} className='space-y-4'>
            <FormField
              control={form.control}
              name='name'
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Name</FormLabel>
                  <FormControl>
                    <Input placeholder='Enter name' {...field} />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <FormField
              control={form.control}
              name='email'
              render={({ field }) => (
                <FormItem>
                  <FormLabel>Email</FormLabel>
                  <FormControl>
                    <Input
                      type='email'
                      placeholder='Enter email address'
                      {...field}
                    />
                  </FormControl>
                  <FormMessage />
                </FormItem>
              )}
            />

            <DialogFooter>
              <Button
                type='button'
                variant='outline'
                onClick={() => handleOpenChange(false)}
              >
                Cancel
              </Button>
              <Button type='submit' disabled={isMutating}>
                {isMutating ? 'Saving...' : 'Save'}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
