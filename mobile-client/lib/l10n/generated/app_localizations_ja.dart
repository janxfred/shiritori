// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'モバイルクライアント';

  @override
  String get userList => 'ユーザー一覧';

  @override
  String get userDetail => 'ユーザー詳細';

  @override
  String get name => '名前';

  @override
  String get email => 'メールアドレス';

  @override
  String get createdAt => '作成日時';

  @override
  String get loading => '読み込み中...';

  @override
  String get error => 'エラー';

  @override
  String get retry => '再試行';

  @override
  String get noUsers => 'ユーザーが見つかりません';
}
