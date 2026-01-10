# Web Application Template for Mid-Camp

開発合宿用のWebアプリケーションテンプレート

## プロジェクト構成

```
.
├── backend/          # Fastify バックエンドAPI
└── web-frontend/     # Next.js フロントエンド
```

## 技術スタック

| Backend | Frontend |
|---------|----------|
| Fastify | Next.js 15 (App Router) |
| Prisma | SWR |
| Zod | shadcn/ui + Tailwind |
| MySQL | React Hook Form |

## クイックスタート

```bash
# バックエンド
cd backend && npm install
npm run db:generate
npm run db:migrate
npm run dev  # ポート3002

# フロントエンド
cd web-frontend && npm install
npm run dev  # ポート3000
```

## よく使うコマンド

### Backend

```bash
npm run dev           # 開発サーバー
npm run db:generate   # Prismaクライアント生成
npm run db:migrate    # マイグレーション
npm run db:seed       # シードデータ
```

### Frontend

```bash
npm run dev    # 開発サーバー
npm run build  # ビルド
```

## API ドキュメント

http://localhost:3002/docs

---

## Kiro 仕様駆動開発

`/kiro` コマンドで仕様からコードを生成できます。
続くコマンドは、各コマンドの出力結果に含まれています。

```bash
/kiro:spec-init <feature-name>       # 仕様作成
```

## サンプル実装

`backend/` と `web-frontend/` にはユーザー管理のサンプル実装が含まれています。新しい機能を追加する際の参考にしてください。

- [Backend README](./backend/README.md) - バックエンドの設計規約
- [Frontend README](./web-frontend/README.md) - フロントエンドの設計規約
