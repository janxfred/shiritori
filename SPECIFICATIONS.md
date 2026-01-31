# 悪魔的しりとり - 完全仕様書

> **目的**: このドキュメントは、コード生成AIが本プロジェクトと同等のアプリケーションを再現できるよう、全ての仕様を詳細に記述したものです。

---

## 目次

1. [プロジェクト概要](#1-プロジェクト概要)
2. [技術スタック](#2-技術スタック)
3. [アーキテクチャ](#3-アーキテクチャ)
4. [データベース設計](#4-データベース設計)
5. [バックエンドAPI仕様](#5-バックエンドapi仕様)
6. [ゲームロジック](#6-ゲームロジック)
7. [フロントエンド仕様](#7-フロントエンド仕様)
8. [ユーザー体験フロー](#8-ユーザー体験フロー)
9. [収益化・課金](#9-収益化課金)
10. [デプロイ・インフラ](#10-デプロイインフラ)
11. [セキュリティ](#11-セキュリティ)
12. [テスト戦略](#12-テスト戦略)

---

## 1. プロジェクト概要

### 1.1 概要

「悪魔的しりとり」は、日本語のしりとり（Word Chain Game）を題材にした対戦型モバイル・Webゲームです。
約12万語の辞書を使用し、AIとの対戦（3段階の難易度）およびPvP（対人戦）の両方に対応しています。

### 1.2 主要機能

- **AI対戦**: 3段階の難易度（Lv.1, Lv.2, Lv.3）で悪魔キャラクターと対戦
- **PvP対戦**: レーティングシステムを使ったランクマッチ
- **ガチャシステム**: アイコン・メッセージ・称号をランダム獲得
- **称号システム**: 30種類以上の称号を条件達成で獲得
- **プレゼントボックス**: 報酬受け取り機能
- **プレミアムサブスクリプション**: 魂の最大値増加、広告非表示など
- **ランキング**: レーティング順ランキング表示

### 1.3 ゲームの特徴

- **確保文字システム**: 有効な単語を出すと、その2文字目以降を「確保」し、相手はその文字を2文字目以降に含む単語を使えなくなる
- **ラウンド制**: 10ラウンド終了時、確保文字数が少ない方が勝利
- **制限時間**: 1ターン40秒
- **お手つき**: 無効な単語を2回出すと敗北
- **レーティングシステム**: Elo風のレーティング（勝利+4、敗北-2、引分0）

---

## 2. 技術スタック

### 2.1 バックエンド

- **言語**: TypeScript 5.x
- **フレームワーク**: Fastify 5.x
- **ORM**: Prisma 7.2
- **データベース**: PostgreSQL 16 (Supabase)
- **キャッシュ**: Redis 7 (Google Cloud Memorystore)
- **バリデーション**: Zod 4.3
- **認証**: bcryptjs + JWT（HS256）
- **API仕様**: OpenAPI 3.0（Swagger UI）

### 2.2 モバイルクライアント

- **SDK**: Flutter 3.10+
- **状態管理**: Riverpod 2.4
- **ルーティング**: GoRouter 14.0
- **HTTP通信**: Dio 5.4
- **ローカルストレージ**: SharedPreferences 2.2
- **広告**: Google Mobile Ads 5.1
- **課金**: RevenueCat (Purchases Flutter 8.3)

### 2.3 Webフロントエンド

- **フレームワーク**: Next.js 15 (App Router)
- **スタイリング**: Tailwind CSS 3.4
- **UI**: Radix UI
- **状態管理**: SWR 2.2
- **バリデーション**: Zod + React Hook Form

### 2.4 インフラ

- **バックエンドホスティング**: Google Cloud Run（Asia-northeast1）
- **Webホスティング**: Firebase Hosting
- **コンテナレジストリ**: Google Artifact Registry
- **シークレット管理**: Google Secret Manager
- **データベース**: Supabase（PostgreSQL 16）
- **キャッシュ**: Google Cloud Memorystore for Redis

---

## 3. アーキテクチャ

### 3.1 全体構成

```
┌────────────────────┐
│   Mobile Client    │  (Flutter)
│   Web Client       │  (Next.js)
└─────────┬──────────┘
          │ HTTPS
          ↓
┌────────────────────┐
│   Cloud Run        │  (Fastify Backend)
│   + Prisma ORM     │
└─────┬──────────┬───┘
      │          │
      ↓          ↓
┌──────────┐  ┌──────────┐
│ Supabase │  │  Redis   │
│PostgreSQL│  │ (PvP)    │
└──────────┘  └──────────┘
```

### 3.2 重要な設計判断

- **ゲームセッション**: インメモリ管理（Map）、Cloud Run再起動で消失
- **PvPセッション**: Redisで共有（TTL 60分）
- **戦績データ**: Supabase PostgreSQLに永続化
- **ステートレス**: Cloud Runの自動スケーリングに対応

---

## 4. データベース設計

### 4.1 ER図

```
users ─┬─ user_stats (1:1)
       ├─ match_histories (1:N)
       ├─ user_messages (N:M via junction)
       ├─ user_icons (N:M via junction)
       ├─ user_titles (N:M via junction)
       └─ present_boxes (1:N)

message_masters ─── user_messages
icon_masters ─── user_icons
titles ─── user_titles
```

### 4.2 Prismaスキーマ定義

#### `users` テーブル

```prisma
model User {
  id           String   @id @default(uuid())
  name         String   @unique
  passwordHash String
  email        String?  @unique

  // 装備
  iconId       String   @default("default_demon")
  equippedIcon Icon     @relation("EquippedIcon", fields: [iconId], references: [id])

  messageId    String   @default("msg_default_01")
  equippedMessage Message @relation("EquippedMessage", fields: [messageId], references: [id])

  title1Id     String?
  equippedTitle1 Title?  @relation("EquippedTitle1", fields: [title1Id], references: [id])

  title2Id     String?
  equippedTitle2 Title?  @relation("EquippedTitle2", fields: [title2Id], references: [id])

  title3Id     String?
  equippedTitle3 Title?  @relation("EquippedTitle3", fields: [title3Id], references: [id])

  // ステータス
  level        Int      @default(1)
  exp          Int      @default(0)
  rating       Int      @default(1000)
  coins        Int      @default(0)
  soulCount    Int      @default(7)
  lastSoulUsedAt DateTime?
  lastLoginAt  DateTime?
  isSubscriber Boolean  @default(false)
  isCheater    Boolean  @default(false)
  iconDisplayNumber Int @default(1)

  // 公開設定
  isRatingPublic   Boolean @default(true)
  isWinCountPublic Boolean @default(true)
  isWinRatePublic  Boolean @default(false)
  isStreakPublic   Boolean @default(true)

  // 最終レート変動
  lastRatingDelta Int?
  lastMatchAt     DateTime?

  // リレーション
  stats        UserStats?
  matchHistory MatchHistory[]
  ownedMessages UserMessage[]
  ownedIcons    UserIcon[]
  ownedTitles   UserTitle[]
  presents      PresentBox[]

  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([rating], name: "idx_users_rating")
  @@index([name], name: "idx_users_name")
}
```

#### `user_stats` テーブル

```prisma
model UserStats {
  userId    String @id
  user      User   @relation(fields: [userId], references: [id], onDelete: Cascade)

  totalWins   Int @default(0)
  totalLosses Int @default(0)
  totalDraws  Int @default(0)

  currentStreak    Int @default(0)
  maxStreak        Int @default(0)
  currentLoseStreak Int @default(0)

  gachaCount           Int @default(0)
  consecutiveLoginDays Int @default(0)
  aiMatchCount         Int @default(0)
}
```

#### `message_masters` テーブル

```prisma
model MessageMaster {
  id        String @id
  content   String
  condition String @default("ガチャで獲得")
  rarity    Int    @default(1)

  users UserMessage[]

  @@map("message_masters")
}
```

#### `icon_masters` テーブル

```prisma
model IconMaster {
  id            String @id
  imageUrl      String
  rarity        Int    @default(1)
  displayNumber Int    @default(0)

  users UserIcon[]

  @@map("icon_masters")
}
```

#### `titles` テーブル

```prisma
model Title {
  id          String @id
  name        String
  description String @default("")
  condition   String

  users UserTitle[]

  @@index([name])
}
```

#### `present_boxes` テーブル

```prisma
model PresentBox {
  id          String    @id @default(uuid())
  userId      String
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  type        String    // "coin", "title", "message", "icon", "item"
  targetId    String?   // title_id, message_id, icon_id
  amount      Int       @default(0)
  description String

  claimed     Boolean   @default(false)
  claimedAt   DateTime?
  createdAt   DateTime  @default(now())
  expiresAt   DateTime?

  @@index([userId, claimed])
  @@map("present_boxes")
}
```

#### `match_histories` テーブル

```prisma
model MatchHistory {
  id         String   @id @default(uuid())
  userId     String
  user       User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  opponentId String
  result     String   // "win", "loss", "draw"
  createdAt  DateTime @default(now())

  @@index([userId, createdAt])
  @@map("match_histories")
}
```

### 4.3 マスタデータ初期投入

#### アイコンマスタ

```typescript
const ICON_CATALOG = [
  {
    id: "default_demon",
    imageUrl: "/static/default_demon.jpg",
    rarity: 1,
    displayNumber: 1,
  },
  {
    id: "angel_white",
    imageUrl: "/static/angel_white.png",
    rarity: 1,
    displayNumber: 2,
  },
  {
    id: "demon_black_red",
    imageUrl: "/static/demon_black_red.png",
    rarity: 1,
    displayNumber: 3,
  },
  {
    id: "demon_white_gold",
    imageUrl: "/static/demon_white_gold.png",
    rarity: 1,
    displayNumber: 4,
  },
  {
    id: "demon_white_green",
    imageUrl: "/static/demon_white_green.png",
    rarity: 1,
    displayNumber: 5,
  },
  {
    id: "demon_white_blue",
    imageUrl: "/static/demon_white_blue.png",
    rarity: 1,
    displayNumber: 6,
  },
  {
    id: "demon_white_gray_horn",
    imageUrl: "/static/demon_white_gray_horn.png",
    rarity: 1,
    displayNumber: 7,
  },
  {
    id: "demon_white_gray",
    imageUrl: "/static/demon_white_gray.jpg",
    rarity: 1,
    displayNumber: 8,
  },
];
```

#### メッセージマスタ

```typescript
const MESSAGE_CATALOG = [
  {
    id: "msg_default_01",
    content: "よろしくお願いします",
    condition: "デフォルト",
    rarity: 1,
  },
  {
    id: "msg_gacha_01",
    content: "悪魔的に負けないぞ！",
    condition: "ガチャで獲得",
    rarity: 1,
  },
  {
    id: "msg_gacha_02",
    content: "しりとりは得意なんだ",
    condition: "ガチャで獲得",
    rarity: 1,
  },
  // ... 約30種類
];
```

#### 称号マスタ

```typescript
const TITLE_CATALOG = [
  // 初期称号
  {
    id: "beginner",
    name: "初心者",
    description: "",
    condition: "ガチャで獲得",
  },

  // レート系
  { id: "strong", name: "強者", description: "", condition: "レート1500到達" },
  {
    id: "overwhelming",
    name: "圧倒的猛者",
    description: "",
    condition: "レート2000到達",
  },

  // 連勝系
  {
    id: "win_streak_3",
    name: "3連勝達成",
    description: "",
    condition: "3連勝",
  },
  {
    id: "win_streak_5",
    name: "5連勝達成",
    description: "",
    condition: "5連勝",
  },
  {
    id: "win_streak_10",
    name: "10連勝達成",
    description: "",
    condition: "10連勝",
  },

  // 累計勝利系
  { id: "wins_10", name: "10勝達成", description: "", condition: "累計10勝" },
  { id: "wins_20", name: "20勝達成", description: "", condition: "累計20勝" },
  { id: "wins_30", name: "30勝達成", description: "", condition: "累計30勝" },
  { id: "wins_50", name: "50勝達成", description: "", condition: "累計50勝" },

  // 特殊系
  {
    id: "soul_eater",
    name: "ソウルイーター",
    description: "",
    condition: "魂を使い果たした",
  },
  {
    id: "transcender",
    name: "超越者",
    description: "",
    condition: "負けた後にすぐ勝利",
  },
  {
    id: "never_give_up",
    name: "めげない強さ",
    description: "",
    condition: "3連敗達成",
  },

  // ガチャ系
  {
    id: "beginner_summoner",
    name: "ビギナー召喚者",
    description: "",
    condition: "ガチャ3回",
  },
  {
    id: "intermediate_summoner",
    name: "中堅召喚者",
    description: "",
    condition: "ガチャ10回",
  },
  {
    id: "veteran_summoner",
    name: "ベテラン召喚者",
    description: "",
    condition: "ガチャ50回",
  },

  // ログイン系
  {
    id: "always_here",
    name: "ずっといるよ",
    description: "",
    condition: "連続7日間ログイン",
  },

  // コイン系
  {
    id: "coins_500",
    name: "500コイン到達",
    description: "",
    condition: "コイン500枚達成",
  },
  {
    id: "coins_1000",
    name: "1000コイン到達",
    description: "",
    condition: "コイン1000枚達成",
  },

  // AI対戦系
  {
    id: "ai_match_10",
    name: "AI対戦10回達成",
    description: "",
    condition: "AI対戦を10回プレイ",
  },
];
```

---

## 5. バックエンドAPI仕様

### 5.1 認証API

#### `POST /api/auth/signup`

新規アカウント作成

**リクエスト**:

```json
{
  "name": "string (1-20文字)",
  "password": "string (6文字以上)"
}
```

**レスポンス** (201):

```json
{
  "message": "アカウントを作成しました",
  "token": "JWT token (HS256)",
  "user": {
    "id": "uuid",
    "name": "string",
    "email": null,
    "iconId": "default_demon",
    "messageId": "msg_default_01",
    "title1Id": null,
    "title2Id": null,
    "title3Id": null,
    "level": 1,
    "exp": 0,
    "rating": 1000,
    "coins": 0,
    "soulCount": 7,
    "isSubscriber": false
  }
}
```

**エラー**:

- 400: バリデーションエラー（名前の長さ、パスワードの長さ）
- 409: ユーザー名重複

---

#### `POST /api/auth/login`

ログイン

**リクエスト**:

```json
{
  "identifier": "string (ユーザー名、ID、またはメール)",
  "password": "string"
}
```

**レスポンス** (200):

```json
{
  "message": "ログインしました",
  "token": "JWT token",
  "user": {
    /* signupと同じ */
  },
  "loginBonus": {
    "granted": true,
    "coins": 3, // 無料ユーザー: 3, プレミアム: 20
    "consecutiveDays": 5
  }
}
```

**ログインボーナスロジック**:

```typescript
// 最終ログインが24時間以上前なら付与
if (lastLoginAt && now - lastLoginAt > 24 * 60 * 60 * 1000) {
  const coinBonus = isSubscriber ? 20 : 3;
  user.coins += coinBonus;
  user.stats.consecutiveLoginDays += 1; // ※実際は日数計算必要
}
```

---

### 5.2 ゲームAPI（AI対戦）

#### `POST /api/game/start`

新しいゲームセッションを開始

**リクエスト**:

```json
{
  "aiLevel": 1 | 2 | 3  //Lv.1, Lv.2, Lv.3
}
```

**レスポンス** (201):

```json
{
  "session": {
    "id": "uuid",
    "status": "playing",
    "currentTurn": "player" | "ai",
    "playerMistakeCount": 0,
    "aiMistakeCount": 0,
    "playerCapturedChars": [],
    "aiCapturedChars": [],
    "lastWord": null,
    "expectedStartChar": "あ",
    "turnCount": 0,
    "roundCount": 0,
    "maxRounds": 10,
    "history": [],
    "aiLevel": 1,
    "turnStartedAt": "2026-01-25T12:00:00.000Z",
    "remainingTimeMs": 40000
  },
  "message": "悪魔的しりとりを始めようぞ！",
  "dictionarySize": 123456,
  "startChar": "あ",
  "firstTurn": "player",
  "aiFirstWord": null  // AI先攻の場合のみ存在
}
```

**ゲームセッション初期化ロジック**:

```typescript
// 先攻/後攻をランダムに決定
const firstTurn = Math.random() < 0.5 ? "player" : "ai";

// 開始文字をランダムに選択（50音から「ん」以外）
const hiragana =
  "あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん";
const startChar = hiragana[Math.floor(Math.random() * (hiragana.length - 1))];

// AI先攻の場合、AIの最初の単語を即座に選択
if (firstTurn === "ai") {
  const aiWord = selectAiWord(startChar, aiLevel, []);
  // ...
}
```

---

#### `POST /api/game/:sessionId/submit`

単語を送信

**リクエスト**:

```json
{
  "word": "あいうえお"
}
```

**レスポンス** (200):

```json
{
  "session": {
    /* 更新されたセッション */
  },
  "playerResult": {
    "word": "あいうえお",
    "isValid": true,
    "message": "有効な単語です！",
    "capturedChars": ["い", "う", "え", "お"]
  },
  "aiResult": {
    "word": "おんがく",
    "isValid": true,
    "message": "くっ、やるな…",
    "capturedChars": ["ん", "が", "く"]
  },
  "gameOver": false,
  "winner": null
}
```

**単語バリデーションロジック**:

```typescript
function validateWord(
  word: string,
  session: GameSession,
  dictionary: string[],
): ValidationResult {
  // 1. 頭文字チェック
  if (word[0] !== session.expectedStartChar) {
    return { isValid: false, message: "頭文字が違います" };
  }

  // 2. 辞書存在チェック
  if (!dictionary.includes(word)) {
    return { isValid: false, message: "辞書にありません" };
  }

  // 3. 「ん」で終わる単語は無効
  if (word[word.length - 1] === "ん") {
    return { isValid: false, message: "「ん」で終わっています" };
  }

  // 4. 既出チェック
  const usedWords = session.history.map((h) => h.word);
  if (usedWords.includes(word)) {
    return { isValid: false, message: "既に使われています" };
  }

  // 5. 確保文字チェック（相手が確保した文字を2文字目以降に含む？）
  const opponentCaptured =
    session.currentTurn === "player"
      ? session.aiCapturedChars
      : session.playerCapturedChars;

  for (const char of word.substring(1)) {
    if (opponentCaptured.includes(char)) {
      return { isValid: false, message: `「${char}」は相手が確保しています` };
    }
  }

  return {
    isValid: true,
    message: "有効な単語です！",
    capturedChars: word.substring(1).split(""),
  };
}
```

**伸ばし棒（ー）の処理**:

```typescript
function getNextChar(word: string): string {
  let lastChar = word[word.length - 1];

  // 伸ばし棒の場合、一つ前の文字を使う
  if (lastChar === "ー") {
    for (let i = word.length - 2; i >= 0; i--) {
      if (word[i] !== "ー") {
        lastChar = word[i];
        break;
      }
    }
  }

  // 小文字を大文字に変換
  const smallToLarge: Record<string, string> = {
    ぁ: "あ",
    ぃ: "い",
    ぅ: "う",
    ぇ: "え",
    ぉ: "お",
    っ: "つ",
    ゃ: "や",
    ゅ: "ゆ",
    ょ: "よ",
    ゎ: "わ",
  };

  return smallToLarge[lastChar] || lastChar;
}
```

---

#### `GET /api/game/:sessionId`

ゲーム状態取得

**レスポンス** (200):

```json
{
  "session": {
    /* GameSession */
  }
}
```

---

#### `GET /api/game/:sessionId/check-time`

制限時間チェック

**レスポンス** (200):

```json
{
  "expired": false,
  "session": {
    /* GameSession */
  },
  "message": null
}
```

**時間切れ判定ロジック**:

```typescript
const now = Date.now();
const turnStarted = new Date(session.turnStartedAt).getTime();
const elapsed = now - turnStarted;

if (elapsed > 40000) {
  // プレイヤーターンなら敗北
  if (session.currentTurn === "player") {
    session.status = "ai_win";
    return { expired: true, message: "時間切れだ。" };
  }
}
```

---

#### `POST /api/game/:sessionId/lifecycle`

アンチチート（非アクティブ時間通知）

**リクエスト**:

```json
{
  "inactiveMs": 15000
}
```

**レスポンス** (200):

```json
{
  "session": {
    /* GameSession */
  },
  "gameOver": true,
  "winner": "ai",
  "message": "非アクティブ時間が長すぎます。敗北です。"
}
```

**非アクティブペナルティ**:

```typescript
// 10秒以上非アクティブで即敗北
if (inactiveMs > 10000) {
  session.status = "ai_win";
  return { gameOver: true, winner: "ai" };
}
```

---

#### `POST /api/game/record-ai-match`

AI対戦結果記録（称号チェック）

**認証**: Bearer Token必須

**リクエスト**:

```json
{
  "result": "win" | "loss" | "draw"
}
```

**レスポンス** (200):

```json
{
  "message": "記録しました",
  "newTitles": [{ "id": "wins_10", "name": "10勝達成" }]
}
```

**称号チェックロジック**:

```typescript
async function checkAndGrantTitles(user: User): Promise<Title[]> {
  const stats = user.stats;
  const newTitles: Title[] = [];

  // レート系
  if (user.rating >= 1500 && !hasTitle(user, "strong")) {
    newTitles.push(await grantTitle(user, "strong"));
  }

  // 連勝系
  if (stats.currentStreak >= 3 && !hasTitle(user, "win_streak_3")) {
    newTitles.push(await grantTitle(user, "win_streak_3"));
  }

  // 累計勝利系
  if (stats.totalWins >= 10 && !hasTitle(user, "wins_10")) {
    newTitles.push(await grantTitle(user, "wins_10"));
  }

  // AI対戦系
  if (stats.aiMatchCount >= 10 && !hasTitle(user, "ai_match_10")) {
    newTitles.push(await grantTitle(user, "ai_match_10"));
  }

  return newTitles;
}

async function grantTitle(user: User, titleId: string): Promise<Title> {
  const title = await prisma.title.findUnique({ where: { id: titleId } });

  // プレゼントボックスに追加
  await prisma.presentBox.create({
    data: {
      userId: user.id,
      type: "title",
      targetId: titleId,
      description: `称号「${title.name}」を獲得しました！`,
    },
  });

  return title;
}
```

---

### 5.3 マッチメイキングAPI

#### `POST /api/matchmake`

PvPマッチング

**認証**: Bearer Token必須

**リクエスト**:

```json
{}
```

**レスポンス** (200):

```json
{
  "session": {
    "id": "uuid",
    "player1Id": "uuid",
    "player2Id": "uuid",
    "status": "playing",
    "currentTurnUserId": "uuid",
    "expectedStartChar": "あ",
    "turnStartedAt": "2026-01-25T12:00:00.000Z"
  },
  "opponent": {
    "userId": "uuid",
    "name": "対戦相手",
    "icon": {
      "id": "demon_black_red",
      "imageUrl": "/static/demon_black_red.png"
    },
    "title": {
      "id": "strong",
      "name": "強者"
    },
    "message": {
      "id": "msg_gacha_01",
      "content": "悪魔的に負けないぞ！"
    },
    "rating": 1050,
    "totalWins": 15,
    "winRate": 65.5,
    "maxStreak": 7
  }
}
```

**マッチングアルゴリズム**:

```typescript
async function matchmake(userId: string): Promise<MatchResult> {
  const me = await prisma.user.findUnique({ where: { id: userId } });

  // 1. 魂チェック
  if (me.soulCount < 1) {
    throw new Error("魂が足りません");
  }

  // 2. 既に割り当てられた相手がいるか確認（Redis）
  const assigned = await consumeAssignedMatch(userId);
  if (assigned) {
    const session = await getPvpSession(assigned.sessionId);
    const opponent = await prisma.user.findUnique({
      where: { id: assigned.opponentId },
    });

    // 魂を消費
    await prisma.user.updateMany({
      where: { id: userId, soulCount: { gte: 1 } },
      data: { soulCount: { decrement: 1 }, lastSoulUsedAt: new Date() },
    });

    return { session, opponent };
  }

  // 3. レート±100の範囲で候補を検索
  const minRating = me.rating - 100;
  const maxRating = me.rating + 100;

  const candidates = await prisma.user.findMany({
    where: {
      id: { not: userId },
      isCheater: false,
      soulCount: { gte: 1 },
      rating: { gte: minRating, lte: maxRating },
    },
    take: 50,
    include: {
      stats: true,
      equippedIcon: true,
      equippedMessage: true,
      equippedTitle1: true,
    },
  });

  if (candidates.length === 0) {
    throw new Error("条件に合う対戦相手が見つかりません");
  }

  // 4. レート差が最も小さい候補を選択
  let best = candidates[0];
  let bestDistance = Math.abs(best.rating - me.rating);

  for (const c of candidates) {
    const d = Math.abs(c.rating - me.rating);
    if (d < bestDistance) {
      bestDistance = d;
      best = c;
    }
  }

  // 5. PvPセッションを作成
  const session = await createPvpSession({
    player1Id: userId,
    player2Id: best.id,
  });

  // 6. 相手側に割り当てを登録（Redis、TTL 2分）
  await assignMatchToUser({
    userId: best.id,
    sessionId: session.id,
    opponentId: userId,
    ttlMs: 2 * 60 * 1000,
  });

  // 7. 魂を消費
  await prisma.user.updateMany({
    where: { id: userId, soulCount: { gte: 1 } },
    data: { soulCount: { decrement: 1 }, lastSoulUsedAt: new Date() },
  });

  return { session, opponent: best };
}
```

---

### 5.4 PvP対戦API

#### `POST /api/pvp/:sessionId/start`

PvPセッションに参加

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "session": {
    /* PvpSession */
  },
  "opponent": {
    /* OpponentInfo */
  }
}
```

---

#### `POST /api/pvp/:sessionId/submit`

PvP単語送信

**認証**: Bearer Token必須

**リクエスト**:

```json
{
  "word": "あいうえお"
}
```

**レスポンス** (200):

```json
{
  "session": {
    /* 更新されたPvpSession */
  },
  "result": {
    "word": "あいうえお",
    "isValid": true,
    "message": "有効な単語です！",
    "capturedChars": ["い", "う", "え", "お"]
  },
  "gameOver": false,
  "winner": null
}
```

**PvPセッション終了時の結果反映**:

```typescript
async function finalizePvpMatch(session: PvpSession): Promise<void> {
  const { player1Id, player2Id, winnerId } = session;

  // 二重反映防止（Redisフラグ）
  const lockKey = `pvp_finalize:${session.id}`;
  const locked = await redis.set(lockKey, "1", "EX", 60, "NX");
  if (!locked) return;

  // 結果を判定
  const player1Result =
    winnerId === player1Id ? "win" : winnerId === player2Id ? "loss" : "draw";
  const player2Result =
    winnerId === player2Id ? "win" : winnerId === player1Id ? "loss" : "draw";

  // 各プレイヤーの結果を反映
  await recordMatchResult(player1Id, player2Id, player1Result);
  await recordMatchResult(player2Id, player1Id, player2Result);
}

async function recordMatchResult(
  userId: string,
  opponentId: string,
  result: "win" | "loss" | "draw",
): Promise<void> {
  const ratingDelta = result === "win" ? 4 : result === "loss" ? -2 : 0;
  const coinDelta = result === "win" ? 4 : 1;

  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: { stats: true },
  });

  // 戦績更新
  const nextStats = {
    totalWins: (user.stats?.totalWins ?? 0) + (result === "win" ? 1 : 0),
    totalLosses: (user.stats?.totalLosses ?? 0) + (result === "loss" ? 1 : 0),
    totalDraws: (user.stats?.totalDraws ?? 0) + (result === "draw" ? 1 : 0),
    currentStreak: result === "win" ? (user.stats?.currentStreak ?? 0) + 1 : 0,
    currentLoseStreak:
      result === "loss" ? (user.stats?.currentLoseStreak ?? 0) + 1 : 0,
  };

  nextStats.maxStreak = Math.max(
    user.stats?.maxStreak ?? 0,
    nextStats.currentStreak,
  );

  // トランザクション
  await prisma.$transaction(async (tx) => {
    // レート・コイン更新
    await tx.user.update({
      where: { id: userId },
      data: {
        rating: { increment: ratingDelta },
        coins: { increment: coinDelta },
        lastRatingDelta: ratingDelta,
        lastMatchAt: new Date(),
      },
    });

    // 戦績更新
    await tx.userStats.upsert({
      where: { userId },
      create: { userId, ...nextStats },
      update: nextStats,
    });

    // 履歴記録
    await tx.matchHistory.create({
      data: { userId, opponentId, result },
    });
  });

  // 称号チェック
  await checkAndGrantTitles(user);
}
```

---

### 5.5 ガチャAPI

#### `GET /api/gacha`

ガチャ状態取得

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "cost": 3,
  "coins": 100,
  "rates": [
    {
      "type": "icon",
      "id": "demon_black_red",
      "imageUrl": "/static/demon_black_red.png",
      "rarity": 1,
      "displayNumber": 3,
      "probability": 0.025
    },
    {
      "type": "message",
      "id": "msg_gacha_01",
      "content": "悪魔的に負けないぞ！",
      "rarity": 1,
      "probability": 0.025
    },
    {
      "type": "title",
      "id": "beginner",
      "name": "初心者",
      "probability": 0.025
    }
  ]
}
```

**排出率計算**:

```typescript
// 全マスタを等確率で排出
const icons = await prisma.iconMaster.findMany();
const messages = await prisma.messageMaster.findMany();
const titles = await prisma.title.findMany({
  where: { condition: "ガチャで獲得" },
});

const totalItems = icons.length + messages.length + titles.length;
const probability = 1 / totalItems;

const rates = [
  ...icons.map((icon) => ({ type: "icon", ...icon, probability })),
  ...messages.map((msg) => ({ type: "message", ...msg, probability })),
  ...titles.map((title) => ({ type: "title", ...title, probability })),
];
```

---

#### `POST /api/gacha/draw`

ガチャを引く

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "result": {
    "type": "icon",
    "id": "demon_white_gold",
    "imageUrl": "/static/demon_white_gold.png",
    "rarity": 1,
    "displayNumber": 4,
    "isDuplicate": false
  },
  "coins": 97
}
```

**ガチャロジック**:

```typescript
async function drawGacha(userId: string): Promise<GachaResult> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      stats: true,
      ownedIcons: true,
      ownedMessages: true,
      ownedTitles: true,
    },
  });

  // コインチェック
  if (user.coins < 3) {
    throw new Error("コインが足りません");
  }

  // ランダム抽選
  const allItems = [
    ...(await prisma.iconMaster.findMany()),
    ...(await prisma.messageMaster.findMany()),
    ...(await prisma.title.findMany({ where: { condition: "ガチャで獲得" } })),
  ];

  const drawn = allItems[Math.floor(Math.random() * allItems.length)];

  // 重複判定
  const isDuplicate = checkDuplicate(user, drawn);

  // アイテム付与（重複でもプレゼントボックスに追加）
  await prisma.presentBox.create({
    data: {
      userId,
      type: drawn.type,
      targetId: drawn.id,
      description: `ガチャで「${drawn.name || drawn.content}」を獲得！`,
    },
  });

  // コイン消費、ガチャ回数カウント
  await prisma.user.update({
    where: { id: userId },
    data: {
      coins: { decrement: 3 },
      stats: {
        update: {
          gachaCount: { increment: 1 },
        },
      },
    },
  });

  // ガチャ回数称号チェック
  await checkGachaTitles(user);

  return { result: drawn, isDuplicate, coins: user.coins - 3 };
}
```

---

### 5.6 プロフィールAPI

#### `GET /api/me`

自分のプロフィール取得

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "iconId": "demon_black_red",
  "messageId": "msg_gacha_01",
  "title1Id": "strong",
  "title2Id": null,
  "title3Id": null,
  "level": 5,
  "exp": 123,
  "rating": 1234,
  "coins": 50,
  "soulCount": 7,
  "lastSoulUsedAt": "2026-01-24T12:00:00.000Z",
  "isSubscriber": false,
  "isRatingPublic": true,
  "isWinCountPublic": true,
  "isWinRatePublic": false,
  "isStreakPublic": true,
  "lastRatingDelta": 4,
  "lastMatchAt": "2026-01-25T11:00:00.000Z",
  "stats": {
    "totalWins": 15,
    "totalLosses": 10,
    "totalDraws": 2,
    "currentStreak": 3,
    "maxStreak": 7,
    "currentLoseStreak": 0,
    "gachaCount": 20,
    "consecutiveLoginDays": 5,
    "aiMatchCount": 30
  }
}
```

**魂自動回復ロジック**:

```typescript
async function recoverSoul(user: User): Promise<User> {
  const now = Date.now();
  const lastUsed = user.lastSoulUsedAt
    ? new Date(user.lastSoulUsedAt).getTime()
    : 0;
  const elapsed = now - lastUsed;

  // 24時間経過で全回復
  if (elapsed > 24 * 60 * 60 * 1000) {
    const maxSoul = user.isSubscriber ? 15 : 7;
    return await prisma.user.update({
      where: { id: user.id },
      data: { soulCount: maxSoul },
    });
  }

  return user;
}
```

---

#### `PATCH /api/me`

プロフィール更新

**認証**: Bearer Token必須

**リクエスト**:

```json
{
  "iconId": "demon_white_gold",
  "messageId": "msg_gacha_02",
  "title1Id": "strong",
  "title2Id": "win_streak_5",
  "title3Id": null,
  "isRatingPublic": true,
  "isWinCountPublic": false,
  "isWinRatePublic": true,
  "isStreakPublic": false
}
```

**レスポンス** (200):

```json
{
  "message": "プロフィールを更新しました",
  "user": {
    /* 更新後のプロフィール */
  }
}
```

---

#### `GET /api/me/inventory`

所持アイテム一覧

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "icons": [
    {
      "id": "default_demon",
      "imageUrl": "/static/default_demon.jpg",
      "rarity": 1,
      "displayNumber": 1
    },
    {
      "id": "demon_black_red",
      "imageUrl": "/static/demon_black_red.png",
      "rarity": 1,
      "displayNumber": 3
    }
  ],
  "messages": [
    { "id": "msg_default_01", "content": "よろしくお願いします", "rarity": 1 },
    { "id": "msg_gacha_01", "content": "悪魔的に負けないぞ！", "rarity": 1 }
  ],
  "titles": [
    {
      "id": "strong",
      "name": "強者",
      "description": "",
      "condition": "レート1500到達"
    },
    {
      "id": "wins_10",
      "name": "10勝達成",
      "description": "",
      "condition": "累計10勝"
    }
  ]
}
```

---

#### `GET /api/me/icons`

アイコンカタログ

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "icons": [
    {
      "id": "default_demon",
      "imageUrl": "/static/default_demon.jpg",
      "rarity": 1,
      "displayNumber": 1,
      "owned": true
    },
    {
      "id": "angel_white",
      "imageUrl": "/static/angel_white.png",
      "rarity": 1,
      "displayNumber": 2,
      "owned": false
    }
    // ...
  ]
}
```

---

#### `GET /api/me/messages`

メッセージカタログ

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "messages": [
    {
      "id": "msg_default_01",
      "content": "よろしくお願いします",
      "condition": "デフォルト",
      "rarity": 1,
      "owned": true
    },
    {
      "id": "msg_gacha_01",
      "content": "悪魔的に負けないぞ！",
      "condition": "ガチャで獲得",
      "rarity": 1,
      "owned": false
    }
    // ...
  ]
}
```

---

#### `GET /api/me/titles`

称号カタログ

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "titles": [
    {
      "id": "strong",
      "name": "強者",
      "condition": "レート1500到達",
      "owned": true
    },
    {
      "id": "wins_10",
      "name": "10勝達成",
      "condition": "累計10勝",
      "owned": true
    },
    {
      "id": "wins_20",
      "name": "20勝達成",
      "condition": "累計20勝",
      "owned": false
    }
    // ...
  ]
}
```

---

#### `POST /api/me/rewarded-ad`

動画広告視聴報酬

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "message": "魂を1回復しました",
  "soulCount": 7
}
```

**報酬ロジック**:

```typescript
async function claimRewardedAd(userId: string): Promise<{ soulCount: number }> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  const maxSoul = user.isSubscriber ? 15 : 7;

  // 既に最大値なら何もしない
  if (user.soulCount >= maxSoul) {
    return { soulCount: user.soulCount };
  }

  // プレミアムユーザーは全回復、無料ユーザーは+1
  const recovery = user.isSubscriber ? maxSoul : 1;

  const updated = await prisma.user.update({
    where: { id: userId },
    data: { soulCount: Math.min(user.soulCount + recovery, maxSoul) },
  });

  return { soulCount: updated.soulCount };
}
```

---

### 5.7 プレゼントボックスAPI

#### `GET /api/present`

プレゼント一覧

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "presents": [
    {
      "id": "uuid",
      "type": "title",
      "targetId": "strong",
      "amount": 0,
      "description": "称号「強者」を獲得しました！",
      "claimed": false,
      "createdAt": "2026-01-25T12:00:00.000Z",
      "expiresAt": null
    },
    {
      "id": "uuid",
      "type": "coin",
      "targetId": null,
      "amount": 10,
      "description": "ログインボーナス",
      "claimed": false,
      "createdAt": "2026-01-24T12:00:00.000Z",
      "expiresAt": null
    }
  ],
  "unclaimedCount": 2
}
```

