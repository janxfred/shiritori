# Flutter関連
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dartコード
-keep class * extends java.util.ListResourceBundle {
    protected Object[][] getContents();
}

# Dart VM (64ビットデバイス対応)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-dontwarn io.flutter.embedding.**

# JSON serialization（freezed/json_annotationで生成されたコードを保護）
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep class * implements com.google.gson.JsonDeserializer { *; }
-keep class * implements com.google.gson.JsonSerializer { *; }

# Freezedで生成されたモデルクラスを保護
-keep class **$serializer { *; }
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Kotlin Reflectionを保護（Kotlinコルーチン等で使用）
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }
-keepclassmembers class kotlin.Metadata { *; }

# RevenueCat（Pixelデバイス等で課金機能関連のクラッシュを防ぐ）
-keep class com.revenuecat.** { *; }
-keep interface com.revenuecat.** { *; }
-dontwarn com.revenuecat.**

# Google Play Core (Deferred Components)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Google Mobile Ads（広告SDKの全機能を保護）
-keep class com.google.android.gms.** { *; }
-keep class com.google.ads.** { *; }
-dontwarn com.google.android.gms.**
-dontwarn com.google.ads.**

# Firebase関連（AdMobがFirebaseに依存）
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# OkHttp & Retrofit（dioの依存関係）
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# dio（HTTP通信ライブラリ）
-keep class dio.** { *; }
-dontwarn dio.**
