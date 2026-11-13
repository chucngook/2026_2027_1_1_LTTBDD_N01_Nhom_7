import 'dart:math';
import 'package:flutter/cupertino.dart' hide Text;
import '../../../widgets/tr_text.dart';
import '../../../services/fx.dart';
import '../../../data/game_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/difficulty_selector_screen.dart';
import '../../../widgets/ios_widgets.dart';

class Game2048Screen extends StatefulWidget {
  final String username;
  final int currentTokens;

  const Game2048Screen(
      {super.key, required this.username, required this.currentTokens});

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  final Random _rand = Random();
  bool _isStarted = false;
  String _difficulty = 'EASY';

  List<List<int>> _b = _empty();
  int _score = 0;
  int _gain = 0;
  int _target = 512;
  bool _over = false;
  late int _balance;

  static List<List<int>> _empty() => List.generate(4, (_) => List.filled(4, 0));

  @override
  void initState() {
    super.initState();
    _balance = widget.currentTokens;
  }

  void _startGame(String diff) {
    setState(() {
      _difficulty = diff;
      _target = diff == 'EASY' ? 512 : (diff == 'MEDIUM' ? 1024 : 2048);
      _isStarted = true;
      _init();
    });
  }

  void _init() {
    _b = _empty();
    _score = 0;
    _over = false;
    _spawn();
    _spawn();
  }

  void _spawn() {
    final empty = <int>[
      for (var r = 0; r < 4; r++)
        for (var c = 0; c < 4; c++)
          if (_b[r][c] == 0) r * 4 + c
    ];
    if (empty.isEmpty) return;
    final i = empty[_rand.nextInt(empty.length)];
    _b[i ~/ 4][i % 4] = _rand.nextDouble() < 0.1 ? 4 : 2;
  }

  List<int> _slide(List<int> line) {
    final nz = line.where((v) => v != 0).toList();
    final out = <int>[];
    var i = 0;
    while (i < nz.length) {
      if (i + 1 < nz.length && nz[i] == nz[i + 1]) {
        out.add(nz[i] * 2);
        _gain += nz[i] * 2;
        i += 2;
      } else {
        out.add(nz[i]);
        i++;
      }
    }
    while (out.length < 4) {
      out.add(0);
    }
    return out;
  }

  void _move(String dir) {
    if (_over) return;
    _gain = 0;
    final nb = _empty();
    for (var k = 0; k < 4; k++) {
      if (dir == 'LEFT') {
        nb[k] = _slide(_b[k]);
      } else if (dir == 'RIGHT') {
        nb[k] = _slide(_b[k].reversed.toList()).reversed.toList();
      } else if (dir == 'UP') {
        final res = _slide([for (var r = 0; r < 4; r++) _b[r][k]]);
        for (var r = 0; r < 4; r++) {
          nb[r][k] = res[r];
        }
      } else {
        final res = _slide([for (var r = 3; r >= 0; r--) _b[r][k]]);
        for (var r = 0; r < 4; r++) {
          nb[3 - r][k] = res[r];
        }
      }
    }

    var moved = false;
    for (var r = 0; r < 4 && !moved; r++) {
      for (var c = 0; c < 4; c++) {
        if (nb[r][c] != _b[r][c]) {
          moved = true;
          break;
        }
      }
    }
    if (!moved) return;

    Fx.select(); Fx.play(_gain > 0 ? Sound.coin : Sound.tap);
    setState(() {
      _b = nb;
      _score += _gain;
      _spawn();
    });

    final won = _b.any((row) => row.any((v) => v >= _target));
    if (won) {
      _over = true;
      _finish(won: true);
    } else if (!_canMove()) {
      _over = true;
      _finish(won: false);
    }
  }

