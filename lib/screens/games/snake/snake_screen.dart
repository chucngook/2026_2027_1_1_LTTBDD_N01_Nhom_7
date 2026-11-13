import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import '../../../services/fx.dart';
import '../../../data/game_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/difficulty_selector_screen.dart';
import '../../../widgets/ios_widgets.dart';

class SnakeScreen extends StatefulWidget {
  final String username;
  final int currentTokens;

  const SnakeScreen(
      {super.key, required this.username, required this.currentTokens});

  @override
  State<SnakeScreen> createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  static const int _cols = 20;
  static const int _rows = 25;

  final Random _rand = Random();
  bool _isStarted = false;
  String _difficulty = 'EASY';

  List<Point<int>> _snake = [];
  Point<int> _food = const Point(5, 5);
  String _direction = 'RIGHT';
  String _nextDirection = 'RIGHT';

  bool _gameOver = false;
  int _score = 0;
  int _speedMs = 200;
  late int _balance;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _balance = widget.currentTokens;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame(String diff) {
    setState(() {
      _difficulty = diff;
      _speedMs = diff == 'EASY' ? 220 : (diff == 'MEDIUM' ? 150 : 100);
      _isStarted = true;
      _initGame();
    });
  }

  void _initGame() {
    _snake = [const Point(10, 12), const Point(9, 12), const Point(8, 12)];
    _direction = 'RIGHT';
    _nextDirection = 'RIGHT';
    _score = 0;
    _gameOver = false;
    _spawnFood();

    _timer?.cancel();
    _timer = Timer.periodic(Duration(milliseconds: _speedMs), (_) {
      if (!_gameOver && mounted) _update();
    });
  }

  void _spawnFood() {
    Point<int> p;
    do {
      p = Point(_rand.nextInt(_cols), _rand.nextInt(_rows));
    } while (_snake.contains(p));
    _food = p;
  }

