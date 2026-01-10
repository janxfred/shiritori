# Backend Coding Guidelines

## Design Principles

### シンプルさを最優先
- 過剰な抽象化をしない
- 必要になるまで機能を追加しない
- 1つのファイルで完結できるなら分割しない

### バリデーション方針
- IDのフォーマットバリデーション（uuid等）は不要
- 存在チェックはDB問い合わせで行う
- バリデーションは最小限に（必須チェック、型チェック程度）

### エラーハンドリング
- 存在しないリソースは404
- 重複は409
- バリデーションエラーはZodが自動で400を返す

## Directory Structure

```
src/
├── main.ts           # エントリポイント
├── database.ts       # Prismaシングルトン
├── model/            # ドメインモデル（Zodスキーマ）
├── lib/              # 共通ユーティリティ
└── controller/       # APIエンドポイント
    └── {resource}/
        ├── controller.ts
        ├── schema.ts
        └── _{param}/
            ├── controller.ts
            └── schema.ts
```

## Coding Rules

### Import
- index.ts禁止（バレルエクスポートしない）
- 直接ファイルをimport: `from "../../lib/pagination"`
- 拡張子なし

### Schema
- 各controller階層に`schema.ts`を配置
- `model/`は純粋なドメインモデルのみ
- Zod 4: `z.string()`, `z.email()`, `z.number()`
- `z.uuid()`は使わない

```typescript
// schema.ts
export const userResponseSchema = z.object({
  id: z.string(),
  email: z.email(),
  name: z.string(),
});

export const createUserRequestSchema = z.object({
  email: z.email(),
  name: z.string().min(1).max(100),
});
```

### Controller
- fastify-autoloadで自動ロード
- `_`プレフィックスディレクトリ → URLパラメータ (`_userId/` → `/:userId`)
- 1ファイル1リソース操作

```typescript
export default async function (fastify: ServerInstance) {
  fastify.get("/", { schema: {...} }, async (request, reply) => {
    // implementation
  });
}
```

### Comments
- 自明なコメントは書かない
- JSDoc不要
- 複雑なロジックのみコメント

### Naming
```typescript
// Schema: {action}{Resource}{Type}Schema
listUsersQuerySchema
createUserRequestSchema
userResponseSchema

// Type: スキーマからinfer
type CreateUserRequest = z.infer<typeof createUserRequestSchema>
```

## Don'ts

- ヘルパー関数の過剰な抽象化
- 使われていないコードを残す
- 将来のための事前設計
- IDのフォーマットバリデーション
- 過剰なエラーハンドリング
