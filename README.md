# 悪魔的しりとり

Next.js + Fastify + Flutter で作る「悪魔的しりとり」プロジェクト。

## プロジェクト構成

```
.
├── backend/          # Fastify バックエンドAPI (Cloud Run)
├── web-frontend/     # Next.js フロントエンド (Firebase Hosting)
├── mobile-client/    # Flutter モバイルアプリ (Google Play / App Store)
└── database/         # 開発用DB（docker compose）
```

## 技術スタック

| Backend              | Frontend                | Mobile  | Infrastructure        |
| -------------------- | ----------------------- | ------- | --------------------- |
| Fastify (TypeScript) | Next.js 15 (App Router) | Flutter | Cloud Run (BE)        |
| Prisma               | Tailwind                | Dio     | Firebase Hosting (FE) |
| PostgreSQL           | Zod                     |         | Supabase (PostgreSQL) |
| Redis                |                         |         | Secret Manager        |

インフラ構成サマリー  
 ┌───────────────────┬────────────────┬──────────────────────────────┐  
 │ サービス　 　 │ 用途 │ 技術 　　　　　　　　　　　　　　 │  
 ├───────────────────┼────────────────┼──────────────────────────────┤  
 │ Backend 　 　 │ REST API │ Cloud Run (Fastify + Prisma) │  
 ├───────────────────┼────────────────┼──────────────────────────────┤  
 │ Frontend(Web) │ 静的サイト │ Firebase Hosting (Next.js) │  
 ├───────────────────┼────────────────┼──────────────────────────────┤  
 │ Frontend (Mobile) │ Android/iOS │ Flutter │  
 ├───────────────────┼────────────────┼──────────────────────────────┤  
 │ Database │ PostgreSQL 　　 │ Supabase │  
 ├───────────────────┼────────────────┼──────────────────────────────┤  
 │ Secret管理 │ DATABASE_URL等 │ Google Secret Manager │  
 ├───────────────────┼────────────────┼──────────────────────────────┤  
 │ イメージ保管 │ Docker 　　　　　│ Artifact Registry │  
 ├───────────────────┼────────────────┼──────────────────────────────┤  
 │ キャッシュ │ セッション 　　 │ Redis (Memorystore) │  
 └───────────────────┴────────────────┴──────────────────────────────┘

---

## インフラ構成（本番環境）

```
┌─────────────────────────────────────────────────────┐
│              INTERNET / クライアント                  │
└──────────────────┬──────────────────────────────────┘
                   │
      ┌────────────┼────────────┐
      │            │            │
      ▼            ▼            ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Web FE   │  │ Mobile   │  │  Admin   │
│(Firebase │  │(Flutter) │  │  Panel   │
│ Hosting) │  │ Android  │  │          │
└────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │             │
     └─────────────┼─────────────┘
                   │ HTTPS
                   ▼
        ┌──────────────────────┐
        │   Cloud Run Backend  │
        │   (Port 8080)        │
        │                      │
        │ - Fastify Server     │
        │ - Prisma ORM         │
        │ - Zod Validation     │
        │ - Redis Client       │
        └──────────┬───────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
    ┌─────────┐          ┌────────┐
    │ Supabase│          │  Redis │
    │ Postgres│          │(Memory-│
    │ DB      │          │ store) │
    └─────────┘          └────────┘
```

### サービス一覧

| サービス                | 役割                          | URL / 備考                                                     |
| ----------------------- | ----------------------------- | -------------------------------------------------------------- |
| **Cloud Run**           | Backend API                   | `https://shiritori-backend-xxx.asia-northeast1.run.app`        |
| **Firebase Hosting**    | Web Frontend (静的配信)       | `https://akumateki-shiritori.web.app`                          |
| **Supabase**            | PostgreSQL Database           | Dashboard → Project Settings → Database                        |
| **Secret Manager**      | DATABASE_URL 等の機密情報管理 | `shiritori-database-url`                                       |
| **Artifact Registry**   | Docker イメージ保管           | `asia-northeast1-docker.pkg.dev/akumateki-shiritori/shiritori` |
| **Google Play Console** | Android アプリ配信            | `mobile-client/` からビルド                                    |