---

#### `POST /api/present/claim`

プレゼント受け取り

**認証**: Bearer Token必須

**リクエスト**:

```json
{
  "presentId": "uuid"
}
```

**レスポンス** (200):

```json
{
  "message": "プレゼントを受け取りました",
  "rewards": [{ "type": "title", "id": "strong", "name": "強者", "amount": 0 }]
}
```

---

#### `POST /api/present/claim-all`

全プレゼント受け取り

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "message": "すべてのプレゼントを受け取りました",
  "rewards": [
    { "type": "title", "id": "strong", "name": "強者", "amount": 0 },
    { "type": "coin", "id": null, "name": null, "amount": 10 }
  ]
}
```

**受け取りロジック**:

```typescript
async function claimPresent(
  userId: string,
  presentId: string,
): Promise<Reward[]> {
  const present = await prisma.presentBox.findUnique({
    where: { id: presentId },
  });

  if (present.userId !== userId) {
    throw new Error("このプレゼントはあなたのものではありません");
  }

  if (present.claimed) {
    throw new Error("既に受け取り済みです");
  }

  // トランザクション
  await prisma.$transaction(async (tx) => {
    // プレゼントを受け取り済みに
    await tx.presentBox.update({
      where: { id: presentId },
      data: { claimed: true, claimedAt: new Date() },
    });

    // 報酬を付与
    if (present.type === "coin") {
      await tx.user.update({
        where: { id: userId },
        data: { coins: { increment: present.amount } },
      });
    } else if (present.type === "title") {
      await tx.userTitle.create({
        data: { userId, titleId: present.targetId },
      });
    } else if (present.type === "message") {
      await tx.userMessage.create({
        data: { userId, messageId: present.targetId },
      });
    } else if (present.type === "icon") {
      await tx.userIcon.create({
        data: { userId, iconId: present.targetId },
      });
    }
  });

  return [{ type: present.type, id: present.targetId, amount: present.amount }];
}
```

---

### 5.8 ランキングAPI

#### `GET /api/ranking?limit=100`

レーティング順ランキング

**レスポンス** (200):

```json
{
  "users": [
    {
      "userId": "uuid",
      "name": "トッププレイヤー",
      "rating": 2000,
      "totalWins": 100,
      "winRate": 70.5,
      "maxStreak": 20,
      "iconUrl": "/static/demon_white_gold.png",
      "title": "圧倒的猛者"
    }
    // ...
  ]
}
```

---

### 5.9 ユーザー検索API

#### `GET /api/users?name=xxx`

ユーザー名でユーザー検索

**レスポンス** (200):

```json
{
  "users": [
    {
      "id": "uuid",
      "name": "プレイヤー名",
      "rating": 1234,
      "iconUrl": "/static/default_demon.jpg"
    }
  ]
}
```

---

#### `GET /api/users/:userId/profile`

ユーザープロフィール詳細

**レスポンス** (200):

```json
{
  "id": "uuid",
  "name": "プレイヤー名",
  "iconUrl": "/static/demon_black_red.png",
  "title1": "強者",
  "title2": null,
  "title3": null,
  "message": "悪魔的に負けないぞ！",
  "rating": 1234,
  "totalWins": 15,
  "totalLosses": 10,
  "totalDraws": 2,
  "winRate": 55.5,
  "currentStreak": 3,
  "maxStreak": 7,
  "isRatingPublic": true,
  "isWinCountPublic": true,
  "isWinRatePublic": false,
  "isStreakPublic": true
}
```

---

### 5.10 サブスクリプションAPI

#### `POST /api/subscription/sync`

サブスクリプション状態同期（RevenueCat → バックエンド）

**認証**: Bearer Token必須

**リクエスト**:

```json
{
  "isActive": true
}
```

**レスポンス** (200):

```json
{
  "message": "サブスクリプション状態を同期しました",
  "isSubscriber": true
}
```

---

### 5.11 利用規約API

#### `POST /api/terms/agree`

利用規約に同意

**認証**: Bearer Token必須

**レスポンス** (200):

```json
{
  "message": "利用規約に同意しました"
}
```

---

## 6. ゲームロジック

### 6.1 しりとり基本ルール

#### 頭文字一致

```typescript
if (word[0] !== session.expectedStartChar) {
  return {
    isValid: false,
    message: `「${session.expectedStartChar}」から始まる単語を入力してください`,
  };
}
```

#### 辞書存在チェック

```typescript
// 辞書（shiritori_list.json）は約12万語を含む
const dictionary: string[] = JSON.parse(
  fs.readFileSync("shiritori_list.json", "utf-8"),
);

