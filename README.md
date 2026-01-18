# 悪魔的しりとり

Next.js + Fastify + Flutter で作る「悪魔的しりとり」プロジェクト。

## プロジェクト構成

```
.
├── backend/          # Fastify バックエンドAPI
├── web-frontend/     # Next.js フロントエンド
├── mobile-client/    # Flutter モバイルアプリ
└── database/         # 開発用DB（docker compose）
```

## 技術スタック

| Backend              | Frontend                | Mobile  |
| -------------------- | ----------------------- | ------- |
| Fastify (TypeScript) | Next.js 15 (App Router) | Flutter |
| Prisma               | Tailwind                | Dio     |
| PostgreSQL           | Zod                     |         |

## クイックスタート

```bash
# 1) DB（必要なら）
cd database
docker compose up -d

# 2) バックエンド（http://localhost:3002）
cd ../backend
npm install
cp .env.example .env
npm run db:generate
npm run db:migrate
npm run dev

# 3) フロントエンド（http://localhost:3000）
cd ../web-frontend
npm install
npm run dev
```

Flutter（Android エミュレータ）から接続する場合は、`mobile-client/lib/core/api/api_client.dart` が `http://10.0.2.2:3002` を使います。

## セキュリティ（機密情報）

- `mobile-client/android/app/google-services.json` は機密情報を含むため **コミット禁止**（`.gitignore`）です。必要な場合は Firebase Console から取得して配置してください。
- ローカルで誤コミットを防ぐには、Git hook を有効化します: `git config core.hooksPath .githooks`
- CI では `scripts/secret-scan.sh` で既知パターン（例: `AIzaSy...`）を検知します。

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

## デプロイ（最安構成）

前提:

- **Backend:** Cloud Run（コンテナ）
- **Frontend:** Firebase Hosting（静的配信）
- **DB（任意）:** Supabase Postgres（ユーザー API 等を使う場合）

注意:

- ゲームセッションはインメモリのため、Cloud Run の再起動/スケールでセッションが消えます。

### Backend（Cloud Run）

Cloud Run の環境変数:

- `NODE_ENV=production`
- `CORS_ALLOW_ALL=true`（Flutter モバイルアプリ向け: CORS で拒否しない）
- `DATABASE_URL=<your-supabase-postgres-url>`（ユーザー API を使う場合）

Supabase の接続文字列は、Supabase Dashboard の **Project Settings → Database → Connection string（URI）** から取得できます。
ユーザー API を使う場合は、先にローカルからマイグレーションを当てておくのが簡単です:

```bash
cd backend
export DATABASE_URL='postgresql://...'
npm install
npm run db:generate
npm run db:migrate:deploy
```

デプロイ例（ローカルから）:

```bash
# 例: Artifact Registry へコンテナをビルドしてから Cloud Run にデプロイ
export PROJECT_ID=<your-gcp-project-id>
export REGION=asia-northeast1

# （初回のみ）Artifact Registry リポジトリ
gcloud artifacts repositories create shiritori \
   --repository-format=docker \
   --location=$REGION

# Docker が使える前提でビルド & push
gcloud auth configure-docker $REGION-docker.pkg.dev

docker build \
   -f backend/Dockerfile \
   -t $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest \
   .

docker push $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest

# デプロイ
gcloud run deploy shiritori-backend \
   --image $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest \
   --region $REGION \
   --allow-unauthenticated \
   --set-env-vars NODE_ENV=production \
   --set-env-vars CORS_ALLOW_ALL=true
```

`DATABASE_URL` はパスワードを含むため、Cloud Run には Secret Manager 経由で設定するのを推奨します。

```bash
export PROJECT_ID=akumateki-shiritori
export REGION=asia-northeast1

# 初回のみ: Secret 作成（値はローカル環境変数から渡す）
gcloud secrets create shiritori-database-url --replication-policy=automatic --project "$PROJECT_ID"
printf '%s' "$DATABASE_URL" | gcloud secrets versions add shiritori-database-url --data-file=- --project "$PROJECT_ID"

# Cloud Run に Secret を紐付け（DATABASE_URL として注入）
gcloud run services update shiritori-backend \
   --region "$REGION" \
   --project "$PROJECT_ID" \
   --set-secrets DATABASE_URL=shiritori-database-url:latest
```

### Frontend（Firebase Hosting）

`NEXT_PUBLIC_API_URL` は **ビルド時に埋め込まれる** ため、デプロイ先 URL でビルドしてください。

