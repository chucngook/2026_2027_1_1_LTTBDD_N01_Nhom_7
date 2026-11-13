import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import '../../../services/fx.dart';
import '../../../constants/app_assets.dart';
import '../../../data/game_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/difficulty_selector_screen.dart';
import '../../../widgets/ios_widgets.dart';

class MemoryScreen extends StatefulWidget {
  final String username;
  final int currentTokens;

  const MemoryScreen(
      {super.key, required this.username, required this.currentTokens});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  static final List<String> _assetPool = AppImages.cardSymbols;

  bool _isStarted = false;
  String _difficulty = 'EASY';

  List<String> _cards = [];
  List<bool> _flipped = [];
  List<bool> _matched = [];

  int? _first;
  bool _checking = false;
  bool _gameOver = false;
  int _moves = 0;
  int _pairsFound = 0;
  int _totalPairs = 6;
  int _cols = 3;
  int _seconds = 0;
  int _gen = 0; // chống callback cũ sau khi chơi lại
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startGame(String diff) {
    setState(() {
      _difficulty = diff;
      if (diff == 'EASY') {
        _totalPairs = 6; // 12 thẻ: 3x4
        _cols = 3;
      } else if (diff == 'MEDIUM') {
        _totalPairs = 8; // 16 thẻ: 4x4
        _cols = 4;
      } else {
        _totalPairs = 10; // 20 thẻ: 4x5
        _cols = 4;
      }
      _isStarted = true;
      _initGame();
    });
  }

  void _initGame() {
    _gen++;
    final pool = [..._assetPool]..shuffle();
    final chosen = pool.take(_totalPairs).toList();
    _cards = [...chosen, ...chosen]..shuffle();
    final n = _totalPairs * 2;
    _flipped = List.filled(n, false);
    _matched = List.filled(n, false);
    _first = null;
    _checking = false;
    _gameOver = false;
    _moves = 0;
    _pairsFound = 0;
    _seconds = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_gameOver) setState(() => _seconds++);
    });
  }

  void _onCardTap(int i) {
    if (_checking || _flipped[i] || _matched[i] || _gameOver) return;
    Fx.select(); Fx.play(Sound.flip);

    if (_first == null) {
      setState(() {
        _flipped[i] = true;
        _first = i;
      });
      return;
    }

    final a = _first!;
    final gen = _gen;
    setState(() {
      _flipped[i] = true;
      _moves++;
      _checking = true;
    });

    if (_cards[a] == _cards[i]) {
      Fx.medium(); Fx.play(Sound.correct);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || gen != _gen) return;
        setState(() {
          _matched[a] = true;
          _matched[i] = true;
          _pairsFound++;
          _first = null;
          _checking = false;
        });
        if (_pairsFound == _totalPairs) _finishGame();
      });
    } else {
      Fx.play(Sound.wrong);
      Future.delayed(const Duration(milliseconds: 750), () {
        if (!mounted || gen != _gen) return;
        setState(() {
          _flipped[a] = false;
          _flipped[i] = false;
          _first = null;
          _checking = false;
        });
      });
    }
  }

  Future<void> _finishGame() async {
    Fx.play(Sound.win);
    _gameOver = true;
    _timer?.cancel();

    final mult = GameService.multiplier(_difficulty);
    final total = _totalPairs * 20 * mult;
    final score = max(10, _totalPairs * 100 - _moves * 5 - _seconds) * mult;

    await GameService.reward(
      username: widget.username,
      balanceBefore: widget.currentTokens,
      amount: total,
      gameId: 'memoryflip',
      score: score,
    );
    if (!mounted) return;

    await showRoundResult(
      context,
      title: 'Hoàn thành!',
      message:
          'Số lượt lật: $_moves\nThời gian: ${formatSeconds(_seconds)}\nĐộ khó: ${GameService.diffName(_difficulty)} (×$mult)\nĐiểm thưởng: +$total điểm${GameService.guestNote(widget.username)}',
    );
    if (!mounted) return;
    Navigator.of(context).pop(total);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return DifficultySelectorScreen(
        gameTitle: 'Lật Hình Ghi Nhớ',
        gameId: 'memoryflip',
        gameDescription:
            'Lật thẻ để tìm các cặp hình giống nhau. Độ khó càng cao, số thẻ càng nhiều và thưởng càng lớn!',
        onPlayPressed: _startGame,
      );
    }

    return GameScaffold(
      title: 'Lật hình • ${GameService.diffName(_difficulty)}',
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
                        label: 'Lượt lật', value: '$_moves', color: Ios.label)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Cặp',
                        value: '$_pairsFound/$_totalPairs',
                        color: Ios.amber)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatBox(
                        label: 'Thời gian',
                        value: formatSeconds(_seconds),
                        color: Ios.teal)),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                const gap = 10.0;
                final rows = (_totalPairs * 2 / _cols).ceil();
                final cell = min((c.maxWidth - (_cols - 1) * gap) / _cols,
                    (c.maxHeight - (rows - 1) * gap) / rows);
                return Center(
                  child: SizedBox(
                    width: cell * _cols + (_cols - 1) * gap,
                    height: cell * rows + (rows - 1) * gap,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _totalPairs * 2,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _cols,
                        mainAxisSpacing: gap,
                        crossAxisSpacing: gap,
                      ),
                      itemBuilder: (context, i) => _FlipCard(
                        faceUp: _flipped[i] || _matched[i],
                        matched: _matched[i],
                        asset: _cards[i],
                        onTap: () => _onCardTap(i),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            IosButton(
              label: 'Chơi lại từ đầu',
              icon: CupertinoIcons.arrow_counterclockwise,
              color: Ios.card2,
              textColor: Ios.accent,
              onPressed: () => setState(_initGame),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ lật 3D (xoay quanh trục Y).
class _FlipCard extends StatelessWidget {
  final bool faceUp;
  final bool matched;
  final String asset;
  final VoidCallback onTap;

  const _FlipCard({
    required this.faceUp,
    required this.matched,
    required this.asset,
    required this.onTap,
  });

  Widget _back() => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFBF5AF2), Color(0xFF5E5CE6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        child: Opacity(
          opacity: 0.9,
          child: Image.asset(AppImages.logo, fit: BoxFit.contain),
        ),
      );

  Widget _front() => Container(
        decoration: BoxDecoration(
          color: matched ? Ios.green.op(0.16) : Ios.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: matched ? Ios.green : Ios.separator,
              width: matched ? 2 : 0.5),
          boxShadow: matched ? null : Ios.shadow,
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Image.asset(asset, fit: BoxFit.contain),
      );

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      pressedScale: 0.95,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: faceUp ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
        builder: (context, v, _) {
          final showFront = v >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(v * pi),
            child: showFront
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _front(),
                  )
                : _back(),
          );
        },
      ),
    );
  }
}