if (!dictionary.includes(word)) {
  return { isValid: false, message: "辞書にありません" };
}
```

#### 「ん」禁止

```typescript
const lastChar = getNextChar(word);
if (lastChar === "ん") {
  return { isValid: false, message: "「ん」で終わる単語は使えません" };
}
```

#### 既出禁止

```typescript
const usedWords = session.history.map((h) => h.word);
if (usedWords.includes(word)) {
  return { isValid: false, message: "その単語は既に使われています" };
}
```

#### 確保文字禁止

```typescript
const opponentCaptured =
  session.currentTurn === "player"
    ? session.aiCapturedChars
    : session.playerCapturedChars;

for (const char of word.substring(1)) {
  if (opponentCaptured.includes(char)) {
    return { isValid: false, message: `「${char}」は相手が確保しています` };
  }
}
```

### 6.2 確保文字システム

```typescript
function captureChars(word: string): string[] {
  // 2文字目以降を確保
  return word.substring(1).split("");
}

// 例: 「あいうえお」→ ['い', 'う', 'え', 'お']
```

### 6.3 伸ばし棒・小文字の正規化

```typescript
function getNextChar(word: string): string {
  let lastChar = word[word.length - 1];

  // 伸ばし棒（ー）の処理
  if (lastChar === "ー") {
    for (let i = word.length - 2; i >= 0; i--) {
      if (word[i] !== "ー") {
        lastChar = word[i];
        break;
      }
    }
  }

  // 小文字→大文字変換
  const smallToLarge: Record<string, string> = {
    ぁ: "あ",
    ぃ: "い",
    ぅ: "う",
    ぇ: "え",
    ぉ: "お",
    っ: "つ",
    ゃ: "や",
    ゅ: "ゆ",
    ょ: "よ",
    ゎ: "わ",
  };

  return smallToLarge[lastChar] || lastChar;
}

