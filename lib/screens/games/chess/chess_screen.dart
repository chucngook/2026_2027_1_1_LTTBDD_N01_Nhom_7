import 'dart:math';
import 'package:flutter/cupertino.dart' hide Text;
import '../../../widgets/tr_text.dart';
import '../../../constants/app_assets.dart';
import '../../../data/game_service.dart';
import '../../../services/fx.dart';
import '../../../services/online_service.dart';
import '../../../services/player_service.dart';
import '../../../services/stats_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/ios_widgets.dart';
import '../../../widgets/online_game_mixin.dart';
import '../../../widgets/recess_ui.dart';
import 'chess_engine.dart';

/// Cờ vua đầy đủ luật: nhập thành, bắt tốt qua đường, phong cấp, chiếu hết, hòa.
class ChessScreen extends StatefulWidget {
  final MatchConfig config;
  const ChessScreen({super.key, required this.config});

  @override
  State<ChessScreen> createState() => _ChessScreenState();
}

class _ChessScreenState extends State<ChessScreen> with OnlineGameMixin<ChessScreen> {
  static const String _kinds = ' pnbrqk';

  final Random _rand = Random();
  late final ChessAI _ai = ChessAI(_rand);

  ChessPos _pos = ChessPos.start();
  List<ChessMove> _legal = [];
  int? _sel;
  List<ChessMove> _selMoves = [];
  ChessMove? _lastMove;
  bool _over = false;
  bool _thinking = false;
  bool _waitRematch = false;
  int _gen = 0;
  final List<int> _wins = [0, 0]; // [Trắng, Đen]
  int _draws = 0;

  @override
  MatchConfig get config => widget.config;

  bool get _flipped => config.isOnline && config.myRole == 1;

  /// Mình cầm quân trắng? (chơi với máy: luôn trắng; online: chủ bàn cầm trắng)
  bool get _iAmWhite => config.isOnline ? config.myRole == 0 : true;