### 重要な注意事項

- **ゲームセッションはインメモリ**: Cloud Run の再起動/スケール時にセッションが消失します
- **ステートレス設計**: ゲーム結果のみ DB に永続化
- **CORS**: モバイルアプリ向けに `CORS_ALLOW_ALL=true` を設定

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

## トラブルシューティング

### 1. Docker / Rancher Desktop 関連

このプロジェクトでは **Rancher Desktop** を使用してDockerコンテナを管理しています。

#### 問題: "Cannot connect to the Docker daemon" エラー

**症状:**

```
Cannot connect to the Docker daemon at unix:///Users/xxx/.rd/docker.sock. Is the docker daemon running?
```

**解決方法:**

1. Rancher Desktopが起動しているか確認

   ```bash
   ps aux | grep -i rancher | grep -v grep
   ```

2. Rancher Desktopのバックエンド状態を確認

   ```bash
   /Applications/Rancher\ Desktop.app/Contents/Resources/resources/darwin/bin/rdctl api /v1/backend_state
   ```

   もし `{"vmState":"DISABLED"}` なら、バックエンドを起動：

   ```bash
   /Applications/Rancher\ Desktop.app/Contents/Resources/resources/darwin/bin/rdctl api /v1/backend_state -X PUT -b '{"vmState":"STARTED"}'
   ```

3. GUIから起動する場合
   - Rancher Desktopアプリを開く
   - 左メニューから「Containers」をクリック
   - コンテナエンジンが自動起動します

4. データベースコンテナを起動

   ```bash
   cd database
   docker compose up -d
   ```

5. コンテナが起動したか確認
   ```bash
   docker compose ps
   # または
   docker ps
   ```

### 2. バックエンド接続エラー

#### 問題: "Connection refused" または "Bad state" エラー

**症状:**

- モバイルアプリから「ログインに失敗しました: Bad state: The connection errored」
- 「ゲーム開始エラー: Connection refused」

**原因と解決方法:**

1. **データベースが起動していない**

   ```bash
   cd database
   docker compose ps
   # redis-1とpostgres-1がUP状態であることを確認

   # 起動していない場合
   docker compose up -d
   ```

2. **バックエンドサーバーが起動していない**

   ```bash
   # ポート3002で起動しているか確認
   lsof -i :3002

   # 何も表示されない場合は起動
   cd backend
   npm run dev
   ```

3. **既存プロセスがポートを占有している**

   ```bash
   # 既存プロセスを終了
   lsof -ti :3002 | xargs kill -9

   # 再起動
   cd backend
   npm run dev
   ```

4. **Prismaクライアントが最新でない**
   ```bash
   cd backend
   npx prisma generate
   npm run dev
   ```

### 3. 起動確認チェックリスト

すべてが正常に動作しているか確認：

```bash
# 1. Dockerが起動しているか
docker ps

# 2. データベースコンテナが起動しているか
cd database && docker compose ps
# Expected: redis-1 (Up), postgres-1 (Up)

# 3. バックエンドが起動しているか
lsof -i :3002
# Expected: node process on port 3002

curl http://127.0.0.1:3002/
# Expected: {"message":"Route GET:/ not found",...}

# 4. (Optional) フロントエンドが起動しているか
lsof -i :3000
curl http://localhost:3000/
```

### 4. 完全リセット手順

すべてがうまくいかない場合の完全リセット：

```bash
# 1. すべてのプロセスを停止
pkill -f "tsx src/main.ts"
pkill -f "next dev"

# 2. Dockerコンテナを停止・削除
cd database
docker compose down -v

# 3. Rancher Desktopを再起動
/Applications/Rancher\ Desktop.app/Contents/Resources/resources/darwin/bin/rdctl shutdown
sleep 10
open -a "Rancher Desktop"
# GUIが起動するまで待つ（約30秒）

# 4. コンテナエンジンを起動
/Applications/Rancher\ Desktop.app/Contents/Resources/resources/darwin/bin/rdctl api /v1/backend_state -X PUT -b '{"vmState":"STARTED"}'
sleep 20

# 5. データベースを起動
cd database
docker compose up -d

# 6. バックエンドを起動
cd ../backend
npm run dev

# 7. モバイルアプリを再起動
cd ../mobile-client
flutter run
```

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