// 例: 「コーヒー」→ 'ひ'
// 例: 「しょうがっこう」→ 'う'
```

### 6.4 勝敗判定

#### お手つき（2回でアウト）

```typescript
if (!result.isValid) {
  session.playerMistakeCount++;
  if (session.playerMistakeCount >= 2) {
    session.status = "ai_win";
    return { gameOver: true, winner: "ai", message: "お手つき2回で敗北です" };
  }
}
```

#### 時間切れ（40秒）

```typescript
const now = Date.now();
const turnStarted = new Date(session.turnStartedAt).getTime();
const elapsed = now - turnStarted;

if (elapsed > 40000 && session.currentTurn === "player") {
  session.status = "ai_win";
  return { gameOver: true, winner: "ai", message: "時間切れです" };
}
```

#### ラウンド制（10ラウンド）

```typescript
// プレイヤーとAIが1回ずつ有効な単語を出すと1ラウンド
session.roundCount++;

if (session.roundCount >= session.maxRounds) {
  // 確保文字数が少ない方が勝利
  const playerCaptured = session.playerCapturedChars.length;
  const aiCaptured = session.aiCapturedChars.length;

  if (playerCaptured < aiCaptured) {
    session.status = "player_win";
    return { gameOver: true, winner: "player", message: "プレイヤーの勝利！" };
  } else if (aiCaptured < playerCaptured) {
    session.status = "ai_win";
    return { gameOver: true, winner: "ai", message: "悪魔の勝利だ…" };
  } else {
    session.status = "draw";
    return { gameOver: true, winner: null, message: "引き分けだ" };
  }
}
```

#### AI降参

```typescript
// AIが有効な単語を見つけられない場合
if (aiCandidates.length === 0) {
  session.status = "player_win";
  return {
    gameOver: true,
    winner: "player",
    message: "AIは降参した。プレイヤーの勝利！",
  };
}
```

#### 非アクティブペナルティ

```typescript
// 10秒以上非アクティブで即敗北
if (inactiveMs > 10000) {
  session.status = "ai_win";
  return {
    gameOver: true,
    winner: "ai",
    message: "非アクティブ時間が長すぎます",
  };
}
```

### 6.5 AIレベル別動作

#### Lv.1（初級）

```typescript
function selectAiWordEasy(
  startChar: string,
  dictionary: string[],
  usedWords: string[],
  opponentCaptured: string[],
): string {
  const candidates = dictionary.filter(
    (word) =>
      word[0] === startChar &&
      !usedWords.includes(word) &&
      getNextChar(word) !== "ん" &&
      !containsCapturedChars(word, opponentCaptured),
  );

  // ランダム選択
  return candidates[Math.floor(Math.random() * candidates.length)];
}
```

#### Lv.2（中級）

```typescript
function selectAiWordNormal(startChar: string, dictionary: string[], usedWords: string[], opponentCaptured: string[], turnCount: number): string {
  const candidates = /* 有効な候補 */;

  // 奇数ターンは戦略的、偶数ターンはランダム
  if (turnCount % 2 === 1) {
    return selectStrategic(candidates, dictionary);
  } else {
    return candidates[Math.floor(Math.random() * candidates.length)];
  }
}
```

#### Lv.3（上級）

```typescript
function selectAiWordHard(startChar: string, dictionary: string[], usedWords: string[], opponentCaptured: string[]): string {
  const candidates = /* 有効な候補 */;

  // 常に戦略的選択
  return selectStrategic(candidates, dictionary);
}

