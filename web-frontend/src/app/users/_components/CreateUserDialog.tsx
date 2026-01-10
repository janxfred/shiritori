'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import useSWRMutation from 'swr/mutation';
import { toast } from 'sonner';
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
  createUserRequestSchema,
  commandResponseSchema,
  type CreateUserRequest,
} from '@/schemas/user/create-user.schema';
import { ApiError } from '@/lib/api-error';

function useCreateUser() {
  return useSWRMutation(
    '/api/users',
    async (path: string, { arg }: { arg: CreateUserRequest }) => {
      return fetcher(path, commandResponseSchema, {
        method: 'POST',
        body: arg,
      });
    }
  );
}

type Props = {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess: () => void;
};

export function CreateUserDialog({ open, onOpenChange, onSuccess }: Props) {
  const { trigger, isMutating } = useCreateUser();

  const form = useForm<CreateUserRequest>({
    resolver: zodResolver(createUserRequestSchema),
    defaultValues: {
      email: '',
      name: '',
    },
  });

  const onSubmit = async (data: CreateUserRequest) => {
    try {
      await trigger(data);
      toast.success('User created successfully');
      form.reset();
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
        toast.error('Failed to create user');
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
          <DialogTitle>Create New User</DialogTitle>
          <DialogDescription>
            Enter the details for the new user.
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
                {isMutating ? 'Creating...' : 'Create'}
              </Button>
            </DialogFooter>
          </form>
        </Form>
      </DialogContent>
    </Dialog>
  );
}
