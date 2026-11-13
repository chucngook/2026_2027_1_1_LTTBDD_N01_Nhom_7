import 'package:flutter/cupertino.dart';

class AppAssets {
  /// Danh mục game. `players`: số người chơi hiển thị trên huy hiệu.
  /// `soon: true` = chưa có, hiển thị mờ "SẮP CÓ".
  static const List<Map<String, dynamic>> _games = [
    // ── Chơi cùng bạn / với máy ──
    {'id': 'oanquan', 'name': 'Ô ăn quan', 'players': '2', 'versus': true, 'tint': 0xFF8DC152},
    {'id': 'caro', 'name': 'Cờ ca-rô', 'players': '2', 'versus': true, 'tint': 0xFF6FD28A},
    {'id': 'planes', 'name': 'Bắn máy bay', 'players': '2', 'versus': true, 'tint': 0xFF7C79F0},
    {'id': 'chess', 'name': 'Cờ vua', 'players': '2', 'versus': true, 'tint': 0xFFE8B13E},
    {'id': 'cotuong', 'name': 'Cờ tướng', 'players': '2', 'versus': true, 'soon': true, 'tint': 0xFFEE7B4C},
    {'id': 'covay', 'name': 'Cờ vây', 'players': '2', 'versus': true, 'soon': true, 'tint': 0xFFD9A765},
    // ── Chơi một mình ──
    {'id': 'snakegame', 'name': 'Rắn săn mồi', 'players': '1', 'versus': false, 'tint': 0xFF2FBF8B},
    {'id': '2048game', 'name': '2048', 'players': '1', 'versus': false, 'tint': 0xFF8E5BEA},
    {'id': 'flappybird', 'name': 'Chim bay', 'players': '1', 'versus': false, 'tint': 0xFFF5A24A},
    {'id': 'memoryflip', 'name': 'Lật hình', 'players': '1', 'versus': false, 'tint': 0xFF2FB6D6},
    {'id': 'catchitem', 'name': 'Hứng táo', 'players': '1', 'versus': false, 'tint': 0xFF4A9BEA},
    {'id': 'mathquiz', 'name': 'Toán nhanh', 'players': '1', 'versus': false, 'tint': 0xFFD64B7C},
    {'id': 'bingo', 'name': 'Bingo', 'players': '1', 'versus': false, 'tint': 0xFF5AA6B0},
    {'id': 'millionaire', 'name': 'Triệu phú', 'players': '1', 'versus': false, 'tint': 0xFF2BB57E},
  ];

  static String gameImage(String id) => 'assets/images/games/$id.png';

  static List<Map<String, dynamic>> getAllGamesWithAssets() => _games
      .map((g) => {
            ...g,
            'image': gameImage(g['id'] as String),
            'colors': [Color(g['tint'] as int), Color(g['tint'] as int)],
          })
      .toList();
}

/// Đường dẫn các ảnh dùng trong app.
class AppImages {
  AppImages._();
  static const String logo = 'assets/images/app_logo.png';
  static const String coin = 'assets/images/items/coin.png';
  static const String apple = 'assets/images/items/apple.png';
  static const String star = 'assets/images/items/star.png';
  static const String bomb = 'assets/images/items/bomb.png';
  static const String basket = 'assets/images/items/basket.png';
  static const String heart = 'assets/images/cards/heart.png';
  static const String cloud = 'assets/images/cards/cloud.png';
  static const String bird = 'assets/images/items/bird.png';

  /// Quân cờ vua: color 'w' | 'b', kind 'k','q','r','b','n','p'
  static String chess(String color, String kind) =>
      'assets/images/chess/$color$kind.png';

  /// 10 hình dùng cho thẻ bài trò Lật hình
  static const List<String> cardSymbols = [
    'assets/images/cards/star.png',
    'assets/images/cards/heart.png',
    'assets/images/cards/moon.png',
    'assets/images/cards/sun.png',
    'assets/images/cards/drop.png',
    'assets/images/cards/bolt.png',
    'assets/images/cards/diamond.png',
    'assets/images/cards/flower.png',
    'assets/images/cards/cloud.png',
    'assets/images/cards/crown.png',
  ];
}