function selectStrategic(candidates: string[], dictionary: string[]): string {
  // 次の候補数が少ない文字で終わる単語を優先
  let best = candidates[0];
  let minNextCandidates = Infinity;

  for (const word of candidates) {
    const nextChar = getNextChar(word);
    const nextCandidates = dictionary.filter(w => w[0] === nextChar).length;

    if (nextCandidates < minNextCandidates) {
      minNextCandidates = nextCandidates;
      best = word;
    }
  }

  return best;
}
```

### 6.6 AI台詞システム

```typescript
const DEMON_MESSAGES = {
  start: "悪魔的しりとりを始めようぞ！",
  playerWin: "くっ…まさか負けるとは…",
  aiWin: "フハハ！悪魔の勝利だ！",
  playerMistake: "お手つきだな。次も気をつけろよ。",
  aiMistake: "くっ…やるな…",
  timeUp: "時間切れだ。",
  draw: "引き分けか…次はこうはいかんぞ。",
};

function getDemonMessage(event: string): string {
  return DEMON_MESSAGES[event] || "…";
}
```

---

## 7. フロントエンド仕様

### 7.1 モバイルクライアント（Flutter）

#### 画面一覧

| パス              | 画面名              | 説明                 |
| ----------------- | ------------------- | -------------------- |
| `/`               | GamePage            | AI対戦メイン画面     |
| `/ranked`         | RankedMatchPage     | ランクマッチメニュー |
| `/pvp/:sessionId` | PvpGamePage         | PvP対戦画面          |
| `/gacha`          | GachaPage           | ガチャ画面           |
| `/present`        | PresentPage         | プレゼントボックス   |
| `/account`        | AccountSettingsPage | アカウント設定       |
| `/login`          | LoginPage           | ログイン画面         |
| `/signup`         | SignupPage          | サインアップ画面     |
| `/icons`          | IconCatalogPage     | アイコン一覧         |
| `/messages`       | MessageCatalogPage  | メッセージ一覧       |
| `/titles`         | TitleCatalogPage    | 称号一覧             |
| `/users`          | UserListPage        | ユーザー検索         |
| `/users/:userId`  | UserProfilePage     | ユーザープロフィール |

#### 状態管理（Riverpod）

```dart
// 認証状態
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(ref.read(authApiProvider));
});

