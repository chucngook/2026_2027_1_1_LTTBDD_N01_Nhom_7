import 'dart:math';
import 'package:flutter/cupertino.dart' hide Text;
import '../../../widgets/tr_text.dart';
import '../../../data/game_service.dart';
import '../../../services/fx.dart';
import '../../../services/online_service.dart';
import '../../../services/player_service.dart';
import '../../../services/stats_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/ios_widgets.dart';
import '../../../widgets/online_game_mixin.dart';
import '../../../widgets/recess_ui.dart';

/// Cờ ca-rô (Gomoku) 13x13: xếp 5 quân liên tiếp để thắng. Người 1 (đen) đi trước.
class CaroScreen extends StatefulWidget {
  final MatchConfig config;
  const CaroScreen({super.key, required this.config});

  @override
  State<CaroScreen> createState() => _CaroScreenState();
}

class _CaroScreenState extends State<CaroScreen> with OnlineGameMixin<CaroScreen> {
  static const int _n = 13;
  static const List<List<int>> _dirs = [
    [0, 1],
    [1, 0],
    [1, 1],
    [1, -1],
  ];

  final Random _rand = Random();
  List<List<int>> _b = _emptyBoard(); // 0 trống, 1 = Người 1 (đen), 2 = Người 2 (trắng)
  List<int>? _last;
  List<List<int>> _winCells = [];
  int _turn = 0; // 0 hoặc 1
  bool _over = false;
  int _moves = 0;
  int _roundId = 0;
  bool _waitRematch = false;
  final List<int> _wins = [0, 0];
  int _draws = 0;

  @override
  MatchConfig get config => widget.config;

  static List<List<int>> _emptyBoard() =>
      List.generate(_n, (_) => List.filled(_n, 0));

  @override
  void initState() {
    super.initState();
    netInit();
  }

  @override
  void dispose() {
    _roundId++;
    netDispose();
    super.dispose();
  }

  void _newRound() {
    setState(() {
      _roundId++;
      _b = _emptyBoard();
      _last = null;
      _winCells = [];
      _turn = 0;
      _over = false;
      _moves = 0;
      _waitRematch = false;
    });
  }

  @override
  void onRematch() => _newRound();

  @override
  void onNetMove(Map<String, dynamic> d) {
    if (_over) return;
    final r = (d['r'] as num).toInt(), c = (d['c'] as num).toInt();
    if (!_in(r, c) || _b[r][c] != 0) return;
    _place(r, c, remote: true);
  }

  // ───────── Tên & trạng thái ─────────
  String _name(int p) {
    if (config.isComputer) return p == 0 ? 'Bạn' : 'Máy';
    if (config.isLocal) return 'Người ${p + 1}';
    return p == config.myRole
        ? PlayerService.instance.name
        : (config.session?.oppName ?? 'Đối thủ');
  }

  String get _status {
    if (_waitRematch) return 'Chờ đối thủ đồng ý chơi lại...';
    if (_over) return 'Ván đã kết thúc';
    final who = _name(_turn);
    final stone = _turn == 0 ? 'đen' : 'trắng';
    if (config.isComputer && _turn == 1) return 'Máy đang suy nghĩ...';
    if (config.isOnline && _turn != config.myRole) return 'Chờ $who đi...';
    return 'Đến lượt $who ($stone)';
  }

  bool get _canTap {
    if (_over) return false;
    if (config.isComputer) return _turn == 0;
    if (config.isOnline) return _turn == config.myRole;
    return true;
  }

  bool _in(int r, int c) => r >= 0 && r < _n && c >= 0 && c < _n;

  // ───────── Luật thắng ─────────
  List<List<int>>? _winLineFrom(int r, int c, int p) {
    for (final d in _dirs) {
      final cells = <List<int>>[
        [r, c]
      ];
      for (final sign in [1, -1]) {
        var rr = r + d[0] * sign, cc = c + d[1] * sign;
        while (_in(rr, cc) && _b[rr][cc] == p) {
          cells.add([rr, cc]);
          rr += d[0] * sign;
          cc += d[1] * sign;
        }
      }
      if (cells.length >= 5) return cells;
    }
    return null;
  }

