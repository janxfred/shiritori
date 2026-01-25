import 'package:shared_preferences/shared_preferences.dart';

/// 新規獲得アイテムの「NEW」表示を管理するサービス
/// ローカルストレージ（SharedPreferences）で各カタログの最終表示日時を記録
class NewItemService {
  static const String _keyTitlesLastViewed = 'titles_last_viewed';
  static const String _keyIconsLastViewed = 'icons_last_viewed';
  static const String _keyMessagesLastViewed = 'messages_last_viewed';

  /// 称号一覧の最終表示日時を取得
  static Future<DateTime?> getTitlesLastViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyTitlesLastViewed);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// アイコン一覧の最終表示日時を取得
  static Future<DateTime?> getIconsLastViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyIconsLastViewed);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// メッセージ一覧の最終表示日時を取得
  static Future<DateTime?> getMessagesLastViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyMessagesLastViewed);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// 称号一覧を表示したことを記録
  static Future<void> markTitlesViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTitlesLastViewed, DateTime.now().millisecondsSinceEpoch);
  }

  /// アイコン一覧を表示したことを記録
  static Future<void> markIconsViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyIconsLastViewed, DateTime.now().millisecondsSinceEpoch);
  }

  /// メッセージ一覧を表示したことを記録
  static Future<void> markMessagesViewed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMessagesLastViewed, DateTime.now().millisecondsSinceEpoch);
  }
}
