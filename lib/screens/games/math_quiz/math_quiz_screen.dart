import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart' hide Text;
import '../../../widgets/tr_text.dart';
import '../../../services/fx.dart';
import '../../../data/game_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/difficulty_selector_screen.dart';
import '../../../widgets/ios_widgets.dart';

class MathQuizScreen extends StatefulWidget {
  final String username;
  final int currentTokens;

  const MathQuizScreen(
      {super.key, required this.username, required this.currentTokens});

  @override
  State<MathQuizScreen> createState() => _MathQuizScreenState();
}

class _MQ {
  final String text;
  final int answer;
  final List<int> options;
  _MQ(this.text, this.answer, this.options);
}

class _MathQuizScreenState extends State<MathQuizScreen> {
  static const int _total = 10;

  final Random _rand = Random();
  bool _isStarted = false;
  String _difficulty = 'EASY';

  late _MQ _q;
  int _index = 0;
  int _score = 0;
  int _correct = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _limitMs = 12000;
  int _remainMs = 12000;
  bool _answered = false;
  int? _selected;
  int _gen = 0;
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

  _MQ _generate() {
    int a, b, ans;
    String text;
    final d = _difficulty;

    if (d == 'EASY') {
      a = _rand.nextInt(20) + 1;
      b = _rand.nextInt(20) + 1;
      if (_rand.nextBool()) {
        ans = a + b;
        text = '$a + $b';
      } else {
        if (a < b) {
          final t = a;
          a = b;
          b = t;
        }
        ans = a - b;
        text = '$a − $b';
      }
    } else if (d == 'MEDIUM') {
      final op = _rand.nextInt(3);
      if (op == 0) {
        a = _rand.nextInt(50) + 10;
        b = _rand.nextInt(50) + 10;
        ans = a + b;
        text = '$a + $b';
      } else if (op == 1) {
        a = _rand.nextInt(60) + 20;
        b = _rand.nextInt(a - 5) + 1;
        ans = a - b;
        text = '$a − $b';
      } else {
        a = _rand.nextInt(11) + 2;
        b = _rand.nextInt(11) + 2;
        ans = a * b;
        text = '$a × $b';
      }
    } else {
      final op = _rand.nextInt(4);
      if (op == 0) {
        a = _rand.nextInt(90) + 10;
        b = _rand.nextInt(90) + 10;
        ans = a + b;
        text = '$a + $b';
      } else if (op == 1) {
        a = _rand.nextInt(90) + 30;
        b = _rand.nextInt(a - 10) + 1;
        ans = a - b;
        text = '$a − $b';
      } else if (op == 2) {
        a = _rand.nextInt(13) + 3;
        b = _rand.nextInt(13) + 3;
        ans = a * b;
        text = '$a × $b';
      } else {
        b = _rand.nextInt(11) + 2;
        ans = _rand.nextInt(14) + 2;
        a = b * ans;
        text = '$a ÷ $b';
      }
    }

    final opts = <int>{ans};
    final spread = d == 'EASY' ? 6 : (d == 'MEDIUM' ? 10 : 15);
    while (opts.length < 4) {
      final delta = _rand.nextInt(spread) + 1;
      final cand = ans + (_rand.nextBool() ? delta : -delta);
      if (cand >= 0) opts.add(cand);
    }
    return _MQ(text, ans, opts.toList()..shuffle(_rand));
  }

  void _startGame(String diff) {
    setState(() {
      _difficulty = diff;
      _limitMs = diff == 'EASY' ? 12000 : (diff == 'MEDIUM' ? 9000 : 7000);
      _isStarted = true;
      _resetRound();
    });
    _nextQuestion(first: true);
  }

  void _resetRound() {
    _gen++;
    _index = 0;
    _score = 0;
    _correct = 0;
    _streak = 0;
    _bestStreak = 0;
    _answered = false;
    _selected = null;
  }

