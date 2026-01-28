import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/game/pages/game_page.dart';
import 'features/users/pages/user_list_page.dart';
import 'features/account/pages/account_settings_page.dart';
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/signup_page.dart';
import 'features/ranked/pages/ranked_match_page.dart';
import 'features/pvp/pages/pvp_game_page.dart';
import 'features/pvp/models/pvp_models.dart';
import 'features/gacha/pages/gacha_page.dart';
import 'features/account/pages/icon_catalog_page.dart';
import 'features/account/pages/title_catalog_page.dart';
import 'features/account/pages/message_catalog_page.dart';
import 'features/present/pages/present_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // エラーハンドリング強化（起動を妨げないようにする）
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Pixelデバイス等でのエラーを表示（開発用）
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✓ .env loaded');
  } catch (e) {
    debugPrint('⚠ .env not found: $e');
    // `.env` が無い場合でも起動できるようにする（デフォルトURLへフォールバック）
  }

  try {
    await dotenv.load(fileName: '.env.local', mergeWith: dotenv.env);
    debugPrint('✓ .env.local loaded');
  } catch (e) {
    debugPrint('⚠ .env.local not found: $e');
    // 開発者ローカルの上書き用（任意）
  }

  // RevenueCat初期化（Play Console制限解除用の最小実装）
  // エラーがあっても起動を継続するように改善
  try {
    await Purchases.configure(
      PurchasesConfiguration('goog_erLlGbZLjiJzdJplicLuSKgaHSs')
        ..appUserID = null,
    );
    debugPrint('✓ RevenueCat initialized');
  } catch (e, stackTrace) {
    // 初期化エラーは無視（開発環境では有効なAPIキーがない）
    debugPrint('⚠ RevenueCat initialization failed: $e');
    debugPrint('Stack: $stackTrace');
  }

  // Google Mobile Ads初期化をtry-catchで囲む
  try {
    await MobileAds.instance.initialize();
    debugPrint('✓ Google Mobile Ads initialized');
  } catch (e, stackTrace) {
    debugPrint('⚠ Google Mobile Ads initialization failed: $e');
    debugPrint('Stack: $stackTrace');
  }

  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // 認証プロバイダーの状態を取得するためにProviderContainerが必要ですが、
    // ここでは直接アクセスできないため、ログイン状態は各ページで処理します
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const GamePage(),
    ),
    GoRoute(
      path: '/ranked',
      builder: (context, state) => const RankedMatchPage(),
    ),
    GoRoute(
      path: '/gacha',
      builder: (context, state) => const GachaPage(),
    ),
    GoRoute(
      path: '/pvp/:sessionId',
      builder: (context, state) {
        final sessionId = state.pathParameters['sessionId']!;
        final extra = state.extra;
        return PvpGamePage(
          sessionId: sessionId,
          initial: extra is PvpStartResponse ? extra : null,
          opponent: extra is PvpOpponent ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) => const AccountSettingsPage(),
    ),
    GoRoute(
      path: '/icons',
      builder: (context, state) => const IconCatalogPage(),
    ),
    GoRoute(
      path: '/titles',
      builder: (context, state) => const TitleCatalogPage(),
    ),
    GoRoute(
      path: '/messages',
      builder: (context, state) => const MessageCatalogPage(),
    ),
    GoRoute(
      path: '/present',
      builder: (context, state) => const PresentPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => const UserListPage(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '悪魔的しりとり',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSerifJpTextTheme(
          ThemeData.dark().textTheme.copyWith(
            // 基本的な文字サイズと色を見やすく調整
            bodyLarge: const TextStyle(
              fontSize: 17,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            bodyMedium: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
            bodySmall: const TextStyle(
              fontSize: 15,
              color: Color(0xFFE0E0E0),
              fontWeight: FontWeight.w400,
            ),
            labelLarge: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            labelMedium: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            labelSmall: const TextStyle(
              fontSize: 14,
              color: Color(0xFFE0E0E0),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
      ],
      routerConfig: _router,
    );
  }
}
