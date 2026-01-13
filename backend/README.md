# Backend

Fastify 製のバックエンド API。

## 技術スタック

- **Framework:** Fastify 5.x
- **Language:** TypeScript 5.x
- **ORM:** Prisma 6.x
- **Validation:** Zod
- **Database:** PostgreSQL

## このリポジトリでの役割

- ゲーム API（`/api/game/*`）: インメモリのセッション（`src/infrastructure/GameSessionStore.ts`） + `shiritori_list.json` の辞書で動作
- ユーザー API（`/api/users`）: Prisma + PostgreSQL のサンプル実装（`DATABASE_URL` が必要。未設定の場合は 503 を返します）

## セットアップ

```bash
# 依存関係のインストール
npm install

# 環境変数（例から作成）
cp .env.example .env

# Prismaクライアント生成
npm run db:generate

# データベースマイグレーション
npm run db:migrate

# 開発サーバー起動
npm run dev

# ファイル変更を監視して自動再起動したい場合
npm run dev:watch
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

| Method | Path              | Description      |
| ------ | ----------------- | ---------------- |
| GET    | /api/user         | ユーザー一覧取得 |
| GET    | /api/user/:userId | ユーザー詳細取得 |
| POST   | /api/user         | ユーザー作成     |
| PUT    | /api/user/:userId | ユーザー更新     |
| DELETE | /api/user/:userId | ユーザー削除     |

## 開発ガイド

### 新しい API を追加する

1. `src/model/` に Zod スキーマを追加
2. `src/controller/` にディレクトリを作成
3. `schema.ts` で API スキーマを定義
4. `controller.ts` でハンドラーを実装
5. 必要に応じて `hook.ts` で preHandler を追加

### RORO 原則

全ての関数はオブジェクト形式で引数を受け取り、オブジェクト形式で返す:

```typescript
// Good
function calculatePagination(params: { page: number; limit: number }): {
  skip: number;
  take: number;
} {
  const { page, limit } = params;
  return { skip: (page - 1) * limit, take: limit };
}

// Bad
function calculatePagination(page: number, limit: number): [number, number] {
  return [(page - 1) * limit, limit];
}
```

## スクリプト

| Script                | Description             |
| --------------------- | ----------------------- |
| `npm run dev`         | 開発サーバー起動        |
| `npm run build`       | TypeScript ビルド       |
| `npm run db:generate` | Prisma クライアント生成 |
| `npm run db:migrate`  | マイグレーション実行    |
| `npm run db:seed`     | シードデータ投入        |
| `npm run lint`        | Lint チェック           |
| `npm run lint:fix`    | Lint 自動修正           |

## API ドキュメント

開発環境では `/docs` で Swagger UI にアクセス可能

## 環境変数

`backend/.env.example` を参照してください。

## デプロイ（Cloud Run）

このプロジェクトは `backend/Dockerfile` を Cloud Run 用に用意しています。

- Docker build はリポジトリルートをコンテキストにして実行してください（例: `docker build -f backend/Dockerfile .`）
- `shiritori_list.json` はコンテナ内に同梱され、ゲーム API の辞書として使われます

本番で推奨する環境変数:

- `NODE_ENV=production`
- `CORS_ALLOW_ALL=true`（Flutter モバイルアプリ向け: CORS で拒否しない）
- `DATABASE_URL=<supabase-postgres-url>`（ユーザー API を使う場合）

`DATABASE_URL` はパスワードを含むため、Cloud Run には Secret Manager 経由で設定するのを推奨します。

### Supabase（Postgres）にマイグレーションを当てる

ユーザー API を使う場合、Supabase 側にテーブルを作る必要があります。

```bash
cd backend

# Supabase の接続文字列（Settings -> Database -> Connection string）を設定
export DATABASE_URL='postgresql://...'

npm install
npm run db:generate
npm run db:migrate:deploy

# 任意（サンプルユーザー投入）
npm run db:seed
```