  // ───────── AI (chấm điểm thế cờ) ─────────
  int _patternScore(int cnt, int open) {
    if (cnt >= 5) return 100000;
    if (open == 0) return 0;
    switch (cnt) {
      case 4:
        return open == 2 ? 10000 : 1000;
      case 3:
        return open == 2 ? 1000 : 100;
      case 2:
        return open == 2 ? 100 : 10;
      default:
        return open == 2 ? 10 : 1;
    }
  }

  int _evalCell(int r, int c, int p) {
    var total = 0;
    for (final d in _dirs) {
      var cnt = 1, open = 0;
      for (final sign in [1, -1]) {
        var rr = r + d[0] * sign, cc = c + d[1] * sign;
        while (_in(rr, cc) && _b[rr][cc] == p) {
          cnt++;
          rr += d[0] * sign;
          cc += d[1] * sign;
        }
        if (_in(rr, cc) && _b[rr][cc] == 0) open++;
      }
      total += _patternScore(cnt, open);
    }
    return total;
  }

  bool _nearStone(int r, int c, int dist) {
    for (var dr = -dist; dr <= dist; dr++) {
      for (var dc = -dist; dc <= dist; dc++) {
        final rr = r + dr, cc = c + dc;
        if (_in(rr, cc) && _b[rr][cc] != 0) return true;
      }
    }
    return false;
  }

