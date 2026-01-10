// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Mobile Client';

  @override
  String get userList => 'User List';

  @override
  String get userDetail => 'User Detail';

  @override
  String get name => 'Name';

  @override
  String get email => 'Email';

  @override
  String get createdAt => 'Created At';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get noUsers => 'No users found';
}
