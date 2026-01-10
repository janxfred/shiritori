# Web Frontend Template

開発合宿用のNext.jsフロントエンドテンプレート

## 技術スタック

- **Framework:** Next.js 15.x (App Router)
- **Language:** TypeScript 5.x
- **Data Fetching:** SWR 2.x
- **Validation:** Zod
- **UI:** shadcn/ui + Tailwind CSS 4.x
- **Form:** React Hook Form 7.x

## セットアップ

```bash
# 依存関係のインストール
npm install

# 開発サーバー起動
npm run dev
```

## ディレクトリ構成

```
web-frontend/
├── src/
│   ├── app/
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── page.tsx              # /usersへリダイレクト
│   │   └── users/
│   │       ├── page.tsx          # ユーザー一覧ページ
│   │       ├── _components/      # 一覧ページ専用コンポーネント
│   │       │   ├── UserListHeader.tsx
│   │       │   ├── UserListTable.tsx
│   │       │   ├── UserListEmptyState.tsx
│   │       │   ├── UserListPagination.tsx
│   │       │   └── CreateUserDialog.tsx
│   │       └── [userId]/
│   │           ├── page.tsx      # ユーザー詳細ページ
│   │           └── _components/  # 詳細ページ専用コンポーネント
│   │               ├── UserDetailHeader.tsx
│   │               ├── UserInfoCard.tsx
│   │               ├── EditUserDialog.tsx
│   │               └── DeleteUserDialog.tsx
│   ├── components/ui/            # shadcn/ui コンポーネント
│   ├── lib/
│   │   ├── utils.ts              # cn() ユーティリティ
│   │   ├── fetcher.ts            # SWRフェッチャー（Zod検証付き）
│   │   └── api-error.ts          # APIエラークラス
│   └── schemas/
│       ├── error-response.schema.ts
│       ├── pagination.schema.ts
│       └── user/
│           ├── user.schema.ts
│           ├── list-users.schema.ts
│           ├── get-user.schema.ts
│           ├── create-user.schema.ts
│           ├── update-user.schema.ts
│           ├── delete-user.schema.ts
│           └── command-response.schema.ts
├── .env.local                    # 環境変数
└── package.json
```

## 設計規約

### 1. ページ専用コンポーネント（_components）

各ページは自身の `_components/` ディレクトリを持ち、そのページ専用のコンポーネントを配置する。コンポーネントは共有せず、ページごとに専用化することで変更の影響範囲を限定する。

```
app/users/
├── page.tsx
└── _components/
    ├── UserListHeader.tsx    # このページでのみ使用
    ├── UserListTable.tsx
    └── CreateUserDialog.tsx
```

### 2. スキーマ駆動Props

コンポーネントのPropsはZodスキーマから型推論した型を使用する。

```typescript
// schemas/user/user.schema.ts
export const userSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  name: z.string(),
  createdAt: z.string(),
  updatedAt: z.string(),
});
export type User = z.infer<typeof userSchema>;

// _components/UserInfoCard.tsx
import type { User } from '@/schemas/user/user.schema';

type Props = {
  user: User;  // スキーマから型推論
};

export function UserInfoCard({ user }: Props) {
  // ...
}
```

### 3. SWRフックはコンポーネントと同じファイルに定義

データ取得用のSWRフックは、それを使用するコンポーネントと同じファイル内に定義する。フックを別ファイルに分離しない。

```typescript
// app/users/page.tsx
'use client';

import useSWR from 'swr';
import { createSwrFetcher } from '@/lib/fetcher';
import { listUsersResponseSchema } from '@/schemas/user/list-users.schema';

// フックはコンポーネントと同じファイル内に定義
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
  const { data, isLoading, mutate } = useUsers({ page: 1, limit: 20 });
  // ...
}
```

### 4. Mutation用フックもコンポーネントと同じファイルに定義

`useSWRMutation` を使用するMutation用フックも、それを使用するダイアログコンポーネントと同じファイル内に定義する。

```typescript
// _components/CreateUserDialog.tsx
'use client';

import useSWRMutation from 'swr/mutation';
import { fetcher } from '@/lib/fetcher';
import { createUserRequestSchema, commandResponseSchema } from '@/schemas/user/create-user.schema';

// フックはコンポーネントと同じファイル内に定義
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

export function CreateUserDialog({ open, onOpenChange, onSuccess }: Props) {
  const { trigger, isMutating } = useCreateUser();
  // ...
}
```

### 5. 書き込み系APIのレスポンスはcommandResponseSchema

POST/PUT/DELETEなどの書き込み系APIのレスポンスは統一して `commandResponseSchema` を使用する。

```typescript
// schemas/user/command-response.schema.ts
export const commandResponseSchema = z.object({
  message: z.string(),
});
export type CommandResponse = z.infer<typeof commandResponseSchema>;

// 各スキーマファイルで再エクスポート
// schemas/user/create-user.schema.ts
export { commandResponseSchema };
```

### 6. fetcher関数の使い方

#### 読み取り（SWR）

```typescript
import useSWR from 'swr';
import { createSwrFetcher } from '@/lib/fetcher';

function useUser(userId: string) {
  return useSWR(
    `/api/users/${userId}`,
    createSwrFetcher(getUserResponseSchema)
  );
}
```

#### 書き込み（SWR Mutation）

```typescript
import useSWRMutation from 'swr/mutation';
import { fetcher } from '@/lib/fetcher';

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
```

### 7. エラーハンドリング

```typescript
import { ApiError } from '@/lib/api-error';
import { toast } from 'sonner';

const onSubmit = async (data: CreateUserRequest) => {
  try {
    await trigger(data);
    toast.success('User created successfully');
    onSuccess();
  } catch (error) {
    if (error instanceof ApiError) {
      // 409 Conflict の場合はフォームエラーとして表示
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
```

### 8. フォームバリデーション

React Hook FormとZodを組み合わせて使用する。

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { createUserRequestSchema, type CreateUserRequest } from '@/schemas/user/create-user.schema';

const form = useForm<CreateUserRequest>({
  resolver: zodResolver(createUserRequestSchema),
  defaultValues: {
    email: '',
    name: '',
  },
});
```

## 新しいページを追加する

### 1. スキーマを定義

```bash
src/schemas/product/
├── product.schema.ts           # エンティティスキーマ
├── list-products.schema.ts     # 一覧取得
├── get-product.schema.ts       # 詳細取得
├── create-product.schema.ts    # 作成
├── update-product.schema.ts    # 更新
└── delete-product.schema.ts    # 削除
```

### 2. ページを作成

```bash
src/app/products/
├── page.tsx                    # 一覧ページ
├── _components/
│   ├── ProductListHeader.tsx
│   ├── ProductListTable.tsx
│   ├── ProductListEmptyState.tsx
│   ├── ProductListPagination.tsx
│   └── CreateProductDialog.tsx
└── [productId]/
    ├── page.tsx                # 詳細ページ
    └── _components/
        ├── ProductDetailHeader.tsx
        ├── ProductInfoCard.tsx
        ├── EditProductDialog.tsx
        └── DeleteProductDialog.tsx
```

### 3. 実装パターン

1. `page.tsx` にSWRフックとページコンポーネントを実装
2. 各 `_components/*.tsx` にUIコンポーネントを実装
3. ダイアログコンポーネントにはMutationフックを含める

## スクリプト

| Script | Description |
|--------|-------------|
| `npm run dev` | 開発サーバー起動（ポート3000） |
| `npm run build` | プロダクションビルド |
| `npm run start` | プロダクションサーバー起動 |
| `npm run lint` | Lintチェック |

## 環境変数

```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:3002
```