  List<int> _pickAiMove() {
    final diff = config.difficulty;
    final cands = <List<int>>[
      for (var r = 0; r < _n; r++)
        for (var c = 0; c < _n; c++)
          if (_b[r][c] == 0 && _nearStone(r, c, 2)) [r, c]
    ];
    if (cands.isEmpty) return [_n ~/ 2, _n ~/ 2];

    if (diff == 'EASY' && _rand.nextDouble() < 0.2) {
      return cands[_rand.nextInt(cands.length)];
    }

    final defW = diff == 'EASY' ? 0.6 : (diff == 'MEDIUM' ? 0.95 : 1.15);
    final scored = <MapEntry<List<int>, double>>[];
    for (final m in cands) {
      final atk = _evalCell(m[0], m[1], 2).toDouble();
      final def = _evalCell(m[0], m[1], 1).toDouble();
      final centerBias = (6 - ((m[0] - 6).abs() + (m[1] - 6).abs()) / 2) * 0.5;
      var s = atk + def * defW + centerBias;
      if (diff == 'EASY') s *= 0.8 + _rand.nextDouble() * 0.4;
      scored.add(MapEntry(m, s));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    final pool = diff == 'EASY' ? min(3, scored.length) : 1;
    return scored[_rand.nextInt(pool)].key;
  }

  // ───────── Lượt đi ─────────
  void _onTapBoard(Offset pos, double cell) {
    if (!_canTap) return;
    final c = (pos.dx / cell - 0.5).round();
    final r = (pos.dy / cell - 0.5).round();
    if (!_in(r, c) || _b[r][c] != 0) return;
    _place(r, c);
  }

  void _place(int r, int c, {bool remote = false}) {
    Fx.light();
    Fx.play(Sound.tap);
    final p = _turn;
    setState(() {
      _b[r][c] = p + 1;
      _last = [r, c];
      _moves++;
    });
    if (!remote && config.isOnline) sendMove({'r': r, 'c': c});

    final line = _winLineFrom(r, c, p + 1);
    if (line != null) {
      setState(() => _winCells = line);
      _end(p);
      return;
    }
    if (_moves >= _n * _n) {
      _end(-1);
      return;
    }
    setState(() => _turn = 1 - p);

    if (config.isComputer && _turn == 1) {
      final id = _roundId;
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted || id != _roundId || _over) return;
        final m = _pickAiMove();
        _place(m[0], m[1]);
      });
    }
  }

  Future<void> _end(int winner) async {
    _over = true;
    final me = config.isOnline ? config.myRole : 0;
    if (winner == -1) {
      _draws++;
    } else {
      _wins[winner]++;
    }

    if (!config.isLocal) {
      final res = winner == -1 ? 'draw' : (winner == me ? 'win' : 'loss');
      StatsService.instance.recordMatch('caro', res);
    }
    final iWon = config.isLocal ? winner != -1 : winner == me;
    Fx.medium();
    Fx.play(winner == -1 ? Sound.tap : (iWon ? Sound.win : Sound.lose));
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final title = winner == -1
        ? 'Hòa cờ'
        : (config.isLocal
            ? '${_name(winner)} thắng!'
            : (winner == me ? 'Bạn thắng!' : '${_name(winner)} thắng'));
    final replay = await showRoundResult(
      context,
      title: title,
      message:
          '${_name(0)} ${_wins[0]} - ${_wins[1]} ${_name(1)}${config.isComputer ? '\nĐộ khó: ${GameService.diffName(config.difficulty)}' : ''}',
      replayLabel: 'Chơi lại',
      closeLabel: 'Thoát',
    );
    if (!mounted) return;
    if (!replay) {
      Navigator.of(context).pop();
    } else if (config.isOnline) {
      setState(() => _waitRematch = true);
      requestRematch();
    } else {
      _newRound();
    }
  }

  Widget _stone(int p) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: p == 0
                ? const [Color(0xFF6E6E73), Color(0xFF0E0E10)]
                : const [Color(0xFFFFFFFF), Color(0xFFCDCDD2)],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Cờ ca-rô',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: PlayerCard(
                      name: _name(0),
                      sub: 'Quân đen • thắng ${_wins[0]}',
                      leading: _stone(0),
                      active: !_over && _turn == 0),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PlayerCard(
                      name: _name(1),
                      sub: 'Quân trắng • thắng ${_wins[1]}',
                      leading: _stone(1),
                      active: !_over && _turn == 1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(_status,
                style: const TextStyle(
                    color: Ios.label, fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final side = min(c.maxWidth, c.maxHeight);
                final cell = side / _n;
                return Center(
                  child: Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8C98F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF8A6A3A), width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (d) => _onTapBoard(d.localPosition, cell),
                        child: CustomPaint(
                          painter: _BoardPainter(_b, _last, _winCells, _n),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            if (!config.isOnline)
              IosButton(
                label: 'Ván mới',
                icon: CupertinoIcons.arrow_counterclockwise,
                color: Ios.card,
                textColor: Ios.accent,
                onPressed: _newRound,
              ),
          ],
        ),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  final List<List<int>> b;
  final List<int>? last;
  final List<List<int>> win;
  final int n;

  _BoardPainter(this.b, this.last, this.win, this.n);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    Offset pt(int r, int c) => Offset((c + 0.5) * cell, (r + 0.5) * cell);

    final line = Paint()
      ..color = const Color(0xFF7A5A2B)
      ..strokeWidth = 1.2;
    for (var i = 0; i < n; i++) {
      canvas.drawLine(pt(0, i), pt(n - 1, i), line);
      canvas.drawLine(pt(i, 0), pt(i, n - 1), line);
    }
    for (final r in [3, 6, 9]) {
      for (final c in [3, 6, 9]) {
        canvas.drawCircle(pt(r, c), 3.2, Paint()..color = const Color(0xFF7A5A2B));
      }
    }

    final rad = cell * 0.43;
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final v = b[r][c];
        if (v == 0) continue;
        final p = pt(r, c);
        canvas.drawCircle(p + const Offset(1.5, 2.5), rad,
            Paint()..color = const Color(0x44000000));
        final rect = Rect.fromCircle(center: p, radius: rad);
        final grad = RadialGradient(
          center: const Alignment(-0.35, -0.35),
          colors: v == 1
              ? const [Color(0xFF6E6E73), Color(0xFF0E0E10)]
              : const [Color(0xFFFFFFFF), Color(0xFFCDCDD2)],
        );
        canvas.drawCircle(p, rad, Paint()..shader = grad.createShader(rect));
        if (v == 2) {
          canvas.drawCircle(
              p,
              rad,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = const Color(0x33000000)
                ..strokeWidth = 0.8);
        }
      }
    }

    if (last != null) {
      canvas.drawCircle(pt(last![0], last![1]), rad * 0.22,
          Paint()..color = const Color(0xFFFF3B30));
    }
    for (final w in win) {
      canvas.drawCircle(
          pt(w[0], w[1]),
          rad + 2.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = const Color(0xFF34C759)
            ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(covariant _BoardPainter old) => true;
}