  bool _canMove() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_b[r][c] == 0) return true;
        if (c < 3 && _b[r][c] == _b[r][c + 1]) return true;
        if (r < 3 && _b[r][c] == _b[r + 1][c]) return true;
      }
    }
    return false;
  }

  int get _maxTile => _b.expand((r) => r).reduce(max);

  Future<void> _finish({required bool won}) async {
    Fx.medium(); Fx.play(won ? Sound.win : Sound.lose);
    final mult = GameService.multiplier(_difficulty);
    final base = _score ~/ 8 + (won ? 200 : 0);
    final total = base * mult;

    await GameService.reward(
      username: widget.username,
      balanceBefore: _balance,
      amount: total,
      gameId: '2048game',
      score: _score * mult,
    );
    _balance += total;
    if (!mounted) return;

    final replay = await showRoundResult(
      context,
      title: won ? 'Bạn đã chiến thắng!' : 'Hết nước đi',
      message:
          'Điểm: $_score • Ô lớn nhất: $_maxTile\nĐộ khó: ${GameService.diffName(_difficulty)} (×$mult)\nĐiểm thưởng: +$total điểm${GameService.guestNote(widget.username)}',
      replayLabel: 'Ván mới',
      closeLabel: 'Thoát',
    );
    if (!mounted) return;
    if (replay) {
      setState(_init);
    } else {
      Navigator.of(context).pop(_balance - widget.currentTokens);
    }
  }

  Color _tileColor(int v) {
    switch (v) {
      case 0:
        return Ios.card3.op(0.45);
      case 2:
        return const Color(0xFFEDE7FF);
      case 4:
        return const Color(0xFFD9CCFF);
      case 8:
        return const Color(0xFFFFB74D);
      case 16:
        return const Color(0xFFFF9800);
      case 32:
        return const Color(0xFFFF7043);
      case 64:
        return const Color(0xFFF4511E);
      case 128:
        return const Color(0xFFFDD835);
      case 256:
        return const Color(0xFFFBC02D);
      case 512:
        return const Color(0xFF9CCC65);
      case 1024:
        return const Color(0xFF43A047);
      default:
        return Ios.accent;
    }
  }

  Widget _tile(int v) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _tileColor(v),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: v == 0
          ? null
          : Padding(
              padding: const EdgeInsets.all(6),
              child: FittedBox(
                child: Text('$v',
                    style: TextStyle(
                        color: v <= 4 ? const Color(0xFF5B3FD6) : CupertinoColors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800)),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return DifficultySelectorScreen(
        gameTitle: '2048 Classic',
        gameId: '2048game',
        gameDescription:
            'Vuốt để gộp các ô giống nhau. Dễ cần đạt 512, Vừa 1024, Khó 2048 để chiến thắng!',
        onPlayPressed: _startGame,
      );
    }

    return GameScaffold(
      title: '2048 • ${GameService.diffName(_difficulty)}',
      onBack: () => setState(() => _isStarted = false),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: StatBox(
                        label: 'Điểm', value: '$_score', color: Ios.accent)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Ô lớn nhất',
                        value: '$_maxTile',
                        color: Ios.orange)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Mục tiêu',
                        value: '$_target',
                        color: Ios.green)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanEnd: (d) {
                  final v = d.velocity.pixelsPerSecond;
                  if (v.distance < 250) return;
                  if (v.dx.abs() > v.dy.abs()) {
                    _move(v.dx > 0 ? 'RIGHT' : 'LEFT');
                  } else {
                    _move(v.dy > 0 ? 'DOWN' : 'UP');
                  }
                },
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Ios.card2,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: Ios.shadow,
                      ),
                      child: Column(
                        children: List.generate(
                          4,
                          (r) => Expanded(
                            child: Row(
                              children: List.generate(
                                  4, (c) => Expanded(child: _tile(_b[r][c]))),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Vuốt lên / xuống / trái / phải để di chuyển các ô',
                  style: TextStyle(color: Ios.label2, fontSize: 13)),
            ),
            Row(
              children: [
                Expanded(
                  child: IosButton(
                    label: 'Ván mới',
                    icon: CupertinoIcons.arrow_counterclockwise,
                    color: Ios.card,
                    textColor: Ios.accent,
                    onPressed: () => setState(_init),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: IosButton(
                    label: 'Kết thúc',
                    color: Ios.accent,
                    onPressed: _over
                        ? null
                        : () {
                            _over = true;
                            _finish(won: false);
                          },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