---

## デプロイ手順

> 詳細は [DEPLOY.md](./DEPLOY.md) を参照してください。

### 共通: 環境変数の設定

```bash
export PROJECT_ID=akumateki-shiritori
export REGION=asia-northeast1
export SERVICE_NAME=shiritori-backend
```

---

### 1. Database（Supabase マイグレーション）

```bash
cd backend

# Supabase Dashboard → Project Settings → Database → Connection string (URI) を取得
export DATABASE_URL='postgresql://...'

npm ci
npm run db:generate
npm run db:migrate:deploy

# 任意: シードデータ投入
npm run db:seed
```

> **トラブルシューティング**: ローカルから接続できない場合は Supabase の Pooler 接続文字列を使用するか、Cloud Run Job でマイグレーションを実行してください（[DEPLOY.md](./DEPLOY.md) 参照）。

---

### 2. Backend（Cloud Run）

#### 2-1. Docker イメージのビルド & プッシュ

```bash
# リポジトリルートで実行
cd /path/to/shiritori

# Docker認証（初回のみ）
gcloud auth configure-docker $REGION-docker.pkg.dev

# ビルド（コンテキストはリポジトリルート）
docker build \
  -f backend/Dockerfile \
  -t $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest \
  .

# プッシュ
docker push $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest
```

#### 2-2. Cloud Run デプロイ

```bash
gcloud run deploy $SERVICE_NAME \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --set-env-vars NODE_ENV=production \
  --set-env-vars CORS_ALLOW_ALL=true
```

#### 2-3. DATABASE_URL を Secret Manager 経由で注入（推奨）

```bash
# 初回のみ: Secret 作成
gcloud secrets create shiritori-database-url \
  --replication-policy=automatic \
  --project "$PROJECT_ID"

# 値を追加
printf '%s' "$DATABASE_URL" | gcloud secrets versions add shiritori-database-url \
  --data-file=- \
  --project "$PROJECT_ID"

# Cloud Run に紐付け
gcloud run services update $SERVICE_NAME \
  --region "$REGION" \
  --project "$PROJECT_ID" \
  --set-secrets DATABASE_URL=shiritori-database-url:latest
```

#### 疎通確認

```bash
curl https://shiritori-backend-xxx.asia-northeast1.run.app/health
curl https://shiritori-backend-xxx.asia-northeast1.run.app/health/ready
```

---

### 3. Frontend（Firebase Hosting）

```bash
cd web-frontend
npm ci

# API URLをビルド時に埋め込み
NEXT_PUBLIC_API_URL=https://shiritori-backend-xxx.asia-northeast1.run.app npm run build

# デプロイ
npx firebase deploy --project akumateki-shiritori
```

> **注意**: `NEXT_PUBLIC_API_URL` はビルド時に埋め込まれるため、本番 URL を指定してビルドしてください。

---

### 4. Mobile（Flutter Android → Google Play）

#### 4-1. 環境変数の設定

```bash
cd mobile-client

# 本番用 .env を作成
cp .env.example .env

# .env を編集して本番APIを指定
# API_BASE_URL=https://shiritori-backend-xxx.asia-northeast1.run.app
```

#### 4-2. Firebase 設定ファイルの配置

```bash
# Firebase Console → プロジェクト設定 → Android アプリ から google-services.json をダウンロード
# 以下のパスに配置（.gitignore に含まれているためコミット禁止）
cp ~/Downloads/google-services.json mobile-client/android/app/google-services.json
```

#### 4-3. 署名キーの準備（初回のみ）

```bash
cd mobile-client/android

# キーストア作成（初回のみ）
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload

# key.properties を作成
cat > key.properties << 'EOF'
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=../upload-keystore.jks
EOF
```

#### 4-4. リリースビルド

