import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart' hide Text;
import '../../../widgets/tr_text.dart';
import '../../../services/fx.dart';
import '../../../constants/app_assets.dart';
import '../../../data/game_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/difficulty_selector_screen.dart';
import '../../../widgets/ios_widgets.dart';

class CatchItemScreen extends StatefulWidget {
  final String username;
  final int currentTokens;

  const CatchItemScreen(
      {super.key, required this.username, required this.currentTokens});

  @override
  State<CatchItemScreen> createState() => _CatchItemScreenState();
}

enum ItemType { apple, star, bomb }

class _FallingItem {
  double x;
  double y;
  final ItemType type;
  _FallingItem({required this.x, required this.y, required this.type});
}

class _CatchItemScreenState extends State<CatchItemScreen> {
  static const double _basketBottom = 8;
  static const double _basketHeight = 82;

  final Random _rand = Random();
  bool _isStarted = false;
  String _difficulty = 'EASY';

  double _basketX = 0.5;
  final List<_FallingItem> _items = [];
  int _score = 0;
  int _lives = 3;
  int _timeLeft = 45;
  bool _gameOver = false;
  bool _flash = false;

  double _fallSpeed = 0.013;
  int _spawnRate = 32;
  int _tick = 0;
  double _areaH = 600; // chiều cao vùng chơi (cập nhật từ LayoutBuilder)

