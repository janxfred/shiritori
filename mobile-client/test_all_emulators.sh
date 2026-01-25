#!/bin/bash

# 全エミュレータでアプリをテストするスクリプト

APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
ADB="$HOME/Library/Android/sdk/platform-tools/adb"

# テスト対象エミュレータリスト
EMULATORS=(
    "Pixel"
    "Pixel_2"
    "Pixel_3"
    "Pixel_3a"
    "Pixel_4"
    "Pixel_4_2"
    "Pixel_6a"
    "Pixel_7"
    "Pixel_8_Pro"
    "Pixel_9_Pro_XL"
    "Pixel_9a"
    "No_Medium_Phone"
)

echo "==================================="
echo "全Androidエミュレータテスト開始"
echo "==================================="
echo ""

# APKが存在するか確認
if [ ! -f "$APK_PATH" ]; then
    echo "❌ APKが見つかりません: $APK_PATH"
    echo "先に 'flutter build apk --release' を実行してください"
    exit 1
fi

PASSED=0
FAILED=0

for EMU in "${EMULATORS[@]}"; do
    echo "-----------------------------------"
    echo "📱 テスト中: $EMU"
    echo "-----------------------------------"
    
    # エミュレータ起動
    flutter emulators --launch "$EMU" > /dev/null 2>&1 &
    
    # 起動を待つ（最大60秒）
    echo "⏳ エミュレータ起動中..."
    for i in {1..30}; do
        sleep 2
        DEVICE_ID=$($ADB devices | grep emulator | tail -1 | awk '{print $1}')
        if [ -n "$DEVICE_ID" ]; then
            # デバイスが完全に起動するまで待つ
            BOOT_COMPLETE=$($ADB -s "$DEVICE_ID" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
            if [ "$BOOT_COMPLETE" = "1" ]; then
                echo "✓ エミュレータ起動完了: $DEVICE_ID"
                break
            fi
        fi
    done
    
    if [ -z "$DEVICE_ID" ]; then
        echo "❌ エミュレータの起動に失敗: $EMU"
        FAILED=$((FAILED + 1))
        continue
    fi
    
    # APKインストール
    echo "📦 APKインストール中..."
    $ADB -s "$DEVICE_ID" install -r "$APK_PATH" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ APKインストールに失敗: $EMU"
        $ADB -s "$DEVICE_ID" emu kill > /dev/null 2>&1
        FAILED=$((FAILED + 1))
        continue
    fi
    echo "✓ インストール完了"
    
    # アプリ起動
    echo "🚀 アプリ起動中..."
    $ADB -s "$DEVICE_ID" shell am start -n jp.akumateki.shiritori/.MainActivity > /dev/null 2>&1
    
    # 初期化ログを待つ
    sleep 10
    
    # ログ確認
    echo "📋 初期化ログ確認中..."
    LOGS=$($ADB -s "$DEVICE_ID" logcat -d | grep -E "flutter.*(✓|⚠|ERROR)" | tail -20)
    
    # 成功判定：必要な初期化が完了しているか
    ENV_LOADED=$(echo "$LOGS" | grep -c "✓ .env loaded")
    RC_INIT=$(echo "$LOGS" | grep -c "✓ RevenueCat initialized")
    
    if [ "$ENV_LOADED" -gt 0 ] && [ "$RC_INIT" -gt 0 ]; then
        echo "✅ テスト成功: $EMU"
        echo "$LOGS" | grep "flutter.*✓"
        PASSED=$((PASSED + 1))
    else
        echo "❌ テスト失敗: $EMU"
        echo "取得したログ:"
        echo "$LOGS"
        FAILED=$((FAILED + 1))
    fi
    
    # エミュレータ終了
    echo "🛑 エミュレータ終了中..."
    $ADB -s "$DEVICE_ID" emu kill > /dev/null 2>&1
    sleep 3
    
    echo ""
done

echo "==================================="
echo "テスト結果サマリー"
echo "==================================="
echo "✅ 成功: $PASSED / ${#EMULATORS[@]}"
echo "❌ 失敗: $FAILED / ${#EMULATORS[@]}"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 全てのエミュレータでテスト成功！"
    exit 0
else
    echo "⚠️  一部のエミュレータでテストに失敗しました"
    exit 1
fi
