# Mobile Client

Flutter で構築されたモバイルアプリケーションテンプレート。

## セットアップ

```bash
cd mobile-client
flutter pub get
flutter gen-l10n
```

## Firebase（Android）設定

このリポジトリでは `mobile-client/android/app/google-services.json` は機密情報を含むため **コミットしません**。

1. Firebase Console から Android アプリ（`jp.akumateki.shiritori`）用の `google-services.json` を取得
2. `mobile-client/android/app/google-services.json.example` を参考に、`mobile-client/android/app/google-services.json` を配置

## iOS シミュレータのセットアップ

### 1. Xcode のインストール

App Store から Xcode をインストールします。

```bash
# コマンドラインツールのインストール
xcode-select --install

# ライセンスへの同意
sudo xcodebuild -license accept
```

### 2. iOS シミュレータの起動

```bash
# シミュレータを開く
open -a Simulator

# または利用可能なデバイス一覧を確認
flutter devices

# 特定のシミュレータを起動
xcrun simctl boot "iPhone 15"
```

### 3. iOS シミュレータでアプリを実行

```bash
# 利用可能なデバイスを確認
flutter devices

# iOSシミュレータで実行
flutter run -d "iPhone 15"

# または自動でシミュレータを選択
flutter run
```

### CocoaPods のセットアップ

iOS 依存関係の管理に CocoaPods が必要です。

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

## Google Play Console（AAB）

Google Play Console にアップロードする場合は、Android App Bundle（`.aab`）を生成します。

```bash
cd mobile-client

# Release用AAB
cd android
./gradlew bundleRelease
```

生成物:

- `mobile-client/build/app/outputs/bundle/release/app-release.aab`
- （このリポジトリでは）`mobile-client/release/akumateki-shiritori.aab`

※更新リリース時は `pubspec.yaml` の `version: x.y.z+N` の `N`（versionCode）を増やしてください。

複数のデバイスが接続されている場合、`flutter run` でデバイス選択を求められます。
`-d` オプションでデバイス ID またはデバイス名を指定してください。

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

| カテゴリ             | ライブラリ            |
| -------------------- | --------------------- |
| 状態管理             | flutter_riverpod      |
| ルーティング         | go_router             |
| API 通信             | dio                   |
| ローカライゼーション | flutter_localizations |

## API 設定

デフォルトのベース URL は `http://10.0.2.2:3002`（Android エミュレータ用）です。

iOS シミュレータの場合は `lib/core/api/api_client.dart` で `localhost` に変更してください。