  late int _balance;
  Timer? _loopTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _balance = widget.currentTokens;
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _stopTimers() {
    _loopTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _startGame(String diff) {
    setState(() {
      _difficulty = diff;
      if (diff == 'EASY') {
        _fallSpeed = 0.013;
        _lives = 5;
        _timeLeft = 40;
        _spawnRate = 32;
      } else if (diff == 'MEDIUM') {
        _fallSpeed = 0.018;
        _lives = 3;
        _timeLeft = 45;
        _spawnRate = 26;
      } else {
        _fallSpeed = 0.025;
        _lives = 2;
        _timeLeft = 50;
        _spawnRate = 20;
      }
      _isStarted = true;
      _initGame();
    });
  }

  void _initGame() {
    _items.clear();
    _score = 0;
    _gameOver = false;
    _basketX = 0.5;
    _tick = 0;
    _flash = false;
    if (_difficulty == 'EASY') {
      _lives = 5;
      _timeLeft = 40;
    } else if (_difficulty == 'MEDIUM') {
      _lives = 3;
      _timeLeft = 45;
    } else {
      _lives = 2;
      _timeLeft = 50;
    }

    _stopTimers();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_gameOver || !mounted) return;
      setState(() => _timeLeft--);
      if (_timeLeft <= 0) {
        _gameOver = true;
        _finish();
      }
    });
    _loopTimer = Timer.periodic(const Duration(milliseconds: 25), (_) {
      if (!_gameOver && mounted) _update();
    });
  }

  void _spawn() {
    final r = _rand.nextDouble();
    ItemType type;
    if (r < 0.15) {
      type = ItemType.star;
    } else if (r < (_difficulty == 'HARD' ? 0.45 : 0.28)) {
      type = ItemType.bomb;
    } else {
      type = ItemType.apple;
    }
    _items.add(_FallingItem(x: _rand.nextDouble() * 0.8 + 0.1, y: 0, type: type));
  }

  void _update() {
    bool dead = false;
    bool bombHit = false;

    setState(() {
      _tick++;
      if (_tick % _spawnRate == 0) _spawn();

      final basketTop = _areaH - _basketBottom - _basketHeight;
      for (int i = _items.length - 1; i >= 0; i--) {
        final it = _items[i];
        it.y += _fallSpeed;
        final cy = it.y * _areaH;

        if (cy >= basketTop && cy <= basketTop + 40 &&
            (it.x - _basketX).abs() < 0.15) {
          if (it.type == ItemType.bomb) {
            bombHit = true;
            _lives--;
            if (_lives <= 0) dead = true;
          } else if (it.type == ItemType.star) {
            _score += 30;
            Fx.medium(); Fx.play(Sound.coin);
          } else {
            _score += 10;
            Fx.light(); Fx.play(Sound.coin);
          }
          _items.removeAt(i);
          continue;
        }
        if (it.y > 1.05) _items.removeAt(i);
      }
    });

    if (bombHit) {
      Fx.heavy(); Fx.play(Sound.bomb);
      setState(() => _flash = true);
      Timer(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _flash = false);
      });
    }
    if (dead && !_gameOver) {
      _gameOver = true;
      _finish();
    }
  }

  void _onPan(DragUpdateDetails d, double width) {
    if (_gameOver) return;
    setState(() {
      _basketX = (_basketX + d.delta.dx / width).clamp(0.08, 0.92).toDouble();
    });
  }

  Future<void> _finish() async {
    Fx.play(Sound.win);
    _stopTimers();
    final mult = GameService.multiplier(_difficulty);
    final base = max(20, (_score ~/ 15) * 10);
    final total = base * mult;

    await GameService.reward(
      username: widget.username,
      balanceBefore: _balance,
      amount: total,
      gameId: 'catchitem',
      score: _score * mult,
    );
    _balance += total;
    if (!mounted) return;

    final replay = await showRoundResult(
      context,
      title: 'Tổng kết vườn táo',
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

  Widget _hud(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: const Color(0x73000000),
            borderRadius: BorderRadius.circular(14)),
        child: child,
      );

  TextStyle get _hudText => const TextStyle(
      color: CupertinoColors.white, fontWeight: FontWeight.w700, fontSize: 14);

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return DifficultySelectorScreen(
        gameTitle: 'Hứng Táo Vui Nhộn',
        gameId: 'catchitem',
        gameDescription:
            'Kéo giỏ để hứng táo và ngôi sao vàng, tránh những quả bom hẹn giờ trong thời gian cho phép!',
        onPlayPressed: _startGame,
      );
    }

    return GameScaffold(
      title: 'Hứng táo • ${GameService.diffName(_difficulty)}',
      onBack: () {
        _stopTimers();
        setState(() => _isStarted = false);
      },
      child: LayoutBuilder(builder: (context, c) {
        _areaH = c.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) => _onPan(d, c.maxWidth),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _flash
                    ? [const Color(0xFF7F1D1D), const Color(0xFFDC2626)]
                    : [const Color(0xFF134E5E), const Color(0xFF71B280)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 70,
                  left: 24,
                  child: Opacity(
                      opacity: 0.55,
                      child: Image.asset(AppImages.cloud, width: 70)),
                ),
                Positioned(
                  top: 130,
                  right: 30,
                  child: Opacity(
                      opacity: 0.4,
                      child: Image.asset(AppImages.cloud, width: 96)),
                ),
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _hud(Row(mainAxisSize: MainAxisSize.min, children: [
                        Image.asset(AppImages.apple, width: 18, height: 18),
                        const SizedBox(width: 6),
                        Text('$_score', style: _hudText),
                      ])),
                      _hud(Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(CupertinoIcons.timer,
                            color: CupertinoColors.white, size: 16),
                        const SizedBox(width: 5),
                        Text(formatSeconds(max(0, _timeLeft)),
                            style: _hudText.copyWith(color: Ios.yellow)),
                      ])),
                      _hud(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                            max(0, _lives),
                            (_) => Padding(
                                  padding: const EdgeInsets.only(right: 2),
                                  child: Image.asset(AppImages.heart,
                                      width: 16, height: 16),
                                )),
                      )),
                    ],
                  ),
                ),
                ..._items.map((it) {
                  final path = it.type == ItemType.star
                      ? AppImages.star
                      : (it.type == ItemType.bomb
                          ? AppImages.bomb
                          : AppImages.apple);
                  final w = it.type == ItemType.star ? 44.0 : 40.0;
                  return Positioned(
                    left: it.x * c.maxWidth - w / 2,
                    top: it.y * c.maxHeight - w / 2,
                    child: Image.asset(path, width: w, height: w),
                  );
                }),
                Positioned(
                  left: _basketX * c.maxWidth - 48,
                  bottom: _basketBottom,
                  child: Image.asset(AppImages.basket, width: 96, height: 96),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