  @override
  void initState() {
    super.initState();
    _legal = _pos.legal();
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
      _pos = ChessPos.start();
      _legal = _pos.legal();
      _sel = null;
      _selMoves = [];
      _lastMove = null;
      _over = false;
      _thinking = false;
      _waitRematch = false;
    });
  }

  @override
  void onRematch() => _newGame();

  // ───────── Tên & trạng thái ─────────
  String _name(bool white) {
    if (config.isComputer) return white ? 'Bạn' : 'Máy';
    if (config.isLocal) return white ? 'Người 1' : 'Người 2';
    final mine = white == _iAmWhite;
    return mine
        ? PlayerService.instance.name
        : (config.session?.oppName ?? 'Đối thủ');
  }

  String get _status {
    if (_waitRematch) return 'Chờ đối thủ đồng ý chơi lại...';
    if (_over) return 'Ván đã kết thúc';
    final chk = _pos.inCheck(_pos.wtm) ? ' • Chiếu!' : '';
    if (config.isComputer && !_pos.wtm) return 'Máy đang suy nghĩ...$chk';
    if (config.isOnline && _pos.wtm != _iAmWhite) {
      return 'Chờ ${_name(_pos.wtm)} đi...$chk';
    }
    return 'Đến lượt ${_name(_pos.wtm)} (${_pos.wtm ? 'Trắng' : 'Đen'})$chk';
  }

  bool get _canMove {
    if (_over || _thinking || _waitRematch) return false;
    if (config.isComputer) return _pos.wtm;
    if (config.isOnline) return _pos.wtm == _iAmWhite;
    return true;
  }

  // ───────── Thao tác ─────────
  void _onTap(int sq) {
    if (!_canMove) return;
    final p = _pos.b[sq];
    if (_sel != null) {
      final cands = _selMoves.where((m) => m.to == sq).toList();
      if (cands.isNotEmpty) {
        _choose(cands);
        return;
      }
    }
    if (p != 0 && (p > 0) == _pos.wtm) {
      Fx.select();
      setState(() {
        _sel = sq;
        _selMoves = _legal.where((m) => m.from == sq).toList();
      });
    } else {
      setState(() {
        _sel = null;
        _selMoves = [];
      });
    }
  }

  Future<void> _choose(List<ChessMove> cands) async {
    ChessMove m;
    if (cands.length == 1) {
      m = cands.first;
    } else {
      final pr = await showCupertinoModalPopup<int>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Phong cấp tốt thành...'),
          actions: [
            for (final e in const [
              [5, 'Hậu'],
              [4, 'Xe'],
              [3, 'Tượng'],
              [2, 'Mã']
            ])
              CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, e[0] as int),
                child: Text(e[1] as String),
              ),
          ],
        ),
      );
      if (pr == null) return;
      m = cands.firstWhere((c) => c.promo == pr);
    }
    _play(m);
  }

  @override
  void onNetMove(Map<String, dynamic> d) {
    if (_over) return;
    if (d.containsKey('resign')) {
      _finish(_iAmWhite ? 1 : -1, 'Đối thủ đã đầu hàng');
      return;
    }
    final f = (d['f'] as num).toInt(), t = (d['t'] as num).toInt();
    final p = (d['p'] as num?)?.toInt() ?? 0;
    final found = _legal.where((m) => m.from == f && m.to == t && m.promo == p);
    if (found.isNotEmpty) _play(found.first, remote: true);
  }

  void _play(ChessMove m, {bool remote = false}) {
    final capture = _pos.b[m.to] != 0 || m.ep;
    setState(() {
      _pos = _pos.apply(m);
      _lastMove = m;
      _sel = null;
      _selMoves = [];
      _legal = _pos.legal();
    });
    Fx.light();
    Fx.play(capture ? Sound.flip : Sound.tap);
    if (!remote && config.isOnline) {
      sendMove({'f': m.from, 't': m.to, 'p': m.promo});
    }
    _afterMove();
  }

  void _afterMove() {
    if (_legal.isEmpty) {
      if (_pos.inCheck(_pos.wtm)) {
        _finish(_pos.wtm ? -1 : 1, 'Chiếu hết!');
      } else {
        _finish(0, 'Hòa (hết nước đi)');
      }
      return;
    }
    if (_pos.insufficientMaterial()) {
      _finish(0, 'Hòa (không đủ quân chiếu hết)');
      return;
    }
    if (_pos.half >= 100) {
      _finish(0, 'Hòa (luật 50 nước)');
      return;
    }
    if (_pos.inCheck(_pos.wtm)) Fx.play(Sound.wrong);

    if (config.isComputer && !_pos.wtm) {
      final gen = _gen;
      setState(() => _thinking = true);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted || gen != _gen || _over) return;
        final m = _ai.bestMove(_pos, config.difficulty);
        setState(() => _thinking = false);
        if (m != null) _play(m);
      });
    }
  }

  void _confirmResign() {
    if (_over) return;
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
              final loserWhite = config.isLocal ? _pos.wtm : _iAmWhite;
              if (config.isOnline) sendMove({'resign': 1});
              _finish(loserWhite ? -1 : 1, 'Đã đầu hàng');
            },
            child: const Text('Đầu hàng'),
          ),
        ],
      ),
    );
  }

  /// winner: 1 = Trắng thắng, -1 = Đen thắng, 0 = hòa
  Future<void> _finish(int winner, String reason) async {
    if (_over) return;
    _over = true;
    _gen++;
    if (winner == 1) _wins[0]++;
    if (winner == -1) _wins[1]++;
    if (winner == 0) _draws++;

    final iWon = config.isLocal ? winner != 0 : (winner == 1) == _iAmWhite && winner != 0;
    if (!config.isLocal) {
      StatsService.instance
          .recordMatch('chess', winner == 0 ? 'draw' : (iWon ? 'win' : 'loss'));
    }
    Fx.medium();
    Fx.play(winner == 0 ? Sound.tap : (iWon ? Sound.win : Sound.lose));
    setState(() {});

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final title = winner == 0
        ? 'Hòa cờ'
        : (config.isLocal
            ? '${_name(winner == 1)} thắng!'
            : (iWon ? 'Bạn thắng!' : '${_name(winner == 1)} thắng'));
    final replay = await showRoundResult(
      context,
      title: title,
      message:
          '$reason\n${_name(true)} ${_wins[0]} - ${_wins[1]} ${_name(false)}${config.isComputer ? '\nĐộ khó: ${GameService.diffName(config.difficulty)}' : ''}',
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
  Widget _square(int sq, double size) {
    final r = sq ~/ 8, c = sq % 8;
    final dark = (r + c) % 2 == 1;
    final piece = _pos.b[sq];
    final isSel = _sel == sq;
    final isLast = _lastMove != null && (_lastMove!.from == sq || _lastMove!.to == sq);
    final target = _selMoves.where((m) => m.to == sq).isNotEmpty;
    final inCheckSq = piece.abs() == 6 && (piece > 0) == _pos.wtm && _pos.inCheck(_pos.wtm);

    Color bg = dark ? const Color(0xFFA77B52) : const Color(0xFFEBD2A8);
    if (isLast) bg = Color.alphaBlend(const Color(0x66F2D23C), bg);
    if (isSel) bg = Color.alphaBlend(const Color(0x8860C050), bg);
    if (inCheckSq) bg = Color.alphaBlend(const Color(0xAAE53935), bg);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _onTap(sq),
      child: Container(
        width: size,
        height: size,
        color: bg,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (piece != 0)
              Padding(
                padding: EdgeInsets.all(size * 0.04),
                child: Image.asset(
                    AppImages.chess(piece > 0 ? 'w' : 'b', _kinds[piece.abs()]),
                    fit: BoxFit.contain),
              ),
            if (target)
              piece == 0
                  ? Container(
                      width: size * 0.3,
                      height: size * 0.3,
                      decoration: const BoxDecoration(
                          color: Color(0x8840A040), shape: BoxShape.circle))
                  : Container(
                      width: size * 0.9,
                      height: size * 0.9,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xAA40A040), width: 4))),
          ],
        ),
      ),
    );
  }

  Widget _board(double side) {
    final cell = side / 8;
    return SizedBox(
      width: side,
      height: side,
      child: Column(
        children: List.generate(8, (vr) {
          final r = _flipped ? 7 - vr : vr;
          return Row(
            children: List.generate(8, (vc) {
              final c = _flipped ? 7 - vc : vc;
              return _square(r * 8 + c, cell);
            }),
          );
        }),
      ),
    );
  }

  Widget _card(bool white) => PlayerCard(
        name: _name(white),
        sub: '${white ? 'Quân trắng' : 'Quân đen'} • thắng ${_wins[white ? 0 : 1]}',
        leading: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: white ? const Color(0xFFFFF8EE) : const Color(0xFF2E2622),
            border: Border.all(color: const Color(0xFF8A7A6A), width: 2),
          ),
        ),
        active: !_over && _pos.wtm == white,
      );

  @override
  Widget build(BuildContext context) {
    final topWhite = _flipped;
    return GameScaffold(
      title: 'Cờ vua',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _card(topWhite),
            const SizedBox(height: 10),
            Text(_status,
                style: const TextStyle(
                    color: Ios.label, fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final side = min(c.maxWidth, c.maxHeight);
                return Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6B4A2E), width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _board(side - 6),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            _card(!topWhite),
            const SizedBox(height: 12),
            Row(
              children: [
                if (!config.isOnline)
                  Expanded(
                    child: IosButton(
                      label: 'Ván mới',
                      icon: CupertinoIcons.arrow_counterclockwise,
                      color: Ios.card,
                      textColor: Ios.accent,
                      onPressed: _newGame,
                    ),
                  ),
                if (!config.isOnline) const SizedBox(width: 10),
                Expanded(
                  child: IosButton(
                    label: 'Đầu hàng',
                    color: Ios.card,
                    textColor: Ios.red,
                    onPressed: _over ? null : _confirmResign,
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
