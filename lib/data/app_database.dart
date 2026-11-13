import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Cơ sở dữ liệu SQLite của app Playtime.
///
/// Bảng:
///  - matches(id, game_id, mode, result, opponent, played_at): lịch sử ván đã chơi
///  - scores(game_id, best): điểm cao nhất của các game 1 người
///  - friends(id, name, emoji, added_at): danh sách bạn bè (kết bạn bằng mã QR)
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'playtime.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE matches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            game_id TEXT NOT NULL,
            mode TEXT NOT NULL,
            result TEXT NOT NULL,
            opponent TEXT,
            played_at INTEGER NOT NULL
          )''');
        await d.execute('''
          CREATE TABLE scores (
            game_id TEXT PRIMARY KEY,
            best INTEGER NOT NULL
          )''');
        await d.execute('''
          CREATE TABLE friends (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            emoji TEXT NOT NULL,
            added_at INTEGER NOT NULL
          )''');
      },
    );
  }
}