// ゲーム状態（インメモリ）
class GamePageState {
  GamePhase phase; // home | playing | overtimeAnnounce | gameOver
  GameSession? session;
  String demonMessage;
  bool isSubmitting;
  bool isAiThinking;
  String? winner;
  AiLevel selectedLevel;
}
```

#### 重要な画面レイアウト

##### GamePage（AI対戦）

```
┌──────────────────────────────────┐
│  [設定]         [ヘルプ] [プレゼント] │
│                                  │
│      ┌──────────────────┐       │
│      │   悪魔の顔         │       │
│      │                  │       │
│      │   台詞エリア      │       │
│      └──────────────────┘       │
│                                  │
│  確保文字エリア                    │
│  ・プレイヤー確保: い、う、え、お    │
│  ・悪魔確保: ん、が、く            │
│                                  │
│  ┌─────────────────────────┐  │
│  │ チャット履歴（LINE風）        │  │
│  │                            │  │
│  │  [あいうえお]              │  │
│  │              [おんがく]    │  │
│  │  [くじら]                  │  │
│  └─────────────────────────┘  │
│                                  │
│  [「ら」から始まる言葉を入力]      │
│  ┌─────────────────────────┐  │
│  │ 入力欄              [送信]  │  │
│  └─────────────────────────┘  │
│                                  │
│  [バナー広告]                     │
└──────────────────────────────────┘
```

##### AccountSettingsPage

```
┌──────────────────────────────────┐
│  [戻る]     アカウント設定         │
│                                  │
│  ┌─────────────────────────┐  │
│  │ プロフィールカード            │  │
│  │                            │  │
│  │  [アイコン]  名前            │  │
│  │             レート: 1234    │  │
│  │             コイン: 50      │  │
│  │             魂: 7           │  │
│  └─────────────────────────┘  │
│                                  │
│  ┌─────────────────────────┐  │
│  │ プレミアムプラン              │  │
│  │  [加入中] or [加入する]      │  │
│  └─────────────────────────┘  │
│                                  │
│  ┌─────────────────────────┐  │
│  │ 広告を見て魂を回復            │  │
│  │  [▶ 視聴する]               │  │
│  └─────────────────────────┘  │
│                                  │
│  ┌─────────────────────────┐  │
│  │ アイコン変更                 │  │
│  │  [アイコン一覧へ]            │  │
│  │  [○] [○] [○] ...         │  │
│  └─────────────────────────┘  │
│                                  │
│  ┌─────────────────────────┐  │
│  │ 称号変更                     │  │
│  │  [称号一覧へ]                │  │
│  │  [強者] [10勝達成] ...       │  │
│  └─────────────────────────┘  │
│                                  │
│  [バナー広告]                     │
└──────────────────────────────────┘
```

##### PresentPage

```
┌──────────────────────────────────┐
│  [戻る]     プレゼントボックス       │
│                                  │
│  未受け取り: 3件  [すべて受け取る]  │
│                                  │
│  ┌─────────────────────────┐  │
│  │ [盾.jpeg]                   │  │
│  │ 称号「強者」を獲得しました！   │  │
│  │ 称号                         │  │
│  └─────────────────────────┘  │
│                                  │
│  ┌─────────────────────────┐  │
│  │ [コイン.jpeg]               │  │
│  │ ログインボーナス             │  │
│  │ コイン ×3                   │  │
│  └─────────────────────────┘  │
│                                  │
│  ┌─────────────────────────┐  │
│  │ [吹き出し.jpeg]             │  │
│  │ メッセージを獲得しました！    │  │
│  │ メッセージ                   │  │
│  └─────────────────────────┘  │
│                                  │
│  [バナー広告]                     │
└──────────────────────────────────┘
```

#### NEW表示機能（依頼4）

```dart
// ローカルストレージで最終表示日時を管理
class NewItemService {
  static Future<DateTime?> getTitlesLastViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('titles_last_viewed');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  static Future<void> markTitlesViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('titles_last_viewed', DateTime.now().millisecondsSinceEpoch);
  }
}

