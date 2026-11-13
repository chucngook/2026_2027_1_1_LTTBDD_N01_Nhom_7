import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import 'player_service.dart';

class Friend {
  final String id, name, emoji;
  const Friend(this.id, this.name, this.emoji);
}

/// Danh sách bạn bè (SQLite) và mã QR kết bạn.
class FriendService extends ChangeNotifier {
  FriendService._();
  static final FriendService instance = FriendService._();

  List<Friend> items = [];

  Future<void> load() async {
    final d = await AppDatabase.instance.db;
    final rows = await d.query('friends', orderBy: 'added_at DESC');
    items = rows
        .map((r) => Friend(r['id'] as String, r['name'] as String, r['emoji'] as String))
        .toList();
    notifyListeners();
  }

  bool isFriend(String id) => items.any((f) => f.id == id);

  Future<void> add(String id, String name, String emoji) async {
    if (id.isEmpty || id == PlayerService.instance.id) return;
    final d = await AppDatabase.instance.db;
    await d.insert(
        'friends',
        {'id': id, 'name': name, 'emoji': emoji, 'added_at': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.replace);
    await load();
  }

  Future<void> remove(String id) async {
    final d = await AppDatabase.instance.db;
    await d.delete('friends', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  /// Nội dung mã QR của mình.
  static String myPayload() => jsonEncode({
        'app': 'playtime',
        'id': PlayerService.instance.id,
        'name': PlayerService.instance.name,
        'emoji': PlayerService.instance.emoji,
      });

  /// Đọc nội dung QR của người khác; trả về null nếu không hợp lệ.
  static Friend? parse(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is Map && m['app'] == 'playtime' && (m['id'] ?? '').toString().isNotEmpty) {
        return Friend(m['id'].toString(), (m['name'] ?? 'Bạn mới').toString(),
            (m['emoji'] ?? '🙂').toString());
      }
    } catch (_) {}
    return null;
  }
}
