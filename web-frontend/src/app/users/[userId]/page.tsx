"use client";

import { use, useState } from "react";
import { useRouter } from "next/navigation";
import useSWR from "swr";
import { createSwrFetcher } from "@/lib/fetcher";
import { getUserResponseSchema } from "@/schemas/user/get-user.schema";
import { UserDetailHeader } from "./_components/UserDetailHeader";
import { UserInfoCard } from "./_components/UserInfoCard";
import { EditUserDialog } from "./_components/EditUserDialog";
import { DeleteUserDialog } from "./_components/DeleteUserDialog";
import { Skeleton } from "@/components/ui/skeleton";
import { Card, CardContent } from "@/components/ui/card";

function useUser(userId: string | null) {
  return useSWR(
    userId ? `/api/users/${userId}` : null,
    createSwrFetcher(getUserResponseSchema),
    {
      revalidateOnFocus: false,
    }
  );
}

type Props = {
  params: Promise<{ userId: string }>;
};

export default function UserDetailPage({ params }: Props) {
  const { userId } = use(params);
  const router = useRouter();
  const { data: user, isLoading, mutate } = useUser(userId);

  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);

  const handleEditSuccess = () => {
    setEditDialogOpen(false);
    mutate();
  };

  const handleDeleteSuccess = () => {
    setDeleteDialogOpen(false);
    router.push("/users");
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-background">
        <div className="h-16 border-b" />
        <main className="container mx-auto px-6 py-8">
          <Card>
            <CardContent className="pt-6">
              <Skeleton className="h-48 w-full" />
            </CardContent>
          </Card>
        </main>
      </div>
    );
  }

  if (!user) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <p className="text-muted-foreground">User not found</p>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      <UserDetailHeader
        user={user}
        onEditClick={() => setEditDialogOpen(true)}
        onDeleteClick={() => setDeleteDialogOpen(true)}
      />

      <main className="container mx-auto px-6 py-8">
        <UserInfoCard user={user} />
      </main>

      <EditUserDialog
        user={user}
        open={editDialogOpen}
        onOpenChange={setEditDialogOpen}
        onSuccess={handleEditSuccess}
      />

      <DeleteUserDialog
        user={user}
        open={deleteDialogOpen}
        onOpenChange={setDeleteDialogOpen}
        onSuccess={handleDeleteSuccess}
      />
    </div>
  );
}
