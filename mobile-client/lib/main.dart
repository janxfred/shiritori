import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // `.env` が無い場合でも起動できるようにする（デフォルトURLへフォールバック）
  }

  try {
    await dotenv.load(fileName: '.env.local', mergeWith: dotenv.env);
  } catch (_) {
    // 開発者ローカルの上書き用（任意）
  }

  MobileAds.instance.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

final _router = GoRouter(
  initialLocation: '/',
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
      title: 'わがまましりとり',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
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