  void _update() {
    bool died = false;
    setState(() {
      _direction = _nextDirection;
      final head = _snake.first;
      Point<int> next;
      switch (_direction) {
        case 'UP':
          next = Point(head.x, head.y - 1);
          break;
        case 'DOWN':
          next = Point(head.x, head.y + 1);
          break;
        case 'LEFT':
          next = Point(head.x - 1, head.y);
          break;
        default:
          next = Point(head.x + 1, head.y);
      }

      if (next.x < 0 || next.x >= _cols || next.y < 0 || next.y >= _rows ||
          _snake.contains(next)) {
        died = true;
        return;
      }

      _snake.insert(0, next);
      if (next == _food) {
        Fx.light(); Fx.play(Sound.eat);
        _score += 10;
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });

    if (died) {
      Fx.heavy(); Fx.play(Sound.lose);
      _gameOver = true;
      _finish();
    }
  }

  void _changeDirection(String d) {
    if ((_direction == 'UP' && d == 'DOWN') ||
        (_direction == 'DOWN' && d == 'UP') ||
        (_direction == 'LEFT' && d == 'RIGHT') ||
        (_direction == 'RIGHT' && d == 'LEFT')) {
      return;
    }
    _nextDirection = d;
  }

  void _onPan(DragUpdateDetails d) {
    const t = 3.0;
    if (d.delta.dx.abs() > d.delta.dy.abs()) {
      if (d.delta.dx > t) _changeDirection('RIGHT');
      if (d.delta.dx < -t) _changeDirection('LEFT');
    } else {
      if (d.delta.dy > t) _changeDirection('DOWN');
      if (d.delta.dy < -t) _changeDirection('UP');
    }
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final mult = GameService.multiplier(_difficulty);
    final total = max(20, _score) * mult;

    await GameService.reward(
      username: widget.username,
      balanceBefore: _balance,
      amount: total,
      gameId: 'snakegame',
      score: _score * mult,
    );
    _balance += total;
    if (!mounted) return;

    final replay = await showRoundResult(
      context,
      title: 'Game Over',
      message:
          'Điểm: $_score\nĐộ khó: ${GameService.diffName(_difficulty)} (×$mult)\nĐiểm thưởng: +$total điểm${GameService.guestNote(widget.username)}',
      replayLabel: 'Chơi lại',
      closeLabel: 'Thoát',
    );
    if (!mounted) return;
    if (replay) {
      setState(_initGame);
    } else {
      Navigator.of(context).pop(_balance - widget.currentTokens);
    }
  }

  Widget _dirButton(IconData icon, String dir) => Tappable(
        onTap: () => _changeDirection(dir),
        pressedScale: 0.9,
        child: Container(
          width: 58,
          height: 50,
          decoration: BoxDecoration(
              color: Ios.card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: Ios.shadow),
          child: Icon(icon, color: Ios.label, size: 22),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return DifficultySelectorScreen(
        gameTitle: 'Rắn Săn Mồi',
        gameId: 'snakegame',
        gameDescription:
            'Vuốt màn hình để điều khiển rắn ăn mồi. Cẩn thận đừng đụng tường hoặc tự cắn đuôi mình!',
        onPlayPressed: _startGame,
      );
    }

    return GameScaffold(
      title: 'Rắn • ${GameService.diffName(_difficulty)}',
      onBack: () {
        _timer?.cancel();
        setState(() => _isStarted = false);
      },
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(_initGame),
        child: const Icon(CupertinoIcons.arrow_counterclockwise,
            color: Ios.accent, size: 24),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                    child: StatBox(
                        label: 'Điểm', value: '$_score', color: Ios.green)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Độ dài',
                        value: '${_snake.length}',
                        color: Ios.teal)),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _onPan,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(builder: (context, c) {
                  final cell = min(c.maxWidth / _cols, c.maxHeight / _rows);
                  return Center(
                    child: Container(
                      width: cell * _cols,
                      height: cell * _rows,
                      decoration: BoxDecoration(
                        color: Ios.card,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: Ios.shadow,
                        border: Border.all(color: Ios.accent.op(0.45), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _SnakePainter(
                                _snake, _food, _cols, _rows, _direction),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                _dirButton(CupertinoIcons.chevron_up, 'UP'),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _dirButton(CupertinoIcons.chevron_left, 'LEFT'),
                    const SizedBox(width: 46),
                    _dirButton(CupertinoIcons.chevron_right, 'RIGHT'),
                  ],
                ),
                const SizedBox(height: 6),
                _dirButton(CupertinoIcons.chevron_down, 'DOWN'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vẽ bàn chơi bằng CustomPaint: mượt hơn và không bị tràn như GridView.
class _SnakePainter extends CustomPainter {
  final List<Point<int>> snake;
  final Point<int> food;
  final int cols;
  final int rows;
  final String direction;

  _SnakePainter(this.snake, this.food, this.cols, this.rows, this.direction);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / cols;

    // Nền caro mờ
    final tile = Paint()..color = CupertinoColors.white.op(0.04);
    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if ((x + y) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), tile);
        }
      }
    }

    // Mồi
    final fc = Offset((food.x + 0.5) * cell, (food.y + 0.5) * cell);
    canvas.drawCircle(fc, cell * 0.36, Paint()..color = Ios.red);
    canvas.drawCircle(fc.translate(-cell * 0.1, -cell * 0.1), cell * 0.1,
        Paint()..color = CupertinoColors.white.op(0.5));

    // Thân rắn: từ đuôi lên đầu
    for (int i = snake.length - 1; i >= 0; i--) {
      final p = snake[i];
      final t = 1 - i / max(1, snake.length);
      final paint = Paint()
        ..color = i == 0 ? Ios.green : Ios.green.op(0.55 + 0.35 * t);
      final r = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x * cell + 1, p.y * cell + 1, cell - 2, cell - 2),
        Radius.circular(cell * 0.3),
      );
      canvas.drawRRect(r, paint);
    }

    // Mắt
    if (snake.isNotEmpty) {
      final h = snake.first;
      final c = Offset((h.x + 0.5) * cell, (h.y + 0.5) * cell);
      Offset a, b, look;
      switch (direction) {
        case 'UP':
          a = c.translate(-cell * 0.2, -cell * 0.12);
          b = c.translate(cell * 0.2, -cell * 0.12);
          look = Offset(0, -cell * 0.04);
          break;
        case 'DOWN':
          a = c.translate(-cell * 0.2, cell * 0.12);
          b = c.translate(cell * 0.2, cell * 0.12);
          look = Offset(0, cell * 0.04);
          break;
        case 'LEFT':
          a = c.translate(-cell * 0.12, -cell * 0.2);
          b = c.translate(-cell * 0.12, cell * 0.2);
          look = Offset(-cell * 0.04, 0);
          break;
        default:
          a = c.translate(cell * 0.12, -cell * 0.2);
          b = c.translate(cell * 0.12, cell * 0.2);
          look = Offset(cell * 0.04, 0);
      }
      final white = Paint()..color = CupertinoColors.white;
      final black = Paint()..color = CupertinoColors.black;
      canvas.drawCircle(a, cell * 0.14, white);
      canvas.drawCircle(b, cell * 0.14, white);
      canvas.drawCircle(a + look, cell * 0.07, black);
      canvas.drawCircle(b + look, cell * 0.07, black);
    }
  }

  @override
  bool shouldRepaint(covariant _SnakePainter old) => true;
}