// 一覧画面のdisposeで記録
@override
void dispose() {
  NewItemService.markTitlesViewed();
  super.dispose();
}

// 表示時にNEWバッジを追加
final showNew = title.owned && _lastViewedAt == null;
if (showNew) {
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
    child: Text('NEW', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
  );
}
```

#### 広告表示（依頼2）

```dart
// バナー広告を全画面に表示
Column(
  children: [
    Expanded(child: /* メインコンテンツ */),
    BannerAdWidget(isSubscriber: session.user.isSubscriber),
  ],
)

// BannerAdWidget
class BannerAdWidget extends StatefulWidget {
  final bool isSubscriber;

  @override
  Widget build(BuildContext context) {
    if (isSubscriber) return SizedBox.shrink(); // 課金者は非表示

    return Container(
      width: bannerAd.size.width.toDouble(),
      height: bannerAd.size.height.toDouble(),
      child: AdWidget(ad: bannerAd),
    );
  }
}
```

---

### 7.2 Webフロントエンド（Next.js）

#### ページ構成

- `/`: トップページ（ゲーム紹介）
- `/terms`: 利用規約
- `/privacy`: プライバシーポリシー

#### デプロイ

- Firebase Hosting（静的サイト）
- `firebase deploy --only hosting`

---

## 8. ユーザー体験フロー

### 8.1 新規ユーザー登録〜初回対戦

```
1. アプリ起動
   ↓
2. ホーム画面（ゲストモード）
   ↓
3. [新規登録]タップ
   ↓
4. プレイヤー名・パスワード入力
   ↓
5. アカウント作成完了（デフォルトアイコン・メッセージ・称号）
   ↓
6. ホーム画面に戻る
   ↓
7. AIレベルを選択（Lv.1〜3）
   ↓
8. [対戦開始]タップ
   ↓
9. ゲーム画面に遷移
   ↓
10. しりとりプレイ
   ↓
11. 勝敗判定
   ↓
12. 結果画面（獲得コイン・称号チェック）
   ↓
13. ホーム画面に戻る
```

### 8.2 PvP対戦フロー

```
1. ホーム画面
   ↓
2. [ランクマッチ]タップ
   ↓
3. ランクマッチメニュー画面
   ↓
4. [対戦開始]タップ
   ↓
5. マッチング中...
   ↓
6. 対戦相手が見つかりました（プロフィール表示）
   ↓
7. PvP対戦画面に遷移
   ↓
8. しりとりプレイ（交互にターン）
   ↓
9. 勝敗判定
   ↓
10. 結果画面（レート変動・コイン獲得）
   ↓
11. ホーム画面に戻る
```

### 8.3 ガチャ〜アイテム受け取りフロー

```
1. ホーム画面
   ↓
2. [ガチャ]タップ
   ↓
3. ガチャ画面（排出率一覧表示）
   ↓
4. [召喚する]タップ（コイン3枚消費）
   ↓
5. ガチャ結果表示（アイコン/メッセージ/称号）
   ↓
