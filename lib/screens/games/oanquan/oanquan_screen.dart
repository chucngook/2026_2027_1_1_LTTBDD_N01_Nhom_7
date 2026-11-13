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

/// Trạng thái bàn Ô ăn quan: 12 ô theo vòng tròn.
/// Ô 0 và 6 là ô Quan; ô 1..5 của người chơi 0; ô 7..11 của người chơi 1.
class _OState {
  List<int> dan;
  List<int> quan;
  List<int> score;
  _OState(this.dan, this.quan, this.score);

  factory _OState.start() => _OState(
        [0, 5, 5, 5, 5, 5, 0, 5, 5, 5, 5, 5],
        [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0],
        [0, 0],
      );

  _OState copy() =>
      _OState(List<int>.from(dan), List<int>.from(quan), List<int>.from(score));

  bool heavy(int i) => quan[i] > 0;
  bool empty(int i) => dan[i] == 0 && quan[i] == 0;
}

class OanQuanScreen extends StatefulWidget {
  final MatchConfig config;
  const OanQuanScreen({super.key, required this.config});

  @override
  State<OanQuanScreen> createState() => _OanQuanScreenState();
}

class _OanQuanScreenState extends State<OanQuanScreen>
    with OnlineGameMixin<OanQuanScreen> {
  final Random _rand = Random();

  _OState _st = _OState.start();
  int _turn = 0; // người chơi đang đi: 0 (dưới) hoặc 1 (trên)
  int? _selected;
  bool _busy = false;
  bool _over = false;
  bool _waitRematch = false;
  int _gen = 0;
  final List<int> _wins = [0, 0];
  int _draws = 0;
  String _note = '';

  @override
  MatchConfig get config => widget.config;

  bool get _flipped => config.isOnline && config.myRole == 1;

  @override
  void initState() {
    super.initState();
    netInit();
  }

  @override
  void dispose() {
    _gen++;
    netDispose();
    super.dispose();
  }

  void _newGame() {
    setState(() {
      _gen++;
      _st = _OState.start();
      _turn = 0;
      _selected = null;
      _busy = false;
      _over = false;
      _waitRematch = false;
      _note = '';
    });
  }

  @override
  void onRematch() => _newGame();

  // ───────── Luật chơi (hàm thuần, dùng cho cả AI) ─────────
  List<int> _own(int player) =>
      player == 0 ? [1, 2, 3, 4, 5] : [7, 8, 9, 10, 11];

  bool _hasStones(_OState s, int player) =>
      _own(player).any((i) => s.dan[i] > 0);

  /// Rải quân từ [cell] theo hướng [dir] (+1/-1); trả về từng bước để làm hoạt ảnh.
  List<_OState> _simulate(_OState start, int cell, int dir, int player) {
    final s = start.copy();
    final snaps = <_OState>[];
    void snap() => snaps.add(s.copy());

    var hand = s.dan[cell];
    s.dan[cell] = 0;
    var pos = cell;
    snap();
    var guard = 0;

    while (guard++ < 300) {
      while (hand > 0) {
        pos = (pos + dir + 12) % 12;
        s.dan[pos]++;
        hand--;
        snap();
      }
      final next = (pos + dir + 12) % 12;
      if (s.heavy(next)) break; // gặp ô Quan còn quan: dừng lượt
      if (s.dan[next] > 0) {
        hand = s.dan[next];
        s.dan[next] = 0;
        pos = next;
        snap();
        continue;
      }
      // Ô kế tiếp trống: nếu ô sau đó có quân thì ăn
      var after = (next + dir + 12) % 12;
      if (!s.empty(after)) {
        while (true) {
          s.score[player] += s.dan[after] + s.quan[after] * 10;
          s.dan[after] = 0;
          s.quan[after] = 0;
          snap();
          final n2 = (after + dir + 12) % 12;
          final a2 = (n2 + dir + 12) % 12;
          if (s.empty(n2) && !s.empty(a2)) {
            after = a2;
            continue;
          }
          break;
        }
      }
      break;
    }
    return snaps;
  }

  List<List<int>> _movesFor(_OState s, int player) => [
        for (final c in _own(player))
          if (s.dan[c] > 0)
            for (final d in [1, -1]) [c, d]
      ];

  // ───────── AI (người chơi 1) ─────────
  List<int> _pickAi() {
    final moves = _movesFor(_st, 1);
    final diff = config.difficulty;
    if (diff == 'EASY') return moves[_rand.nextInt(moves.length)];

    double value(List<int> m) {
      final s1 = _simulate(_st, m[0], m[1], 1).last;
      final base = (s1.score[1] - s1.score[0]).toDouble();
      if (diff == 'MEDIUM') return base + _rand.nextDouble() * 0.5;
      // HARD: xét cả phản đòn tốt nhất của đối thủ
      final replies = _movesFor(s1, 0);
      if (replies.isEmpty) return base;
      var worst = 1e9;
      for (final r in replies) {
        final s2 = _simulate(s1, r[0], r[1], 0).last;
        final v = (s2.score[1] - s2.score[0]).toDouble();
        if (v < worst) worst = v;
      }
      return worst + _rand.nextDouble() * 0.3;
    }

    var best = moves.first;
    var bestV = -1e9;
    for (final m in moves) {
      final v = value(m);
      if (v > bestV) {
        bestV = v;
        best = m;
      }
    }
    return best;
  }

  // ───────── Diễn biến ─────────
  bool get _canAct {
    if (_over || _busy || _waitRematch) return false;
    if (config.isComputer) return _turn == 0;
    if (config.isOnline) return _turn == config.myRole;
    return true;
  }

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
    if (_busy) return 'Đang rải quân...';
    if (config.isComputer && _turn == 1) return 'Máy đang suy nghĩ...';
    if (config.isOnline && _turn != config.myRole) return 'Chờ ${_name(_turn)} đi...';
    return 'Đến lượt ${_name(_turn)}';
  }

  void _onTapCell(int idx) {
    if (!_canAct) return;
    if (!_own(_turn).contains(idx) || _st.dan[idx] == 0) return;
    Fx.select();
    setState(() => _selected = idx);
  }

  List<int> get _bottomRow => _flipped ? [7, 8, 9, 10, 11] : [1, 2, 3, 4, 5];
  List<int> get _topRow => _flipped ? [5, 4, 3, 2, 1] : [11, 10, 9, 8, 7];

  /// Hướng "sang phải" theo màn hình của ô [idx].
  int _screenRight(int idx) => _bottomRow.contains(idx) ? 1 : -1;

  @override
  void onNetMove(Map<String, dynamic> d) {
    if (_over) return;
    if (d.containsKey('resign')) {
      _finishGame(forcedWinner: config.myRole, reason: 'Đối thủ đã đầu hàng');
      return;
    }
    _doMove((d['c'] as num).toInt(), (d['d'] as num).toInt(), remote: true);
  }

  Future<void> _doMove(int cell, int dir, {bool remote = false}) async {
    if (_busy || _over) return;
    _busy = true;
    final gen = _gen;
    final player = _turn;
    if (!remote && config.isOnline) sendMove({'c': cell, 'd': dir});

    final before = _st.score[player];
    setState(() => _selected = null);
    final snaps = _simulate(_st, cell, dir, player);
    for (final sn in snaps) {
      if (!mounted || gen != _gen) return;
      setState(() => _st = sn);
      Fx.select();
      await Future.delayed(const Duration(milliseconds: 210));
    }
    if (!mounted || gen != _gen) return;
    final gained = _st.score[player] - before;
    if (gained > 0) {
      Fx.medium();
      Fx.play(Sound.coin);
    }
    setState(() => _note = gained > 0 ? '${_name(player)} ăn được $gained điểm!' : '');
    _busy = false;
    _advanceTurn();
  }

  void _advanceTurn() {
    if (_st.quan[0] == 0 && _st.quan[6] == 0) {
      _finishGame();
      return;
    }
    final next = 1 - _turn;
    setState(() => _turn = next);

    if (!_hasStones(_st, next)) {
      if (_st.score[next] >= 5) {
        setState(() {
          _st.score[next] -= 5;
          for (final c in _own(next)) {
            _st.dan[c] = 1;
          }
          _note = '${_name(next)} hết quân, phải rải 5 điểm vào bàn.';
        });
      } else {
        _finishGame();
        return;
      }
    }

    if (config.isComputer && _turn == 1) {
      final gen = _gen;
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted || gen != _gen || _over) return;
        final m = _pickAi();
        _doMove(m[0], m[1]);
      });
    }
  }

  void _confirmResign() {
    if (_over || _busy) return;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Đầu hàng?'),
        content: const Text('Bạn sẽ thua ván này.'),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tiếp tục chơi')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              final loser = config.isLocal ? _turn : config.myRole;
              if (config.isOnline) sendMove({'resign': 1});
              _finishGame(forcedWinner: 1 - loser, reason: 'Đã đầu hàng');
            },
            child: const Text('Đầu hàng'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishGame({int? forcedWinner, String reason = ''}) async {
    if (_over) return;
    _over = true;
    _gen++;

    // Mỗi người thu số quân còn lại ở phía mình
    final s = _st.copy();
    for (final c in _own(0)) {
      s.score[0] += s.dan[c];
      s.dan[c] = 0;
    }
    for (final c in _own(1)) {
      s.score[1] += s.dan[c];
      s.dan[c] = 0;
    }
    setState(() => _st = s);

    int winner;
    if (forcedWinner != null) {
      winner = forcedWinner;
    } else if (s.score[0] > s.score[1]) {
      winner = 0;
    } else if (s.score[1] > s.score[0]) {
      winner = 1;
    } else {
      winner = -1;
    }
    if (winner == -1) {
      _draws++;
    } else {
      _wins[winner]++;
    }

    final me = config.isOnline ? config.myRole : 0;
    final iWon = config.isLocal ? winner != -1 : winner == me;
    if (!config.isLocal) {
      StatsService.instance
          .recordMatch('oanquan', winner == -1 ? 'draw' : (iWon ? 'win' : 'loss'));
    }
    Fx.medium();
    Fx.play(winner == -1 ? Sound.tap : (iWon ? Sound.win : Sound.lose));

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    final title = winner == -1
        ? 'Hòa!'
        : (config.isLocal
            ? '${_name(winner)} thắng!'
            : (iWon ? 'Bạn thắng!' : '${_name(winner)} thắng'));
    final replay = await showRoundResult(
      context,
      title: title,
      message:
          '${reason.isNotEmpty ? '$reason\n' : ''}${_name(0)} ${s.score[0]} - ${s.score[1]} ${_name(1)}${config.isComputer ? '\nĐộ khó: ${GameService.diffName(config.difficulty)}' : ''}',
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
      _newGame();
    }
  }

  // ───────── Giao diện ─────────
  Widget _stones(int dan, int quan, double size) {
    final dots = <Widget>[
      for (var i = 0; i < quan; i++)
        Container(
          width: size * 0.34,
          height: size * 0.34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Ios.yellow,
            border: Border.all(color: const Color(0xFF8A5A00), width: 2),
          ),
        ),
      for (var i = 0; i < min(dan, 14); i++)
        Container(
          width: size * 0.17,
          height: size * 0.17,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0xFFF5E6C8)),
        ),
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 2,
      runSpacing: 2,
      children: dots,
    );
  }

  Widget _cell(int idx, double w, double h, {bool isQuan = false}) {
    final mine = _own(_turn).contains(idx) && _st.dan[idx] > 0;
    final selectable = _canAct && mine;
    final sel = _selected == idx;
    final total = _st.dan[idx] + _st.quan[idx] * 10;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTapCell(idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: w,
        height: h,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: sel
              ? const Color(0xFF6A4524)
              : (isQuan ? const Color(0xFF4B3B2B) : const Color(0xFF3B2F25)),
          borderRadius: BorderRadius.circular(isQuan ? w * 0.45 : 18),
          border: Border.all(
              color: sel
                  ? Ios.orange
                  : (selectable ? Ios.green : const Color(0xFF5E4C3A)),
              width: sel || selectable ? 3 : 2),
        ),
        child: Stack(
          children: [
            Center(child: _stones(_st.dan[idx], _st.quan[idx], min(w, h))),
            Positioned(
              right: 2,
              bottom: 0,
              child: Text(total > 0 ? '$total' : '',
                  style: const TextStyle(
                      color: Ios.label2,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boardView(double width) {
    const pad = 10.0, gap = 6.0;
    final quanW = width * 0.17;
    final cellW = (width - pad * 2 - quanW * 2 - gap * 6) / 5;
    final cellH = cellW * 1.05;
    final leftQuan = _flipped ? 6 : 0;
    final rightQuan = _flipped ? 0 : 6;

    Widget row(List<int> cells) => Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              _cell(cells[i], cellW, cellH),
            ],
          ],
        );

    return Container(
      width: width,
      padding: const EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2018),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF6B4A2E), width: 3),
      ),
      child: Row(
        children: [
          _cell(leftQuan, quanW, cellH * 2 + gap, isQuan: true),
          const SizedBox(width: gap),
          Column(
            children: [
              row(_topRow),
              const SizedBox(height: gap),
              row(_bottomRow),
            ],
          ),
          const SizedBox(width: gap),
          _cell(rightQuan, quanW, cellH * 2 + gap, isQuan: true),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sel = _selected;
    final canDir = sel != null && _canAct;
    final topPlayer = _flipped ? 0 : 1;
    final bottomPlayer = 1 - topPlayer;

    return GameScaffold(
      title: 'Ô ăn quan',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            PlayerCard(
              name: _name(topPlayer),
              sub: 'Điểm: ${_st.score[topPlayer]} • thắng ${_wins[topPlayer]}',
              active: !_over && _turn == topPlayer,
            ),
            const SizedBox(height: 10),
            Text(_status,
                style: const TextStyle(
                    color: Ios.label, fontSize: 16, fontWeight: FontWeight.w800)),
            SizedBox(
              height: 22,
              child: Text(_note,
                  style: const TextStyle(color: Ios.yellow, fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                return Center(child: _boardView(c.maxWidth));
              }),
            ),
            const SizedBox(height: 10),
            PlayerCard(
              name: _name(bottomPlayer),
              sub: 'Điểm: ${_st.score[bottomPlayer]} • thắng ${_wins[bottomPlayer]}',
              active: !_over && _turn == bottomPlayer,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: IosButton(
                    label: 'Rải sang trái',
                    icon: CupertinoIcons.arrow_left,
                    color: Ios.orange,
                    onPressed: canDir ? () => _doMove(sel, -_screenRight(sel)) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: IosButton(
                    label: 'Rải sang phải',
                    icon: CupertinoIcons.arrow_right,
                    color: Ios.orange,
                    onPressed: canDir ? () => _doMove(sel, _screenRight(sel)) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!config.isOnline)
                  Expanded(
                    child: IosButton(
                        label: 'Ván mới',
                        color: Ios.card,
                        textColor: Ios.accent,
                        onPressed: _newGame),
                  ),
                if (!config.isOnline) const SizedBox(width: 10),
                Expanded(
                  child: IosButton(
                      label: 'Đầu hàng',
                      color: Ios.card,
                      textColor: Ios.red,
                      onPressed: (_over || _busy) ? null : _confirmResign),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Chạm một ô của bạn, rồi chọn hướng rải (theo màn hình)',
                style: TextStyle(color: Ios.label2, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
