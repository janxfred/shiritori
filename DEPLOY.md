# Deploy (FE + BE + DB)

最安構成の前提:

- **Backend:** Cloud Run（コンテナ）
- **Frontend:** Firebase Hosting（静的配信 / `web-frontend/out`）
- **DB:** Supabase Postgres（`DATABASE_URL`）

> 注意: ゲームセッションはインメモリなので、Cloud Run の再起動/スケールでセッションは消えます。

---

## 0) 変数（以降のコマンドで使う）

```bash
export PROJECT_ID=akumateki-shiritori
export REGION=asia-northeast1
export SERVICE_NAME=shiritori-backend
```

---

## 1) DB（Supabase Postgres）

1. Supabase で Project 作成
2. Supabase Dashboard → Project Settings → Database → Connection string（URI）を取得
3. その URI を `DATABASE_URL` として使う

ローカルから Supabase にマイグレーション適用:

```bash
cd backend

export DATABASE_URL='postgresql://...'

npm ci
npm run db:generate
npm run db:migrate:deploy

# 任意（サンプル投入）
# npm run db:seed
```

### うまくいかない場合（`P1001: Can't reach database server`）

ローカルネットワークの制約（IPv6/Outbound 5432 ブロック等）で Supabase の Postgres に到達できないことがあります。

その場合は次のどちらかで回避してください:

1. **Supabase の Pooler 接続文字列**（Dashboard の Connection string で _Session pooler_ 等）を使う

2. **Cloud Run Job でマイグレーションだけ実行**する（ローカルから DB へ直接つながなくてよい）

Cloud Run Job 方式（例）:

```bash
# 1) migration 用イメージを build & push（コンテキストは backend）
docker build \
  -f backend/Dockerfile.migration \
  -t $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-migrate:latest \
  backend

docker push $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-migrate:latest

# 2) Job 作成（DATABASE_URL は Secret Manager 経由推奨）
gcloud run jobs create shiritori-migrate \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-migrate:latest \
  --region $REGION \
  --project $PROJECT_ID \
  --set-secrets DATABASE_URL=shiritori-database-url:latest

# 3) 実行
gcloud run jobs execute shiritori-migrate \
  --region $REGION \
  --project $PROJECT_ID
```

---

## 2) Backend（Cloud Run）

### 2-1) Artifact Registry（初回のみ）

```bash
gcloud artifacts repositories create shiritori \
  --repository-format=docker \
  --location=$REGION \
  --project $PROJECT_ID

gcloud auth configure-docker $REGION-docker.pkg.dev
```

### 2-2) Docker build & push

> ビルドコンテキストはリポジトリルートです（`backend/Dockerfile` が前提）。

```bash
cd .. # リポジトリルート

docker build \
  -f backend/Dockerfile \
  -t $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest \
  .

docker push $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest
```

### 2-3) Cloud Run デプロイ

```bash
gcloud run deploy $SERVICE_NAME \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --set-env-vars NODE_ENV=production \
  --set-env-vars CORS_ALLOW_ALL=true
```

### 2-4) `DATABASE_URL` を Secret Manager 経由で注入（推奨）

```bash
# 初回のみ: Secret 作成
gcloud secrets create shiritori-database-url \
  --replication-policy=automatic \
  --project "$PROJECT_ID"

# 値を追加（ローカル環境変数から流し込み）
printf '%s' "$DATABASE_URL" | gcloud secrets versions add shiritori-database-url \
  --data-file=- \
  --project "$PROJECT_ID"

# Cloud Run に Secret を紐付け（DATABASE_URL として注入）
gcloud run services update $SERVICE_NAME \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --set-secrets DATABASE_URL=shiritori-database-url:latest
```

疎通確認:

- `GET https://shiritori-backend-398307942070.asia-northeast1.run.app/health`
- `GET https://shiritori-backend-398307942070.asia-northeast1.run.app/health/ready`

---

## 3) Frontend（Firebase Hosting）

前提:

- `web-frontend/next.config.ts` は `output: 'export'`（静的出力）
- `web-frontend/firebase.json` の `public` は `out`
- `NEXT_PUBLIC_API_URL` は **ビルド時に埋め込まれる**

### 3-1) Firebase project を指定

どちらか:

- `web-frontend/.firebaserc` を作る（例: `web-frontend/.firebaserc.example` をコピーして編集）
- もしくは `firebase deploy --project <id>` を使う

### 3-2) ビルド → デプロイ

```bash
cd web-frontend
npm ci

NEXT_PUBLIC_API_URL=https://shiritori-backend-398307942070.asia-northeast1.run.app npm run build

npx firebase deploy --project akumateki-shiritori
```

---

## 4) Mobile（Flutter Android）

Flutter は `mobile-client/.env` の `API_BASE_URL` を参照します（デフォルトは Cloud Run）。

ローカルで backend を使いたい場合は `mobile-client/.env.local` を作って上書きしてください。

```dotenv
# Android emulator からホストの backend(3002) へ
API_BASE_URL=http://10.0.2.2:3002
```