  void _nextQuestion({bool first = false}) {
    _timer?.cancel();
    setState(() {
      if (!first) _index++;
      _q = _generate();
      _answered = false;
      _selected = null;
      _remainMs = _limitMs;
    });
    final gen = _gen;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || gen != _gen || _answered) return;
      setState(() => _remainMs -= 100);
      if (_remainMs <= 0) _answer(-1);
    });
  }

  void _answer(int optionIndex) {
    if (_answered) return;
    _timer?.cancel();
    final gen = _gen;
    final ok = optionIndex >= 0 && _q.options[optionIndex] == _q.answer;

    setState(() {
      _answered = true;
      _selected = optionIndex;
      if (ok) {
        _correct++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        final speedBonus = (_remainMs / _limitMs * 10).floor();
        _score += 10 + speedBonus + (_streak % 3 == 0 ? 5 : 0);
      } else {
        _streak = 0;
      }
    });
    ok ? Fx.light() : Fx.heavy();
        Fx.play(ok ? Sound.correct : Sound.wrong);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || gen != _gen) return;
      if (_index >= _total - 1) {
        _finish();
      } else {
        _nextQuestion();
      }
    });
  }

  Future<void> _finish() async {
    Fx.play(Sound.win);
    final mult = GameService.multiplier(_difficulty);
    final total = max(10, _score ~/ 2) * mult;

    await GameService.reward(
      username: widget.username,
      balanceBefore: _balance,
      amount: total,
      gameId: 'mathquiz',
      score: _score * mult,
    );
    _balance += total;
    if (!mounted) return;

    final replay = await showRoundResult(
      context,
      title: 'Hoàn thành thử thách',
      message:
          'Đúng $_correct/$_total • Điểm: $_score\nChuỗi đúng dài nhất: $_bestStreak\nĐộ khó: ${GameService.diffName(_difficulty)} (×$mult)\nĐiểm thưởng: +$total điểm${GameService.guestNote(widget.username)}',
      replayLabel: 'Chơi lại',
      closeLabel: 'Thoát',
    );
    if (!mounted) return;
    if (replay) {
      setState(_resetRound);
      _nextQuestion(first: true);
    } else {
      Navigator.of(context).pop(_balance - widget.currentTokens);
    }
  }

  Widget _option(int i) {
    final value = _q.options[i];
    Color bg = Ios.card;
    Color border = Ios.separator;
    Color fg = Ios.label;
    if (_answered) {
      if (value == _q.answer) {
        bg = Ios.green.op(0.18);
        border = Ios.green;
      } else if (i == _selected) {
        bg = Ios.red.op(0.18);
        border = Ios.red;
      }
    }
    return Tappable(
      onTap: _answered ? null : () => _answer(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: 1.5),
          boxShadow: _answered ? null : Ios.shadow,
        ),
        child: Text('$value',
            style: TextStyle(
                color: fg, fontSize: 28, fontWeight: FontWeight.w800)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return DifficultySelectorScreen(
        gameTitle: 'Thử Thách Toán Học',
        gameId: 'mathquiz',
        gameDescription:
            'Giải 10 phép tính trong thời gian giới hạn. Trả lời càng nhanh và đúng liên tiếp, điểm thưởng càng cao!',
        onPlayPressed: _startGame,
      );
    }

    final frac = (_remainMs / _limitMs).clamp(0.0, 1.0).toDouble();
    final barColor = frac > 0.5 ? Ios.green : (frac > 0.25 ? Ios.orange : Ios.red);

    return GameScaffold(
      title: 'Toán học • ${GameService.diffName(_difficulty)}',
      onBack: () {
        _timer?.cancel();
        _gen++;
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
                        label: 'Câu',
                        value: '${_index + 1}/$_total',
                        color: Ios.label)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Điểm', value: '$_score', color: Ios.accent)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Chuỗi đúng',
                        value: '$_streak',
                        color: Ios.orange)),
              ],
            ),
            const SizedBox(height: 16),
            // Thanh thời gian
            Container(
              height: 8,
              decoration: BoxDecoration(
                  color: Ios.card2, borderRadius: BorderRadius.circular(4)),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: frac,
                child: Container(
                  decoration: BoxDecoration(
                      color: barColor, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFCC2B5E), Color(0xFF753A88)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: Ios.shadow,
              ),
              child: Column(
                children: [
                  Text('${(_remainMs / 1000).ceil().clamp(0, 99)} giây',
                      style: TextStyle(
                          color: CupertinoColors.white.op(0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('${_q.text} = ?',
                      style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
                children: List.generate(4, _option),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