```bash
cd web-frontend
npm install

NEXT_PUBLIC_API_URL=https://<your-cloud-run-url> npm run build

# 初回は Firebase プロジェクトを選択/紐付け（どちらか）
# npx firebase use --add

# または --project を指定
npx firebase deploy --project <your-firebase-project-id>
```

## 環境変数

### Backend（`backend/.env`）

- `DATABASE_URL`（PostgreSQL）
- `PORT`（デフォルト `3002`）
- `NODE_ENV`（`development` / `production`）
- `CORS_ORIGIN`（本番時のみ推奨）

### Web Frontend（`web-frontend`）

- `NEXT_PUBLIC_API_URL`（バックエンドのオリジン例: `https://api.example.com`）

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

# 悪魔的しりとり：ルール仕様

このゲームは，単なるしりとりではなく，特殊なルール（「文字の奪い合い」と「禁忌（お手つき）の回避」）が追加されています．

【悪魔的しりとり】
・基本のルールは，普通の 2 人で行うしりとり．
・当然，名詞のみ使用可能で，固有名詞は使用不可（但し，地名と建物名は使用可能．人名は不可）．
・当然，一度使用した単語は，再使用不可．

〜ここからが，特殊ルール〜
・全ての文字の内，相手より先に使用した文字を，各プレイヤーは｢確保｣できる．確保した文字は，確保したプレイヤーのみ何度でも使える．
・相手が確保した文字は使えない．但し，語句の最初の文字に限り，｢確保された文字が使えないルール｣は適用されない．
・濁点，半濁点，伸ばし棒は固有の文字とするが，小さい文字（ょ等）は大きい文字と同一と見なす．
・末尾が伸ばし棒の語句は，その一字前を頭文字とする．例えば，プレイヤー A が｢ルビー｣と言った場合，プレイヤー B は｢び｣から始まる語句で返答する必要がある．
・末尾が小さい文字の語句は，その小さい文字を大きい文字にして，頭文字とする．例えば，プレイヤー A が｢じしょ｣と言った場合，プレイヤー B は｢よ｣から始まる語句を送信する必要がある．

## 1. 基本制約

- 全ての入出力は「ひらがな」のみで行う．
- 有効な単語は `shiritori_list.json` に存在するもののみとする（現状の実装）。

## 2. 判定フロー（お手つき/Mistake の定義）

以下のいずれかに該当した場合，そのターンの入力は「お手つき」となり，送信者の累積お手つき回数を+1 する．

- 【ルール A：んの禁忌】: 単語の末尾が「ん」で終わる．
- 【ルール B：確保文字の禁忌】:
  - 単語を $c_1, c_2, \dots, c_n$ （各文字）としたとき，$c_2$ から $c_n$ までの文字の中に，既に「確保済み文字（CapturedCharacters）」に含まれる文字が 1 つでもある場合．
  - ※重要：1 文字目（頭文字 $c_1$）が確保済みであっても，それは使用可能（ノーカウント）とする．
- 【ルール C：存在の否定】: 辞書テーブルに存在しない，または名詞ではない単語．

## 3. 勝利・敗北条件

- 【即時敗北】: いずれかのプレイヤーの累積お手つきが「2 回」に達した瞬間，または持ち時間を使い切った瞬間，そのプレイヤーが即座に敗北となる．
- 【ターン満了時（10 ラウンド終了等）】: 確保した文字数が多いプレイヤーが敗北となる（＝文字確保数が少ない方が勝利）．

## 4. 文字確保（Capture）の処理

- お手つきにならず受理された単語の「2 文字目以降の構成文字全て」は，送信者の「確保文字」として DB に登録される．

# アーキテクチャ指示

1. Domain Layer:
   - `Game` エンティティ: `mistakeCount`, `status` を管理．
   - `ShiritoriJudgeService`: 禁忌判定ロジックを純粋関数として実装．
   - `AiBrainService`: アルゴリズムに基づいた次の一手を計算．
2. Infrastructure Layer:
   - `DictionaryRepository`: `shiritori_list.json` から辞書ロード + 前方一致検索（現状の実装）。
   - `GameSessionStore`: インメモリのセッション管理（現状の実装）。
3. Application Layer:
   - `ProcessTurnUseCase`: ユーザー送信 → 判定 → 確保 → AI 思考 → 台詞選択 → DB 更新 を一連のトランザクションで実行．

# UI 要求

- 色彩: #1E1E1E (漆黒), #3D0000 (真紅), #D4AF37 (金) を基調とする．
- 世界観: 羊皮紙のテクスチャ，魔法陣のアニメーション，金属光沢のあるボタンなど，ゴシックでミステリアスな UI を Tailwind CSS で表現せよ．
