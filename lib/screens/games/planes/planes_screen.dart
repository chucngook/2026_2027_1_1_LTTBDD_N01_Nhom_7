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

const int _n = 10;
const int _planeCount = 3;

/// Máy bay (10 ô): ô đầu tiên (đầu máy bay) đứng trước. Bắn trúng đầu = hạ máy bay.
const List<List<int>> _shape = [
  [0, 2], // đầu
  [1, 0], [1, 1], [1, 2], [1, 3], [1, 4], // cánh
  [2, 2], // thân
  [3, 1], [3, 2], [3, 3], // đuôi
];

List<List<List<int>>> _buildOrients() {
  final res = <List<List<int>>>[];
  var cur = _shape.map((p) => [p[0], p[1]]).toList();
  for (var k = 0; k < 4; k++) {
    res.add(cur.map((p) => List<int>.from(p)).toList());
    cur = cur.map((p) => [p[1], -p[0]]).toList();
  }
  return res;
}

final List<List<List<int>>> _orients = _buildOrients();

/// Các ô tuyệt đối của máy bay khi đặt đầu tại (hr, hc) theo hướng [rot].
List<List<int>> _cellsFor(int hr, int hc, int rot) {
  final o = _orients[rot % 4];
  final h = o[0];
  return o.map((p) => [hr + p[0] - h[0], hc + p[1] - h[1]]).toList();
}

class _Plane {
  final List<List<int>> cells;
  _Plane(this.cells);
}

/// Một phía của bàn chơi.
class _Side {
  final List<List<int>> plane =
      List.generate(_n, (_) => List.filled(_n, -1));
  final List<List<int>> hit =
      List.generate(_n, (_) => List.filled(_n, 0)); // 0 chưa bắn, 1 trượt, 2 trúng thân, 3 trúng đầu
  final List<List<bool>> revealed =
      List.generate(_n, (_) => List.filled(_n, false));
  final List<_Plane> planes = [];
  int downs = 0;

  bool canPlace(List<List<int>> cells) {
    for (final c in cells) {
      if (c[0] < 0 || c[0] >= _n || c[1] < 0 || c[1] >= _n) return false;
      if (plane[c[0]][c[1]] != -1) return false;
    }
    return true;
  }

  void place(List<List<int>> cells) {
    final id = planes.length;
    planes.add(_Plane(cells));
    for (final c in cells) {
      plane[c[0]][c[1]] = id;
    }
  }

  void removeLast() {
    if (planes.isEmpty) return;
    final p = planes.removeLast();
    for (final c in p.cells) {
      plane[c[0]][c[1]] = -1;
    }
  }

  /// Bắn vào ô: trả về 1 (trượt), 2 (trúng thân), 3 (hạ máy bay).
  int fire(int r, int c) {
    if (hit[r][c] != 0) return hit[r][c];
    final id = plane[r][c];
    if (id < 0) {
      hit[r][c] = 1;
    } else {
      final p = planes[id];
      if (p.cells[0][0] == r && p.cells[0][1] == c) {
        hit[r][c] = 3;
        downs++;
        for (final cell in p.cells) {
          revealed[cell[0]][cell[1]] = true;
        }
      } else {
        hit[r][c] = 2;
      }
    }
    return hit[r][c];
  }

  /// Dùng cho bàn của đối thủ (online): chỉ biết kết quả đã được báo.
  void applyResult(int r, int c, int v, List<List<int>> cells) {
    hit[r][c] = v;
    if (v == 3) {
      downs++;
      for (final cell in cells) {
        revealed[cell[0]][cell[1]] = true;
      }
    }
  }

  bool get allDown => downs >= _planeCount;

  List<List<int>> planeCellsAt(int r, int c) {
    final id = plane[r][c];
    return id < 0 ? [] : planes[id].cells;
  }
}

enum _Phase { setup, handover, battle }

class PlanesScreen extends StatefulWidget {
  final MatchConfig config;
  const PlanesScreen({super.key, required this.config});

  @override
  State<PlanesScreen> createState() => _PlanesScreenState();
}

