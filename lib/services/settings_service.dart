import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lang.dart';

/// Toàn bộ cài đặt của người dùng (lưu bằng SharedPreferences).
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  bool sound = true; // âm thanh trò chơi
  bool music = true; // nhạc nền
  bool haptics = true; // rung
  double volume = 0.8;
  String serverUrl = '';
  String lastHost = ''; // IP chủ bàn lần gần nhất (chơi qua Wi-Fi)

  String language = 'vi'; // 'vi' | 'en'
  bool largeText = false;
  int themeIndex = 0;

  bool chatSound = true;
  bool friendsOnlyInvites = false;

  bool reminderOn = false;
  int reminderHour = 20;
  int reminderMinute = 0;
  String lastPlayDate = '';
  String reminderShownDate = '';

  int rating = 0;

  late SharedPreferences _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    sound = _p.getBool('set_sound') ?? true;
    music = _p.getBool('set_music') ?? true;
    haptics = _p.getBool('set_haptics') ?? true;
    volume = _p.getDouble('set_volume') ?? 0.8;
    serverUrl = _p.getString('set_server') ?? '';
    lastHost = _p.getString('last_host') ?? '';
    language = _p.getString('set_lang') ?? 'vi';
    largeText = _p.getBool('set_large') ?? false;
    themeIndex = _p.getInt('set_theme') ?? 0;
    chatSound = _p.getBool('set_chat_sound') ?? true;
    friendsOnlyInvites = _p.getBool('set_friends_only') ?? false;
    reminderOn = _p.getBool('rem_on') ?? false;
    reminderHour = _p.getInt('rem_h') ?? 20;
    reminderMinute = _p.getInt('rem_m') ?? 0;
    lastPlayDate = _p.getString('last_play') ?? '';
    reminderShownDate = _p.getString('rem_shown') ?? '';
    rating = _p.getInt('rating') ?? 0;
    Lang.notifier.value = language;
  }

  void _changed() => notifyListeners();

  Future<void> setSound(bool v) async {
    sound = v;
    _changed();
    await _p.setBool('set_sound', v);
  }

  Future<void> setMusic(bool v) async {
    music = v;
    _changed();
    await _p.setBool('set_music', v);
  }

  Future<void> setHaptics(bool v) async {
    haptics = v;
    _changed();
    await _p.setBool('set_haptics', v);
  }

  Future<void> setVolume(double v) async {
    volume = v;
    _changed();
    await _p.setDouble('set_volume', v);
  }

  /// Địa chỉ máy chủ online, ví dụ 192.168.1.5:8080 hoặc wss://ten-mien.com
  Future<void> setServerUrl(String v) async {
    serverUrl = v.trim();
    _changed();
    await _p.setString('set_server', serverUrl);
  }

  Future<void> setLastHost(String v) async {
    lastHost = v.trim();
    await _p.setString('last_host', lastHost);
  }

  Future<void> setLanguage(String code) async {
    language = code;
    Lang.notifier.value = code;
    _changed();
    await _p.setString('set_lang', code);
  }

  Future<void> setLargeText(bool v) async {
    largeText = v;
    _changed();
    await _p.setBool('set_large', v);
  }

  Future<void> setTheme(int i) async {
    themeIndex = i;
    _changed();
    await _p.setInt('set_theme', i);
  }

  Future<void> setChatSound(bool v) async {
    chatSound = v;
    _changed();
    await _p.setBool('set_chat_sound', v);
  }

  Future<void> setFriendsOnly(bool v) async {
    friendsOnlyInvites = v;
    _changed();
    await _p.setBool('set_friends_only', v);
  }

  Future<void> setReminder({bool? on, int? hour, int? minute}) async {
    if (on != null) reminderOn = on;
    if (hour != null) reminderHour = hour;
    if (minute != null) reminderMinute = minute;
    _changed();
    await _p.setBool('rem_on', reminderOn);
    await _p.setInt('rem_h', reminderHour);
    await _p.setInt('rem_m', reminderMinute);
  }

  Future<void> setRating(int v) async {
    rating = v;
    _changed();
    await _p.setInt('rating', v);
  }

  static String today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  Future<void> markPlayedToday() async {
    lastPlayDate = today();
    await _p.setString('last_play', lastPlayDate);
  }

  Future<void> markReminderShown() async {
    reminderShownDate = today();
    await _p.setString('rem_shown', reminderShownDate);
  }

  /// Chuẩn hóa thành URL WebSocket đầy đủ ('' nếu chưa cài).
  String get wsUrl {
    var u = serverUrl.trim();
    if (u.isEmpty) return '';
    if (u.startsWith('http://')) u = 'ws://${u.substring(7)}';
    if (u.startsWith('https://')) u = 'wss://${u.substring(8)}';
    if (!u.startsWith('ws://') && !u.startsWith('wss://')) u = 'ws://$u';
    return u;
  }
}