```bash
cd mobile-client

# App Bundle (Google Play 推奨)
flutter build appbundle --release

# 出力先: build/app/outputs/bundle/release/app-release.aab

# または APK
flutter build apk --release
# 出力先: build/app/outputs/flutter-apk/app-release.apk
```

#### 4-5. Google Play Console へアップロード

1. [Google Play Console](https://play.google.com/console) にアクセス
2. アプリを作成（初回）または既存アプリを選択
3. **リリース** → **本番** → **新しいリリースを作成**
4. `app-release.aab` をアップロード
5. リリースノートを記入して審査に提出

> **重要**: 初回リリースでは、プライバシーポリシー URL、コンテンツレーティング、ストア掲載情報（スクリーンショット等）の設定が必要です。

---

## コード修正時のデプロイフロー

### Backend を修正した場合

```bash
# 1. ビルド & プッシュ
docker build -f backend/Dockerfile -t $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest .
docker push $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest

# 2. デプロイ（新リビジョン作成）
gcloud run deploy $SERVICE_NAME \
  --image $REGION-docker.pkg.dev/$PROJECT_ID/shiritori/shiritori-backend:latest \
  --region $REGION \
  --project $PROJECT_ID
```

### DB スキーマを修正した場合

```bash
cd backend

# 1. マイグレーションファイル作成（ローカル）
npm run db:migrate

# 2. 本番DBに適用
export DATABASE_URL='postgresql://...'  # Supabase接続文字列
npm run db:migrate:deploy
```

### Frontend を修正した場合

```bash
cd web-frontend

# 1. ビルド
NEXT_PUBLIC_API_URL=https://shiritori-backend-xxx.asia-northeast1.run.app npm run build

# 2. デプロイ
npx firebase deploy --project akumateki-shiritori
```

### Mobile を修正した場合

```bash
cd mobile-client

# 1. バージョン番号を更新（pubspec.yaml の version を変更）
# 例: version: 1.0.1+2

# 2. リリースビルド
flutter build appbundle --release

# 3. Google Play Console にアップロード
# build/app/outputs/bundle/release/app-release.aab
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

# Google Play Console にアップする流れ

1. 環境設定: mobile-client/.env に本番 API URL を設定
2. Firebase設定: google-services.json を配置
3. 署名キー準備: keytool でキーストア作成、key.properties 設定
4. ビルド: flutter build appbundle --release
5. アップロード: Google Play Console で app-release.aab をアップロード

---

現在の状態（準備完了）  
 ┌──────────────────────┬──────┬───────────────────────┐  
 │ 項目 │ 状態 │ 備考 │  
 ├──────────────────────┼──────┼───────────────────────┤  
 │ pubspec.yaml │ ✅ │ 現在 version: 1.0.0+4 │  
 ├──────────────────────┼──────┼───────────────────────┤  
 │ key.properties │ ✅ │ 署名キー設定済み │  
 ├──────────────────────┼──────┼───────────────────────┤  
 │ google-services.json │ ✅ │ Firebase設定済み │  
 └──────────────────────┴──────┴───────────────────────┘

---

今後使える「呪文」

##パターン1: モバイルのみ修正した場合

モバイルを修正した。バージョンを+1してapp bundleをビルドして。

##パターン2: バックエンドも修正した場合

バックエンドとモバイルを修正した。Cloud Runにデプロイし、モバイルはバージョン+1してapp bundleをビルドして。

##パターン3: 全部修正した場合

全サービスを修正した。DB→Backend→Frontend→Mobileの順でデプロイし、モバイルはバージョン+1してapp bundleをビルドして。

##パターン4: DBスキーマ変更を含む場合

DBスキーマを変更した。マイグレーションを本番に適用し、Backend→Frontend→Mobileをデプロイ。モバイルはバージョン+1してビルド。

---

補足

- app bundleの出力先: mobile-client/build/app/outputs/bundle/release/app-release.aab
- Google Play Console へのアップロードは手動（CLI自動化も可能だが設定が必要）
- バージョン形式: 1.0.0+5（+の後ろがビルド番号、Google Playでは必ず増やす必要あり）

---

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