6. プレゼントボックスに追加
   ↓
7. [プレゼントボックス]タップ
   ↓
8. プレゼント一覧表示
   ↓
9. [すべて受け取る]タップ
   ↓
10. 受け取り完了モーダル表示
   ↓
11. ホーム画面に戻る
```

---

## 9. 収益化・課金

### 9.1 収益モデル

- **広告**: Google Mobile Ads（バナー・リワード動画）
- **サブスクリプション**: RevenueCat経由でGoogle Play/App Store課金

### 9.2 プレミアムプラン特典

| 項目                 | 無料ユーザー | プレミアムユーザー |
| -------------------- | ------------ | ------------------ |
| 魂の最大値           | 7個          | 15個               |
| ログインボーナス     | 3コイン      | 20コイン           |
| リワード広告視聴報酬 | 魂+1         | 魂全回復           |
| バナー広告           | 表示         | 非表示             |

### 9.3 RevenueCat設定

```dart
// 初期化
await Purchases.configure(PurchasesConfiguration('PUBLIC_API_KEY'));

// サブスクリプション購入
final customerInfo = await Purchases.purchasePackage(package);

// サブスクリプション状態確認
final customerInfo = await Purchases.getCustomerInfo();
final isSubscriber = customerInfo.entitlements.all['premium']?.isActive == true;

// バックエンドに同期
await SubscriptionService.syncSubscriptionToBackend(
  token: session.token,
  isActive: isSubscriber,
);
```

### 9.4 広告配置

- **バナー広告**: 全画面下部（課金者は非表示）
- **リワード動画**: アカウント設定画面の「魂を回復」ボタン

---

## 10. デプロイ・インフラ

### 10.1 バックエンド（Cloud Run）

#### Dockerfile

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/shiritori_list.json ./shiritori_list.json
COPY --from=builder /app/static ./static
ENV NODE_ENV=production
EXPOSE 8080
CMD ["node", "dist/main.js"]
```

#### cloudbuild.yaml

```yaml
steps:
  - name: "gcr.io/cloud-builders/docker"
    args:
      - "build"
      - "-t"
      - "asia-northeast1-docker.pkg.dev/$PROJECT_ID/shiritori/backend:$SHORT_SHA"
      - "-f"
      - "backend/Dockerfile"
      - "./backend"

  - name: "gcr.io/cloud-builders/docker"
    args:
      [
        "push",
        "asia-northeast1-docker.pkg.dev/$PROJECT_ID/shiritori/backend:$SHORT_SHA",
      ]

  - name: "gcr.io/google.com/cloudsdktool/cloud-sdk"
    entrypoint: gcloud
    args:
      - "run"
      - "deploy"
      - "shiritori-backend"
      - "--image"
      - "asia-northeast1-docker.pkg.dev/$PROJECT_ID/shiritori/backend:$SHORT_SHA"
      - "--region"
      - "asia-northeast1"
      - "--platform"
      - "managed"
      - "--allow-unauthenticated"
      - "--set-env-vars"
      - "NODE_ENV=production"
      - "--set-secrets"
      - "DATABASE_URL=DATABASE_URL:latest,JWT_SECRET=JWT_SECRET:latest,REDIS_URL=REDIS_URL:latest"
```

#### 環境変数（Secret Manager）

- `DATABASE_URL`: Supabase PostgreSQL接続文字列
- `JWT_SECRET`: JWT署名鍵（HS256）
- `REDIS_URL`: Google Cloud Memorystore for Redis接続文字列
- `PORT`: 8080（Cloud Runデフォルト）

---

### 10.2 データベース（Supabase）

#### 初期セットアップ

```bash
# Prisma初期化
npx prisma init

# マイグレーション作成
npx prisma migrate dev --name init

# シード実行
npx prisma db seed
```

#### seed/main.ts

```typescript
// アイコン・メッセージ・称号マスタを投入
await prisma.iconMaster.createMany({ data: ICON_CATALOG });
await prisma.messageMaster.createMany({ data: MESSAGE_CATALOG });
await prisma.title.createMany({ data: TITLE_CATALOG });
```

---

### 10.3 モバイルアプリ（Flutter）

#### Android

```bash
# デバッグビルド
flutter build apk --debug

# リリースビルド
flutter build appbundle --release

# Google Play Consoleにアップロード
# Internal Testing → Closed Testing → Open Testing → Production
```

#### iOS

```bash
# デバッグビルド
flutter build ios --debug

# リリースビルド
flutter build ipa --release

# App Store Connectにアップロード
# TestFlight → App Store
```

---

### 10.4 Webフロントエンド（Next.js + Firebase Hosting）

#### デプロイ

```bash
cd web-frontend
npm run build
firebase deploy --only hosting
```

#### firebase.json

```json
{
  "hosting": {
    "public": "out",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## 11. セキュリティ

### 11.1 認証

- **パスワード**: bcryptjsでハッシュ化（saltRounds: 10）
- **JWT**: HS256署名、有効期限30日
- **トークン検証**: 全APIで`verifyAuthToken`ミドルウェア

```typescript
function verifyAuthToken(token: string): { userId: string } | null {
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET!, {
      algorithms: ["HS256"],
    });
    return payload as { userId: string };
  } catch (e) {
    return null;
  }
}
```

### 11.2 アンチチート

- **非アクティブ検知**: 10秒以上のバックグラウンド化で敗北
- **チーターフラグ**: `isCheater`フラグでマッチング除外
- **制限時間**: 40秒厳守（クライアントとサーバー両方でチェック）

### 11.3 レート制限

- Cloud Runの自動スケーリングで負荷分散
- 必要に応じてCloud Armorでレート制限

---

## 12. テスト戦略

### 12.1 バックエンド

- **ユニットテスト**: Jest（しりとりロジック、AIアルゴリズム）
- **統合テスト**: Supertest（API エンドポイント）
- **E2Eテスト**: Smoke Test（`src/smoke.ts`、`src/smoke_pvp.ts`）

```bash
# ユニットテスト
npm test

# Smoke Test
npm run smoke
npm run smoke:pvp
```

### 12.2 フロントエンド

- **Flutterウィジェットテスト**: `flutter test`
- **統合テスト**: `flutter test integration_test`

---

## 13. 今後の拡張性

### 13.1 実装予定機能

- **アイテムシステム**: ガチャで引けるアイテムの機能実装
- **ギルド/クラン**: チーム対戦機能
- **シーズン制**: 定期的なレーティングリセット
- **リーダーボード強化**: 週間・月間ランキング
- **フレンド機能**: フレンド招待・対戦

### 13.2 技術的改善

- **ゲームセッション永続化**: Redisにセッションを保存し、Cloud Run再起動に耐性を持たせる
- **WebSocket対応**: PvPのリアルタイム性向上
- **GraphQL導入**: 複雑なクエリの最適化
- **CI/CD強化**: 自動テスト→自動デプロイパイプライン

---

## 付録: 重要ファイル一覧

### バックエンド

- `backend/prisma/schema.prisma`: データベーススキーマ
- `backend/src/lib/shiritori_core.ts`: しりとりロジック
- `backend/src/domain/services/TitleService.ts`: 称号チェックロジック
- `backend/src/infrastructure/PvpSessionStore.ts`: PvPセッション管理（Redis）
- `backend/src/infrastructure/MatchmakeAssignmentStore.ts`: マッチング割り当て（Redis）
- `backend/shiritori_list.json`: 辞書データ（約12万語）

### モバイルクライアント

- `mobile-client/lib/features/game/pages/game_page.dart`: AI対戦画面
- `mobile-client/lib/features/game/pages/pvp_game_page.dart`: PvP対戦画面
- `mobile-client/lib/features/account/pages/account_settings_page.dart`: アカウント設定
- `mobile-client/lib/features/gacha/pages/gacha_page.dart`: ガチャ画面
- `mobile-client/lib/features/present/pages/present_page.dart`: プレゼントボックス
- `mobile-client/lib/core/services/new_item_service.dart`: NEW表示管理

---

**以上で完全仕様書は終わりです。この仕様書をもとに、コード生成AIは本プロジェクトと同等のアプリケーションを再現可能です。**
