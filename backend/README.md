# Backend Template

開発合宿用のFastifyバックエンドテンプレート

## 技術スタック

- **Framework:** Fastify 4.x
- **Language:** TypeScript 5.x
- **ORM:** Prisma 5.x
- **Validation:** Zod
- **Database:** MySQL

## セットアップ

```bash
# 依存関係のインストール
npm install

# Prismaクライアント生成
npm run db:generate

# データベースマイグレーション
npm run db:migrate

# 開発サーバー起動
npm run dev
```

## ディレクトリ構成

```
backend/
├── src/
│   ├── controller/     # APIルート定義
│   │   └── user/       # ユーザーAPI例
│   │       ├── controller.ts
│   │       ├── schema.ts
│   │       └── _userId/  # パラメータルート
│   │           ├── controller.ts
│   │           └── hook.ts
│   ├── model/          # Zodスキーマ定義
│   ├── lib/            # ユーティリティ
│   ├── main.ts         # エントリーポイント
│   └── database.ts     # Prismaクライアント
├── prisma/
│   ├── schema.prisma   # データベーススキーマ
│   └── seed/           # シードデータ
└── package.json
```

## API エンドポイント

### User API

| Method | Path | Description |
|--------|------|-------------|
| GET | /api/user | ユーザー一覧取得 |
| GET | /api/user/:userId | ユーザー詳細取得 |
| POST | /api/user | ユーザー作成 |
| PUT | /api/user/:userId | ユーザー更新 |
| DELETE | /api/user/:userId | ユーザー削除 |

## 開発ガイド

### 新しいAPIを追加する

1. `src/model/` にZodスキーマを追加
2. `src/controller/` にディレクトリを作成
3. `schema.ts` でAPIスキーマを定義
4. `controller.ts` でハンドラーを実装
5. 必要に応じて `hook.ts` でpreHandlerを追加

### RORO原則

全ての関数はオブジェクト形式で引数を受け取り、オブジェクト形式で返す:

```typescript
// Good
function calculatePagination(params: { page: number; limit: number }): { skip: number; take: number } {
  const { page, limit } = params
  return { skip: (page - 1) * limit, take: limit }
}

// Bad
function calculatePagination(page: number, limit: number): [number, number] {
  return [(page - 1) * limit, limit]
}
```

## スクリプト

| Script | Description |
|--------|-------------|
| `npm run dev` | 開発サーバー起動 |
| `npm run build` | TypeScriptビルド |
| `npm run db:generate` | Prismaクライアント生成 |
| `npm run db:migrate` | マイグレーション実行 |
| `npm run db:seed` | シードデータ投入 |
| `npm run lint` | Lintチェック |
| `npm run lint:fix` | Lint自動修正 |

## API ドキュメント

開発環境では `/docs` でSwagger UIにアクセス可能
