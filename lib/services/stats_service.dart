import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../data/app_database.dart';
import 'settings_service.dart';

/// Thống kê lưu trong SQLite: lịch sử ván, điểm cao, thắng/thua/hòa.
class StatsService {
  StatsService._();
  static final StatsService instance = StatsService._();

  Future<Database> get _db => AppDatabase.instance.db;

  Future<void> submitScore(String gameId, int score) async {
    final d = await _db;
    final r = await d.query('scores', where: 'game_id = ?', whereArgs: [gameId]);
    final best = r.isEmpty ? 0 : (r.first['best'] as int);
    if (score > best) {
      await d.insert('scores', {'game_id': gameId, 'best': score},
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<int> bestScore(String gameId) async {
    final d = await _db;
    final r = await d.query('scores', where: 'game_id = ?', whereArgs: [gameId]);
    return r.isEmpty ? 0 : (r.first['best'] as int);
  }

  /// result: 'win' | 'loss' | 'draw' | 'played'
  Future<void> recordMatch(String gameId, String result,
      {String mode = 'versus', String? opponent}) async {
    final d = await _db;
    await d.insert('matches', {
      'game_id': gameId,
      'mode': mode,
      'result': result,
      'opponent': opponent,
      'played_at': DateTime.now().millisecondsSinceEpoch,
    });
    await AppSettings.instance.markPlayedToday();
  }

  Future<Map<String, int>> record(String gameId) async {
    final d = await _db;
    final rows = await d.rawQuery(
        'SELECT result, COUNT(*) AS c FROM matches WHERE game_id = ? GROUP BY result',
        [gameId]);
    final m = {'win': 0, 'loss': 0, 'draw': 0, 'played': 0};
    for (final r in rows) {
      m[r['result'] as String] = (r['c'] as int);
    }
    return m;
  }

  Future<int> totalPlayed() async {
    final d = await _db;
    return Sqflite.firstIntValue(await d.rawQuery('SELECT COUNT(*) FROM matches')) ?? 0;
  }

  Future<int> totalWins() async {
    final d = await _db;
    return Sqflite.firstIntValue(
            await d.rawQuery("SELECT COUNT(*) FROM matches WHERE result = 'win'")) ??
        0;
  }

  Future<List<Map<String, Object?>>> recent({int limit = 60}) async {
    final d = await _db;
    return d.query('matches', orderBy: 'played_at DESC', limit: limit);
  }

  Future<void> clearHistory() async {
    final d = await _db;
    await d.delete('matches');
  }

  // ── Giao diện danh sách game (lưu nhanh bằng SharedPreferences) ──
  Future<List<String>> favorites() async =>
      (await SharedPreferences.getInstance()).getStringList('favorites') ?? [];

  Future<List<String>> toggleFavorite(String gameId) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList('favorites') ?? [];
    list.contains(gameId) ? list.remove(gameId) : list.add(gameId);
    await p.setStringList('favorites', list);
    return list;
  }

  Future<String> sortMode() async =>
      (await SharedPreferences.getInstance()).getString('sort_mode') ?? 'default';

  Future<void> setSortMode(String m) async =>
      (await SharedPreferences.getInstance()).setString('sort_mode', m);
}
