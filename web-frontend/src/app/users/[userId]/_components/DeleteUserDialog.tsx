'use client';

import useSWRMutation from 'swr/mutation';
import { toast } from 'sonner';
import type { User } from '@/schemas/user/user.schema';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';
import { fetcher } from '@/lib/fetcher';
import { commandResponseSchema } from '@/schemas/user/delete-user.schema';
import { ApiError } from '@/lib/api-error';

function useDeleteUser(userId: string) {
  return useSWRMutation(`/api/users/${userId}`, async (path: string) => {
    return fetcher(path, commandResponseSchema, {
      method: 'DELETE',
    });
  });
}

type Props = {
  user: User;
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess: () => void;
};

export function DeleteUserDialog({
  user,
  open,
  onOpenChange,
  onSuccess,
}: Props) {
  const { trigger, isMutating } = useDeleteUser(user.id);

  const handleDelete = async () => {
    try {
      await trigger();
      toast.success('User deleted successfully');
      onSuccess();
    } catch (error) {
      if (error instanceof ApiError) {
        toast.error(error.message);
      } else {
        toast.error('Failed to delete user');
      }
    }
  };

  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>Delete User</AlertDialogTitle>
          <AlertDialogDescription>
            Are you sure you want to delete &quot;{user.name}&quot;? This action
            cannot be undone.
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>Cancel</AlertDialogCancel>
          <AlertDialogAction
            onClick={handleDelete}
            disabled={isMutating}
            className='bg-destructive text-destructive-foreground hover:bg-destructive/90'
          >
            {isMutating ? 'Deleting...' : 'Delete'}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
}