class _PlanesScreenState extends State<PlanesScreen>
    with OnlineGameMixin<PlanesScreen> {
  final Random _rand = Random();

  List<_Side> _sides = [_Side(), _Side()];
  _Phase _phase = _Phase.setup;
  int _setupPlayer = 0;
  int _turn = 0; // người đang bắn
  int _viewer = 0; // (chơi chung máy) ai đang cầm máy
  int _rot = 0;
  List<int>? _ghost; // ô đầu máy bay đang xem trước
  bool _busy = false;
  bool _over = false;
  bool _revealAll = false;
  bool _awaiting = false;
  bool _myReady = false;
  bool _oppReady = false;
  bool _waitRematch = false;
  String _msg = '';
  int _gen = 0;
  final List<int> _wins = [0, 0];
  int _draws = 0;

  // chuyển máy (local)
  String _handoverTo = '';
  VoidCallback? _afterHandover;

  @override
  MatchConfig get config => widget.config;

  int get _me => config.isOnline ? config.myRole : 0;

  @override
  void initState() {
    super.initState();
    _resetAll();
    netInit();
  }

  @override
  void dispose() {
    _gen++;
    netDispose();
    super.dispose();
  }

  void _resetAll() {
    _gen++;
    _sides = [_Side(), _Side()];
    _phase = _Phase.setup;
    _setupPlayer = _me;
    _turn = 0;
    _viewer = 0;
    _rot = 0;
    _ghost = null;
    _busy = false;
    _over = false;
    _revealAll = false;
    _awaiting = false;
    _myReady = false;
    _oppReady = false;
    _waitRematch = false;
    _msg = '';
    if (config.isComputer) _randomPlace(_sides[1]);
  }

  @override
  void onRematch() => setState(_resetAll);

  // ───────── Tên ─────────
  String _name(int p) {
    if (config.isComputer) return p == 0 ? 'Bạn' : 'Máy';
    if (config.isLocal) return 'Người ${p + 1}';
    return p == config.myRole
        ? PlayerService.instance.name
        : (config.session?.oppName ?? 'Đối thủ');
  }

  // ───────── Đặt máy bay ─────────
  void _randomPlace(_Side s) {
    while (s.planes.length < _planeCount) {
      final cells = _cellsFor(_rand.nextInt(_n), _rand.nextInt(_n), _rand.nextInt(4));
      if (s.canPlace(cells)) s.place(cells);
    }
  }

  void _setupTap(int r, int c) {
    final side = _sides[_setupPlayer];
    if (side.planes.length >= _planeCount) return;
    if (_ghost != null && _ghost![0] == r && _ghost![1] == c) {
      final cells = _cellsFor(r, c, _rot);
      if (side.canPlace(cells)) {
        Fx.light();
        Fx.play(Sound.tap);
        setState(() {
          side.place(cells);
          _ghost = null;
        });
      } else {
        Fx.heavy();
      }
    } else {
      Fx.select();
      setState(() => _ghost = [r, c]);
    }
  }

  void _setupReady() {
    final side = _sides[_setupPlayer];
    if (side.planes.length < _planeCount) return;
    Fx.play(Sound.correct);
    if (config.isComputer) {
      setState(() {
        _phase = _Phase.battle;
        _turn = 0;
        _msg = 'Bạn bắn trước. Chạm vào bản đồ đối thủ!';
      });
    } else if (config.isLocal) {
      if (_setupPlayer == 0) {
        _goHandover(_name(1), () {
          setState(() {
            _setupPlayer = 1;
            _viewer = 1;
            _phase = _Phase.setup;
            _ghost = null;
          });
        });
      } else {
        _goHandover(_name(0), () {
          setState(() {
            _turn = 0;
            _viewer = 0;
            _phase = _Phase.battle;
            _msg = '${_name(0)} bắn trước.';
          });
        });
      }
    } else {
      setState(() => _myReady = true);
      sendMove({'k': 'ready'});
      _tryStartOnline();
    }
  }

  void _tryStartOnline() {
    if (_myReady && _oppReady && _phase == _Phase.setup) {
      setState(() {
        _phase = _Phase.battle;
        _turn = 0;
        _msg = _turn == config.myRole ? 'Bạn bắn trước!' : 'Đối thủ bắn trước...';
      });
    }
  }

  void _goHandover(String to, VoidCallback after) {
    setState(() {
      _handoverTo = to;
      _afterHandover = after;
      _phase = _Phase.handover;
    });
  }

  // ───────── Bắn ─────────
  bool get _canShoot {
    if (_phase != _Phase.battle || _busy || _over || _waitRematch) return false;
    if (config.isComputer) return _turn == 0;
    if (config.isOnline) return _turn == config.myRole && !_awaiting;
    return true;
  }

  String _resText(int v) => v == 1 ? 'Trượt!' : (v == 2 ? 'Trúng!' : 'Hạ máy bay!');

  void _playRes(int v) {
    if (v == 1) {
      Fx.light();
      Fx.play(Sound.tap);
    } else if (v == 2) {
      Fx.medium();
      Fx.play(Sound.bomb);
    } else {
      Fx.heavy();
      Fx.play(Sound.coin);
    }
  }

  Future<void> _shoot(int r, int c) async {
    if (!_canShoot) return;
    final attacker = _turn;
    final target = 1 - attacker;
    if (_sides[target].hit[r][c] != 0) return;

    if (config.isOnline) {
      setState(() {
        _awaiting = true;
        _msg = 'Đã bắn... chờ kết quả';
      });
      sendMove({'k': 'shot', 'r': r, 'c': c});
      Fx.light();
      return;
    }

    final gen = _gen;
    final v = _sides[target].fire(r, c);
    _playRes(v);
    setState(() => _msg = '${_name(attacker)}: ${_resText(v)}');
    if (_sides[target].allDown) {
      _finish(attacker);
      return;
    }

    _busy = true;
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted || gen != _gen) return;
    _busy = false;

    if (config.isComputer) {
      setState(() {
        _turn = 1;
        _msg = 'Máy đang ngắm bắn...';
      });
      _aiShoot();
    } else {
      final next = 1 - attacker;
      _goHandover(_name(next), () {
        setState(() {
          _turn = next;
          _viewer = next;
          _phase = _Phase.battle;
          _msg = '${_name(next)} bắn.';
        });
      });
    }
  }

  // ───────── Máy bắn ─────────
  Future<void> _aiShoot() async {
    final gen = _gen;
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted || gen != _gen || _over) return;
    final target = _sides[0];
    final shot = _aiPick(target);
    final v = target.fire(shot[0], shot[1]);
    _playRes(v);
    setState(() => _msg = 'Máy bắn: ${v == 1 ? 'trượt' : (v == 2 ? 'trúng!' : 'hạ một máy bay của bạn!')}');
    if (target.allDown) {
      _finish(1);
      return;
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted || gen != _gen || _over) return;
    setState(() {
      _turn = 0;
      _msg = 'Đến lượt bạn bắn!';
    });
  }

  List<int> _aiPick(_Side t) {
    final unknown = <List<int>>[
      for (var r = 0; r < _n; r++)
        for (var c = 0; c < _n; c++)
          if (t.hit[r][c] == 0) [r, c]
    ];
    final diff = config.difficulty;
    if (diff == 'EASY') return unknown[_rand.nextInt(unknown.length)];

    // Các ô trúng thân chưa được "giải quyết" (chưa hạ máy bay chứa nó)
    final open = <List<int>>[
      for (var r = 0; r < _n; r++)
        for (var c = 0; c < _n; c++)
          if (t.hit[r][c] == 2 && !t.revealed[r][c]) [r, c]
    ];

    if (diff == 'MEDIUM') {
      if (open.isNotEmpty) {
        final cand = <List<int>>[];
        for (final o in open) {
          for (final d in const [
            [1, 0], [-1, 0], [0, 1], [0, -1]
          ]) {
            final r = o[0] + d[0], c = o[1] + d[1];
            if (r >= 0 && r < _n && c >= 0 && c < _n && t.hit[r][c] == 0) {
              cand.add([r, c]);
            }
          }
        }
        if (cand.isNotEmpty) return cand[_rand.nextInt(cand.length)];
      }
      final even = unknown.where((p) => (p[0] + p[1]) % 2 == 0).toList();
      final pool = even.isNotEmpty ? even : unknown;
      return pool[_rand.nextInt(pool.length)];
    }

    // KHÓ: đếm mật độ các cách đặt máy bay còn khả dĩ
    final dens = List.generate(_n, (_) => List.filled(_n, 0.0));
    for (var hr = 0; hr < _n; hr++) {
      for (var hc = 0; hc < _n; hc++) {
        for (var rot = 0; rot < 4; rot++) {
          final cells = _cellsFor(hr, hc, rot);
          var ok = true;
          var w = 1.0;
          for (final cell in cells) {
            final r = cell[0], c = cell[1];
            if (r < 0 || r >= _n || c < 0 || c >= _n) {
              ok = false;
              break;
            }
            if (t.hit[r][c] == 1 || t.revealed[r][c]) {
              ok = false;
              break;
            }
            if (t.hit[r][c] == 2) w *= 8;
          }
          if (!ok) continue;
          for (final cell in cells) {
            if (t.hit[cell[0]][cell[1]] == 0) dens[cell[0]][cell[1]] += w;
          }
        }
      }
    }
    var best = -1.0;
    final top = <List<int>>[];
    for (final u in unknown) {
      final d = dens[u[0]][u[1]];
      if (d > best) {
        best = d;
        top
          ..clear()
          ..add(u);
      } else if (d == best) {
        top.add(u);
      }
    }
    return top[_rand.nextInt(top.length)];
  }

  // ───────── Online: nhận tin ─────────
  @override
  void onNetMove(Map<String, dynamic> d) {
    final k = d['k'];
    final me = config.myRole;
    switch (k) {
      case 'ready':
        _oppReady = true;
        _tryStartOnline();
        break;
      case 'shot':
        if (_over) return;
        final r = (d['r'] as num).toInt(), c = (d['c'] as num).toInt();
        final mine = _sides[me];
        final v = mine.fire(r, c);
        final cells = v == 3 ? mine.planeCellsAt(r, c) : <List<int>>[];
        final lost = mine.allDown;
        sendMove({'k': 'res', 'r': r, 'c': c, 'v': v, 'cells': cells, 'lost': lost});
        _playRes(v);
        setState(() {
          _msg = 'Đối thủ bắn: ${v == 1 ? 'trượt' : (v == 2 ? 'trúng!' : 'hạ máy bay của bạn!')}';
          _turn = me;
        });
        if (lost) _finish(1 - me);
        break;
      case 'res':
        final r = (d['r'] as num).toInt(), c = (d['c'] as num).toInt();
        final v = (d['v'] as num).toInt();
        final cells = (d['cells'] as List)
            .map((e) => (e as List).map((x) => (x as num).toInt()).toList())
            .toList();
        _sides[1 - me].applyResult(r, c, v, cells);
        _playRes(v);
        setState(() {
          _awaiting = false;
          _msg = 'Bạn: ${_resText(v)}';
          _turn = 1 - me;
        });
        if (d['lost'] == true) _finish(me);
        break;
      case 'resign':
        _finish(me, reason: 'Đối thủ đã đầu hàng');
        break;
    }
  }

  void _confirmResign() {
    if (_over || _phase != _Phase.battle) return;
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
              final loser = config.isLocal ? _turn : _me;
              if (config.isOnline) sendMove({'k': 'resign'});
              _finish(1 - loser, reason: 'Đã đầu hàng');
            },
            child: const Text('Đầu hàng'),
          ),
        ],
      ),
    );
  }

  // ───────── Kết thúc ─────────
  Future<void> _finish(int winner, {String reason = ''}) async {
    if (_over) return;
    _over = true;
    _gen++;
    _wins[winner]++;
    final iWon = config.isLocal ? true : winner == _me;
    if (!config.isLocal) {
      StatsService.instance.recordMatch('planes', iWon ? 'win' : 'loss');
    }
    Fx.medium();
    Fx.play(iWon ? Sound.win : Sound.lose);
    setState(() {
      _revealAll = true;
      _busy = false;
    });

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    final title = config.isLocal
        ? '${_name(winner)} thắng!'
        : (iWon ? 'Bạn thắng!' : '${_name(winner)} thắng');
    final replay = await showRoundResult(
      context,
      title: title,
      message:
          '${reason.isNotEmpty ? '$reason\n' : 'Đã hạ hết 3 máy bay!\n'}${_name(0)} ${_wins[0]} - ${_wins[1]} ${_name(1)}${config.isComputer ? '\nĐộ khó: ${GameService.diffName(config.difficulty)}' : ''}',
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
      setState(_resetAll);
    }
  }

  // ───────── Giao diện ─────────
  Widget _grid({
    required double side,
    required _Side data,
    required bool showPlanes,
    List<List<int>>? ghost,
    bool ghostOk = true,
    void Function(int r, int c)? onTap,
  }) {
    final cell = side / _n;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Ios.border, width: 2.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: onTap == null
              ? null
              : (d) {
                  final c = (d.localPosition.dx / cell).floor();
                  final r = (d.localPosition.dy / cell).floor();
                  if (r >= 0 && r < _n && c >= 0 && c < _n) onTap(r, c);
                },
          child: CustomPaint(
            painter: _GridPainter(data, showPlanes, ghost, ghostOk),
          ),
        ),
      ),
    );
  }

  Widget _setupView() {
    final side = _sides[_setupPlayer];
    final count = side.planes.length;
    final ghostCells = _ghost == null ? null : _cellsFor(_ghost![0], _ghost![1], _rot);
    final ghostOk = ghostCells != null && side.canPlace(ghostCells);
    final waiting = config.isOnline && _myReady;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          PlayerCard(
              name: config.isLocal ? _name(_setupPlayer) : _name(_me),
              sub: 'Đặt máy bay: $count/$_planeCount',
              active: true),
          const SizedBox(height: 10),
          Text(
              waiting
                  ? 'Đã sẵn sàng. Chờ đối thủ đặt xong...'
                  : (count < _planeCount
                      ? 'Chạm một ô để xem trước, chạm lại để đặt. Ô trắng là đầu máy bay.'
                      : 'Đã đặt đủ 3 máy bay. Bấm "Sẵn sàng"!'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Ios.label2, fontSize: 14, height: 1.3)),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final s = min(c.maxWidth, c.maxHeight);
              return Center(
                child: _grid(
                  side: s,
                  data: side,
                  showPlanes: true,
                  ghost: ghostCells,
                  ghostOk: ghostOk,
                  onTap: waiting ? null : _setupTap,
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: IosButton(
                  label: 'Xoay',
                  icon: CupertinoIcons.arrow_clockwise,
                  color: Ios.card,
                  textColor: Ios.accent,
                  onPressed: waiting ? null : () => setState(() => _rot = (_rot + 1) % 4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IosButton(
                  label: 'Hoàn tác',
                  color: Ios.card,
                  textColor: Ios.label,
                  onPressed: (waiting || count == 0)
                      ? null
                      : () => setState(() {
                            side.removeLast();
                            _ghost = null;
                          }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: IosButton(
                  label: 'Ngẫu nhiên',
                  color: Ios.card,
                  textColor: Ios.label,
                  onPressed: waiting
                      ? null
                      : () => setState(() {
                            while (side.planes.isNotEmpty) {
                              side.removeLast();
                            }
                            _randomPlace(side);
                            _ghost = null;
                          }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          IosButton(
            label: waiting ? 'Đang chờ...' : 'Sẵn sàng',
            color: Ios.orange,
            onPressed: (count == _planeCount && !waiting) ? _setupReady : null,
          ),
        ],
      ),
    );
  }

  Widget _handoverView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: Ios.box(radius: 30, borderColor: Ios.teal),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🙈', style: TextStyle(fontSize: 56, decoration: TextDecoration.none)),
                const SizedBox(height: 12),
                Text('Đưa máy cho $_handoverTo',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Ios.label,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none)),
                const SizedBox(height: 8),
                const Text('Đừng nhìn màn hình của đối thủ nhé!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Ios.label2, fontSize: 15, decoration: TextDecoration.none)),
                const SizedBox(height: 22),
                IosButton(
                  label: 'Tôi là $_handoverTo, sẵn sàng',
                  color: Ios.orange,
                  onPressed: () {
                    Fx.select();
                    final cb = _afterHandover;
                    _afterHandover = null;
                    cb?.call();
                  },
                ),
              ],
            ),
          ),
        ),
      );

  Widget _battleView() {
    // Ai đang nhìn màn hình?
    final viewer = config.isLocal ? _viewer : _me;
    final enemy = 1 - viewer;
    final mine = _sides[viewer];
    final target = _sides[enemy];
    final mineLeft = _planeCount - mine.downs;
    final enemyLeft = _planeCount - target.downs;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PlayerCard(
                    name: _name(viewer),
                    sub: 'Còn $mineLeft máy bay • thắng ${_wins[viewer]}',
                    active: !_over && _turn == viewer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PlayerCard(
                    name: _name(enemy),
                    sub: 'Còn $enemyLeft máy bay • thắng ${_wins[enemy]}',
                    active: !_over && _turn == enemy),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
              _waitRematch
                  ? 'Chờ đối thủ đồng ý chơi lại...'
                  : (_msg.isEmpty ? ' ' : _msg),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Ios.label, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
              _canShoot ? 'Chạm vào bản đồ đối thủ để bắn' : 'Bản đồ đối thủ',
              style: const TextStyle(color: Ios.label2, fontSize: 12)),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final s = min(c.maxWidth, c.maxHeight);
              return Center(
                child: _grid(
                  side: s,
                  data: target,
                  showPlanes: _revealAll && !config.isOnline,
                  onTap: _canShoot ? _shoot : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _grid(side: 124, data: mine, showPlanes: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Máy bay của bạn',
                        style: TextStyle(
                            color: Ios.label,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Chấm cam: bị trúng thân\nChấm đỏ: bị hạ máy bay',
                        style: TextStyle(color: Ios.label2, fontSize: 12, height: 1.35)),
                    const SizedBox(height: 10),
                    IosButton(
                      label: 'Đầu hàng',
                      color: Ios.card,
                      textColor: Ios.red,
                      onPressed: _over ? null : _confirmResign,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    switch (_phase) {
      case _Phase.setup:
        body = _setupView();
        break;
      case _Phase.handover:
        body = _handoverView();
        break;
      case _Phase.battle:
        body = _battleView();
        break;
    }
    return GameScaffold(title: 'Bắn máy bay', child: body);
  }
}

class _GridPainter extends CustomPainter {
  final _Side data;
  final bool showPlanes;
  final List<List<int>>? ghost;
  final bool ghostOk;

  _GridPainter(this.data, this.showPlanes, this.ghost, this.ghostOk);

  @override
  void paint(Canvas canvas, Size size) {
    final cs = size.width / _n;
    final heads = <int>{for (final p in data.planes) p.cells[0][0] * _n + p.cells[0][1]};

    for (var r = 0; r < _n; r++) {
      for (var c = 0; c < _n; c++) {
        final rect = Rect.fromLTWH(c * cs, r * cs, cs, cs);
        canvas.drawRect(
            rect, Paint()..color = (r + c) % 2 == 0 ? const Color(0xFF2B2521) : const Color(0xFF332C27));

        final isPlane = data.plane[r][c] >= 0;
        final show = (showPlanes && isPlane) || data.revealed[r][c];
        if (show) {
          final destroyed = data.revealed[r][c];
          canvas.drawRRect(
              RRect.fromRectAndRadius(rect.deflate(1.2), Radius.circular(cs * 0.2)),
              Paint()
                ..color = destroyed ? const Color(0x66FF6B5E) : const Color(0xAA4C8FD6));
          if (heads.contains(r * _n + c) && isPlane) {
            canvas.drawCircle(rect.center, cs * 0.16, Paint()..color = const Color(0xFFFFFFFF));
          }
        }

        final h = data.hit[r][c];
        if (h == 1) {
          canvas.drawCircle(rect.center, cs * 0.12, Paint()..color = const Color(0xFFB3A698));
        } else if (h == 2) {
          canvas.drawCircle(rect.center, cs * 0.28, Paint()..color = const Color(0xFFF08A4B));
          canvas.drawCircle(
              rect.center,
              cs * 0.28,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = const Color(0xFF6A3510));
        } else if (h == 3) {
          canvas.drawCircle(rect.center, cs * 0.36, Paint()..color = const Color(0xFFE5392E));
          final x = Paint()
            ..color = const Color(0xFFFFFFFF)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round;
          final d = cs * 0.15;
          canvas.drawLine(rect.center + Offset(-d, -d), rect.center + Offset(d, d), x);
          canvas.drawLine(rect.center + Offset(-d, d), rect.center + Offset(d, -d), x);
        }
      }
    }

    if (ghost != null) {
      final col = ghostOk ? const Color(0x8860C050) : const Color(0x88E53935);
      for (final g in ghost!) {
        if (g[0] < 0 || g[0] >= _n || g[1] < 0 || g[1] >= _n) continue;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(g[1] * cs, g[0] * cs, cs, cs).deflate(1.2),
                Radius.circular(cs * 0.2)),
            Paint()..color = col);
      }
      final hd = ghost!.first;
      if (hd[0] >= 0 && hd[0] < _n && hd[1] >= 0 && hd[1] < _n) {
        canvas.drawCircle(Offset((hd[1] + 0.5) * cs, (hd[0] + 0.5) * cs), cs * 0.16,
            Paint()..color = const Color(0xFFFFFFFF));
      }
    }

    final line = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 0.6;
    for (var i = 1; i < _n; i++) {
      canvas.drawLine(Offset(i * cs, 0), Offset(i * cs, size.height), line);
      canvas.drawLine(Offset(0, i * cs), Offset(size.width, i * cs), line);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => true;
}
