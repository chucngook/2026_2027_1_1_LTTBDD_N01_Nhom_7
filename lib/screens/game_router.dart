import 'package:flutter/cupertino.dart';
import '../services/app_nav.dart';
import '../services/online_service.dart';
import '../services/player_service.dart';
import '../services/table_service.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/mode_select_screen.dart';
import 'games/bingo/bingo_screen.dart';
import 'games/caro/caro_screen.dart';
import 'games/catch_item/catch_item_screen.dart';
import 'games/chess/chess_screen.dart';
import 'games/flappy/flappy_screen.dart';
import 'games/game_2048/game_2048_screen.dart';
import 'games/math_quiz/math_quiz_screen.dart';
import 'games/memory_flip/memory_screen.dart';
import 'games/oanquan/oanquan_screen.dart';
import 'games/planes/planes_screen.dart';
import 'games/snake/snake_screen.dart';
import 'games/who_wants_to_be_a_millionaire/millionaire_screen.dart';

/// Mở game từ danh mục: game 2 người đi qua màn chọn chế độ, game 1 người vào thẳng.
class GameRouter {
  GameRouter._();

  static const Map<String, String> _desc = {
    'oanquan':
        'Trò chơi dân gian Việt Nam: rải quân và ăn quan. Ai nhiều điểm hơn sẽ thắng!',
    'caro': 'Xếp 5 quân liên tiếp theo hàng, cột hoặc đường chéo trên bàn 13×13.',
    'planes':
        'Giấu 3 máy bay trên bản đồ 10×10 rồi đoán vị trí của đối thủ. Bắn trúng đầu là hạ máy bay!',
    'chess': 'Cờ vua đầy đủ luật: nhập thành, bắt tốt qua đường, phong cấp.',
  };

  static Widget? versus(String id, MatchConfig cfg) {
    switch (id) {
      case 'caro':
        return CaroScreen(config: cfg);
      case 'chess':
        return ChessScreen(config: cfg);
      case 'oanquan':
        return OanQuanScreen(config: cfg);
      case 'planes':
        return PlanesScreen(config: cfg);
    }
    return null;
  }

  static Widget? solo(String id) {
    final u = PlayerService.instance.name;
    switch (id) {
      case 'snakegame':
        return SnakeScreen(username: u, currentTokens: 0);
      case '2048game':
        return Game2048Screen(username: u, currentTokens: 0);
      case 'flappybird':
        return FlappyScreen(username: u, currentTokens: 0);
      case 'memoryflip':
        return MemoryScreen(username: u, currentTokens: 0);
      case 'catchitem':
        return CatchItemScreen(username: u, currentTokens: 0);
      case 'mathquiz':
        return MathQuizScreen(username: u, currentTokens: 0);
      case 'bingo':
        return BingoScreen(username: u, currentTokens: 0);
      case 'millionaire':
        return MillionaireScreen(username: u, currentTokens: 0);
    }
    return null;
  }

  static void open(BuildContext context, Map<String, dynamic> game) {
    final id = game['id'] as String;
    if (game['soon'] == true) {
      showIosAlert(context, 'Sắp có',
          '${game['name']} đang được chuẩn bị. Hãy quay lại sau nhé!');
      return;
    }
    if (game['versus'] == true) {
      Navigator.of(context).push(CupertinoPageRoute<void>(
        builder: (_) => ModeSelectScreen(
          gameId: id,
          title: game['name'] as String,
          description: _desc[id] ?? '',
          buildGame: (cfg) => versus(id, cfg)!,
        ),
      ));
    } else {
      final w = solo(id);
      if (w != null) {
        Navigator.of(context).push(CupertinoPageRoute<void>(
            settings: const RouteSettings(name: 'game'), builder: (_) => w));
      }
    }
  }

  /// Mở game online trong bàn đang ngồi (cả hai máy cùng mở khi một người chọn game).
  static void openTableGame(String id) {
    final t = TableService.instance;
    final nav = rootNavKey.currentState;
    final w = (nav == null || t.session == null)
        ? null
        : versus(id, MatchConfig(mode: PlayMode.online, session: t.session));
    if (w == null) {
      t.gameClosed();
      return;
    }
    nav!
        .push(CupertinoPageRoute<void>(
            settings: const RouteSettings(name: 'game'), builder: (_) => w))
        .then((_) => t.gameClosed());
  }
}
