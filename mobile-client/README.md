# Mobile Client

Flutterで構築されたモバイルアプリケーションテンプレート。

## セットアップ

```bash
cd mobile-client
flutter pub get
flutter gen-l10n
```

## iOSシミュレータのセットアップ

### 1. Xcodeのインストール

App StoreからXcodeをインストールします。

```bash
# コマンドラインツールのインストール
xcode-select --install

# ライセンスへの同意
sudo xcodebuild -license accept
```

### 2. iOSシミュレータの起動

```bash
# シミュレータを開く
open -a Simulator

# または利用可能なデバイス一覧を確認
flutter devices

# 特定のシミュレータを起動
xcrun simctl boot "iPhone 15"
```

### 3. iOSシミュレータでアプリを実行

```bash
# 利用可能なデバイスを確認
flutter devices

# iOSシミュレータで実行
flutter run -d "iPhone 15"

# または自動でシミュレータを選択
flutter run
```

### CocoaPodsのセットアップ

iOS依存関係の管理にCocoaPodsが必要です。

```bash
# CocoaPodsのインストール
sudo gem install cocoapods

# Podのインストール
cd ios
pod install
cd ..
```

## 開発

```bash
# 実行（デバイスが1つの場合）
flutter run

# デバイスを指定して実行
flutter run -d <device_id>

# 利用可能なデバイス一覧を確認
flutter devices

# 分析
flutter analyze

# ビルド
flutter build apk     # Android
flutter build ios     # iOS
```

複数のデバイスが接続されている場合、`flutter run` でデバイス選択を求められます。
`-d` オプションでデバイスIDまたはデバイス名を指定してください。

## ディレクトリ構成

```
lib/
├── main.dart                    # エントリーポイント
├── core/
│   └── api/
│       └── api_client.dart      # API通信クライアント
├── features/
│   └── users/
│       ├── models/              # データモデル
│       ├── providers/           # Riverpodプロバイダ
│       └── pages/               # 画面
└── l10n/
    ├── app_en.arb               # 英語翻訳
    ├── app_ja.arb               # 日本語翻訳
    └── generated/               # 生成されたローカライゼーションコード
```

## ローカライゼーション

### 翻訳の追加

1. `lib/l10n/app_en.arb` と `lib/l10n/app_ja.arb` に翻訳キーを追加
2. `flutter gen-l10n` を実行

### 使用方法

```dart
import '../../../l10n/generated/app_localizations.dart';

// Widget内で
final l10n = AppLocalizations.of(context)!;
Text(l10n.userList);
```

## 技術スタック

| カテゴリ | ライブラリ |
|---------|-----------|
| 状態管理 | flutter_riverpod |
| ルーティング | go_router |
| API通信 | dio |
| ローカライゼーション | flutter_localizations |

## API設定

デフォルトのベースURLは `http://10.0.2.2:3000`（Androidエミュレータ用）です。

iOSシミュレータの場合は `lib/core/api/api_client.dart` で `localhost` に変更してください。
