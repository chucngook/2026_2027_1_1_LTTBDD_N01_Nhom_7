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

class FlappyScreen extends StatefulWidget {
  final String username;
  final int currentTokens;

  const FlappyScreen(
      {super.key, required this.username, required this.currentTokens});

  @override
  State<FlappyScreen> createState() => _FlappyScreenState();
}

class _Pipe {
  double x;
  final double gapY; // tâm khe hở
  bool passed = false;
  _Pipe(this.x, this.gapY);
}

class _FlappyScreenState extends State<FlappyScreen> {
  static const double _ground = 56;
  static const double _pipeW = 66;
  static const double _birdR = 15;
  static const double _birdSize = 46;
  static const double _spacing = 230;

  final Random _rand = Random();
  bool _isStarted = false;
  String _difficulty = 'EASY';

  double _w = 360;
  double _h = 600;
  double _birdY = 270;
  double _vy = 0;
  double _speed = 2.6;
  double _gap = 175;

  final List<_Pipe> _pipes = [];
  int _score = 0;
  bool _waiting = true;
  bool _over = false;
  late int _balance;
  Timer? _timer;

  double get _birdX => _w * 0.28;

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
      if (diff == 'EASY') {
        _speed = 2.6;
        _gap = 175;
      } else if (diff == 'MEDIUM') {
        _speed = 3.2;
        _gap = 155;
      } else {
        _speed = 3.9;
        _gap = 138;
      }
      _isStarted = true;
      _init();
    });
  }

  void _init() {
    _pipes.clear();
    _score = 0;
    _vy = 0;
    _birdY = _h * 0.45;
    _waiting = true;
    _over = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (mounted) _tick();
    });
  }

  void _flap() {
    if (_over) return;
    Fx.select(); Fx.play(Sound.flap);
    if (_waiting) setState(() => _waiting = false);
    _vy = -_h * 0.0125;
  }

  void _tick() {
    if (_waiting || _over) return;

    setState(() {
      _vy += _h * 0.00085;
      _birdY += _vy;
      for (final p in _pipes) {
        p.x -= _speed;
      }
      _pipes.removeWhere((p) => p.x < -_pipeW - 10);

      if (_pipes.isEmpty || _pipes.last.x < _w - _spacing) {
        final minC = _gap / 2 + 60;
        final maxC = _h - _ground - _gap / 2 - 60;
        _pipes.add(_Pipe(_w + 10, minC + _rand.nextDouble() * (maxC - minC)));
      }
      for (final p in _pipes) {
        if (!p.passed && p.x + _pipeW < _birdX - _birdR) {
          p.passed = true;
          _score++;
          Fx.light(); Fx.play(Sound.coin);
        }
      }
    });

    var dead = _birdY - _birdR < 0 || _birdY + _birdR > _h - _ground;
    for (final p in _pipes) {
      if (_birdX + _birdR > p.x && _birdX - _birdR < p.x + _pipeW) {
        if (_birdY - _birdR < p.gapY - _gap / 2 ||
            _birdY + _birdR > p.gapY + _gap / 2) {
          dead = true;
        }
      }
    }
    if (dead) {
      _over = true;
      _timer?.cancel();
      Fx.heavy(); Fx.play(Sound.lose);
      _finish();
    }
  }

  Future<void> _finish() async {
    final mult = GameService.multiplier(_difficulty);
    final total = max(20, _score * 15) * mult;

    await GameService.reward(
      username: widget.username,
      balanceBefore: _balance,
      amount: total,
      gameId: 'flappybird',
      score: _score * mult,
    );
    _balance += total;
    if (!mounted) return;

    final replay = await showRoundResult(
      context,
      title: 'Game Over',
      message:
          'Vượt qua: $_score ống\nĐộ khó: ${GameService.diffName(_difficulty)} (×$mult)\nĐiểm thưởng: +$total điểm${GameService.guestNote(widget.username)}',
      replayLabel: 'Chơi lại',
      closeLabel: 'Thoát',
    );
    if (!mounted) return;
    if (replay) {
      setState(_init);
    } else {
      Navigator.of(context).pop(_balance - widget.currentTokens);
    }
  }

  Widget _pipeBody({required bool capAtBottom}) {
    final body = Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E9E3F), Color(0xFF7BE06C), Color(0xFF2E9E3F)],
        ),
        border: Border.all(color: const Color(0xFF1B6B2A), width: 2),
      ),
    );
    final cap = Container(
      height: 26,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E9E3F), Color(0xFF7BE06C), Color(0xFF2E9E3F)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1B6B2A), width: 2),
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: body),
        Positioned(
          left: -5,
          right: -5,
          bottom: capAtBottom ? 0 : null,
          top: capAtBottom ? null : 0,
          child: cap,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return DifficultySelectorScreen(
        gameTitle: 'Chim Vượt Chướng Ngại',
        gameId: 'flappybird',
        gameDescription:
            'Chạm màn hình để chú chim vỗ cánh, bay qua các khe hở giữa những chiếc ống. Càng xa, thưởng càng cao!',
        onPlayPressed: _startGame,
      );
    }

    return GameScaffold(
      title: 'Flappy • ${GameService.diffName(_difficulty)}',
      onBack: () {
        _timer?.cancel();
        setState(() => _isStarted = false);
      },
      child: LayoutBuilder(builder: (context, c) {
        _w = c.maxWidth;
        _h = c.maxHeight;
        if (_waiting) _birdY = _h * 0.45;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _flap(),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5AC8FA), Color(0xFFE6F7FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: 90,
                  left: 30,
                  child: Opacity(
                      opacity: 0.9,
                      child: Image.asset(AppImages.cloud, width: 84)),
                ),
                Positioned(
                  top: 190,
                  right: 24,
                  child: Opacity(
                      opacity: 0.8,
                      child: Image.asset(AppImages.cloud, width: 110)),
                ),
                for (final p in _pipes) ...[
                  Positioned(
                    left: p.x,
                    top: 0,
                    width: _pipeW,
                    height: max(0.0, p.gapY - _gap / 2),
                    child: _pipeBody(capAtBottom: true),
                  ),
                  Positioned(
                    left: p.x,
                    top: p.gapY + _gap / 2,
                    width: _pipeW,
                    height: max(0.0, _h - _ground - (p.gapY + _gap / 2)),
                    child: _pipeBody(capAtBottom: false),
                  ),
                ],
                // Mặt đất
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: _ground,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFD7B377),
                      border: Border(
                          top: BorderSide(color: Color(0xFF6CC24A), width: 10)),
                    ),
                  ),
                ),
                // Chim
                Positioned(
                  left: _birdX - _birdSize / 2,
                  top: _birdY - _birdSize / 2,
                  child: Transform.rotate(
                    angle: (_vy / (_h * 0.03)).clamp(-0.45, 1.1).toDouble(),
                    child: Image.asset(AppImages.bird,
                        width: _birdSize, height: _birdSize),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text('$_score',
                        style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(color: Color(0x66000000), blurRadius: 8)
                            ])),
                  ),
                ),
                if (_waiting)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: _h * 0.62,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                            color: const Color(0x99000000),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Text('Chạm để bắt đầu bay',
                            style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
