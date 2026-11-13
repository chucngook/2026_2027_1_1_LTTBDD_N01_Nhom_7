import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart' hide Text;
import '../../../widgets/tr_text.dart';
import '../../../services/fx.dart';
import '../../../data/game_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/difficulty_selector_screen.dart';
import '../../../widgets/ios_widgets.dart';

class BingoScreen extends StatefulWidget {
  final String username;
  final int currentTokens;

  const BingoScreen(
      {super.key, required this.username, required this.currentTokens});

  @override
  State<BingoScreen> createState() => _BingoScreenState();
}

class _BingoScreenState extends State<BingoScreen> {
  final Random _rand = Random();
  bool _isStarted = false;
  String _difficulty = 'EASY';

  List<int> _numbers = [];
  List<bool> _selected = [];
  int _target = 0;
  int _mistakes = 0;
  int _seconds = 0;
  int? _wrongIndex;
  bool _gameOver = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initBoard() {
    final range =
        _difficulty == 'HARD' ? 80 : (_difficulty == 'MEDIUM' ? 60 : 40);
    final nums = <int>{};
    while (nums.length < 16) {
      nums.add(_rand.nextInt(range) + 1);
    }
    _numbers = nums.toList();
    _selected = List.filled(16, false);
    _mistakes = 0;
    _seconds = 0;
    _wrongIndex = null;
    _gameOver = false;
    _pickTarget();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_gameOver) setState(() => _seconds++);
    });
  }

  void _pickTarget() {
    final remaining = [
      for (var i = 0; i < 16; i++)
        if (!_selected[i]) _numbers[i]
    ];
    if (remaining.isNotEmpty) {
      _target = remaining[_rand.nextInt(remaining.length)];
    }
  }

  void _onTap(int i) {
    if (_gameOver || _selected[i]) return;

    if (_numbers[i] == _target) {
      Fx.light(); Fx.play(Sound.correct);
      setState(() => _selected[i] = true);
      if (_selected.every((e) => e)) {
        _gameOver = true;
        _finish();
      } else {
        setState(_pickTarget);
      }
    } else {
      Fx.heavy(); Fx.play(Sound.wrong);
      setState(() {
        _mistakes++;
        _wrongIndex = i;
      });
      Timer(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _wrongIndex = null);
      });
    }
  }

  Future<void> _finish() async {
    Fx.play(Sound.win);
    _timer?.cancel();
    final mult = GameService.multiplier(_difficulty);
    final base = max(100, 300 - _mistakes * 20);
    final total = base * mult;
    final score = max(10, 1000 - _seconds * 5 - _mistakes * 30) * mult;

    await GameService.reward(
      username: widget.username,
      balanceBefore: widget.currentTokens,
      amount: total,
      gameId: 'bingo',
      score: score,
    );
    if (!mounted) return;

    await showRoundResult(
      context,
      title: 'Chiến thắng Bingo!',
      message:
          'Thời gian: ${formatSeconds(_seconds)} • Nhầm: $_mistakes lần\nĐộ khó: ${GameService.diffName(_difficulty)} (×$mult)\nĐiểm thưởng: +$total điểm${GameService.guestNote(widget.username)}',
    );
    if (!mounted) return;
    Navigator.of(context).pop(total);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return DifficultySelectorScreen(
        gameTitle: 'Bingo Sôi Động',
        gameId: 'bingo',
        gameDescription:
            'Tìm và chạm đúng con số mục tiêu trên bảng thật nhanh. Càng ít nhầm, thưởng càng cao!',
        onPlayPressed: (diff) {
          setState(() {
            _difficulty = diff;
            _isStarted = true;
            _initBoard();
          });
        },
      );
    }

    final done = _selected.where((e) => e).length;

    return GameScaffold(
      title: 'Bingo • ${GameService.diffName(_difficulty)}',
      onBack: () {
        _timer?.cancel();
        setState(() => _isStarted = false);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: StatBox(
                        label: 'Tiến độ', value: '$done/16', color: Ios.green)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Nhầm', value: '$_mistakes', color: Ios.red)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Thời gian',
                        value: formatSeconds(_seconds),
                        color: Ios.teal)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('TÌM SỐ',
                      style: TextStyle(
                          color: CupertinoColors.white.op(0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1)),
                  const SizedBox(height: 2),
                  Text('$_target',
                      style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.count(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    children: List.generate(16, (i) {
                      final sel = _selected[i];
                      final wrong = _wrongIndex == i;
                      return Tappable(
                        onTap: () => _onTap(i),
                        pressedScale: 0.92,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel
                                ? Ios.green.op(0.25)
                                : (wrong ? Ios.red.op(0.2) : Ios.card),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: sel
                                  ? Ios.green
                                  : (wrong ? Ios.red : Ios.separator),
                              width: sel || wrong ? 2 : 0.5,
                            ),
                            boxShadow: sel || wrong ? null : Ios.shadow,
                          ),
                          child: Text('${_numbers[i]}',
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: sel ? Ios.green : Ios.label)),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
