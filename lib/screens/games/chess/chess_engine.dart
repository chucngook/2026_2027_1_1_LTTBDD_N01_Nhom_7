import 'dart:math';

/// Quân cờ: 1 tốt, 2 mã, 3 tượng, 4 xe, 5 hậu, 6 vua. Dương = trắng, âm = đen.
/// Ô đánh số 0..63 = hàng*8 + cột (hàng 0 ở phía quân đen).
class ChessMove {
  final int from, to, promo;
  final bool ep, castle;
  const ChessMove(this.from, this.to,
      {this.promo = 0, this.ep = false, this.castle = false});
}

class ChessPos {
  List<int> b;
  bool wtm;
  List<bool> castle; // [trắng gần, trắng xa, đen gần, đen xa]
  int ep; // ô bắt tốt qua đường, -1 nếu không có
  int half;

  ChessPos(this.b, this.wtm, this.castle, this.ep, this.half);

  factory ChessPos.start() {
    final b = List<int>.filled(64, 0);
    const back = [4, 2, 3, 5, 6, 3, 2, 4];
    for (var c = 0; c < 8; c++) {
      b[c] = -back[c];
      b[8 + c] = -1;
      b[48 + c] = 1;
      b[56 + c] = back[c];
    }
    return ChessPos(b, true, [true, true, true, true], -1, 0);
  }

  ChessPos copy() =>
      ChessPos(List<int>.from(b), wtm, List<bool>.from(castle), ep, half);

  static const List<List<int>> _knight = [
    [-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]
  ];
  static const List<List<int>> _diag = [
    [-1, -1], [-1, 1], [1, -1], [1, 1]
  ];
  static const List<List<int>> _orth = [
    [-1, 0], [1, 0], [0, -1], [0, 1]
  ];

  static bool _in(int r, int c) => r >= 0 && r < 8 && c >= 0 && c < 8;

  bool attacked(int sq, bool byWhite) {
    final r = sq ~/ 8, c = sq % 8;
    final s = byWhite ? 1 : -1;
    final pr = r + (byWhite ? 1 : -1);
    for (final dc in [-1, 1]) {
      final pc = c + dc;
      if (_in(pr, pc) && b[pr * 8 + pc] == s) return true;
    }
    for (final d in _knight) {
      final rr = r + d[0], cc = c + d[1];
      if (_in(rr, cc) && b[rr * 8 + cc] == s * 2) return true;
    }
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final rr = r + dr, cc = c + dc;
        if (_in(rr, cc) && b[rr * 8 + cc] == s * 6) return true;
      }
    }
    for (final d in _diag) {
      var rr = r + d[0], cc = c + d[1];
      while (_in(rr, cc)) {
        final v = b[rr * 8 + cc];
        if (v != 0) {
          if (v == s * 3 || v == s * 5) return true;
          break;
        }
        rr += d[0];
        cc += d[1];
      }
    }
    for (final d in _orth) {
      var rr = r + d[0], cc = c + d[1];
      while (_in(rr, cc)) {
        final v = b[rr * 8 + cc];
        if (v != 0) {
          if (v == s * 4 || v == s * 5) return true;
          break;
        }
        rr += d[0];
        cc += d[1];
      }
    }
    return false;
  }

  int kingSquare(bool white) {
    final k = white ? 6 : -6;
    for (var i = 0; i < 64; i++) {
      if (b[i] == k) return i;
    }
    return -1;
  }

  bool inCheck(bool white) {
    final k = kingSquare(white);
    return k >= 0 && attacked(k, !white);
  }

  void _addPawn(List<ChessMove> res, int from, int to, bool promo) {
    if (promo) {
      for (final p in [5, 4, 3, 2]) {
        res.add(ChessMove(from, to, promo: p));
      }
    } else {
      res.add(ChessMove(from, to));
    }
  }

  List<ChessMove> pseudo() {
    final res = <ChessMove>[];
    for (var i = 0; i < 64; i++) {
      final p = b[i];
      if (p == 0 || (p > 0) != wtm) continue;
      final t = p.abs();
      final r = i ~/ 8, c = i % 8;

      if (t == 1) {
        final dir = wtm ? -1 : 1;
        final startRow = wtm ? 6 : 1;
        final promoRow = wtm ? 0 : 7;
        final nr = r + dir;
        if (nr >= 0 && nr < 8) {
          if (b[nr * 8 + c] == 0) {
            _addPawn(res, i, nr * 8 + c, nr == promoRow);
            if (r == startRow && b[(r + 2 * dir) * 8 + c] == 0) {
              res.add(ChessMove(i, (r + 2 * dir) * 8 + c));
            }
          }
          for (final dc in [-1, 1]) {
            final nc = c + dc;
            if (nc < 0 || nc > 7) continue;
            final ti = nr * 8 + nc;
            final tp = b[ti];
            if (tp != 0 && (tp > 0) != wtm) {
              _addPawn(res, i, ti, nr == promoRow);
            } else if (ti == ep) {
              res.add(ChessMove(i, ti, ep: true));
            }
          }
        }
      } else if (t == 2) {
        for (final d in _knight) {
          final rr = r + d[0], cc = c + d[1];
          if (!_in(rr, cc)) continue;
          final tp = b[rr * 8 + cc];
          if (tp == 0 || (tp > 0) != wtm) res.add(ChessMove(i, rr * 8 + cc));
        }
      } else if (t == 6) {
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final rr = r + dr, cc = c + dc;
            if (!_in(rr, cc)) continue;
            final tp = b[rr * 8 + cc];
            if (tp == 0 || (tp > 0) != wtm) res.add(ChessMove(i, rr * 8 + cc));
          }
        }
        if (wtm && i == 60) {
          if (castle[0] && b[61] == 0 && b[62] == 0 && b[63] == 4 &&
              !attacked(60, false) && !attacked(61, false) && !attacked(62, false)) {
            res.add(const ChessMove(60, 62, castle: true));
          }
          if (castle[1] && b[59] == 0 && b[58] == 0 && b[57] == 0 && b[56] == 4 &&
              !attacked(60, false) && !attacked(59, false) && !attacked(58, false)) {
            res.add(const ChessMove(60, 58, castle: true));
          }
        } else if (!wtm && i == 4) {
          if (castle[2] && b[5] == 0 && b[6] == 0 && b[7] == -4 &&
              !attacked(4, true) && !attacked(5, true) && !attacked(6, true)) {
            res.add(const ChessMove(4, 6, castle: true));
          }
          if (castle[3] && b[3] == 0 && b[2] == 0 && b[1] == 0 && b[0] == -4 &&
              !attacked(4, true) && !attacked(3, true) && !attacked(2, true)) {
            res.add(const ChessMove(4, 2, castle: true));
          }
        }
      } else {
        final dirs = t == 3 ? _diag : (t == 4 ? _orth : [..._diag, ..._orth]);
        for (final d in dirs) {
          var rr = r + d[0], cc = c + d[1];
          while (_in(rr, cc)) {
            final tp = b[rr * 8 + cc];
            if (tp == 0) {
              res.add(ChessMove(i, rr * 8 + cc));
            } else {
              if ((tp > 0) != wtm) res.add(ChessMove(i, rr * 8 + cc));
              break;
            }
            rr += d[0];
            cc += d[1];
          }
        }
      }
    }
    return res;
  }

  ChessPos apply(ChessMove m) {
    final n = copy();
    final p = n.b[m.from];
    final t = p.abs();
    final white = p > 0;
    final captured = n.b[m.to];

    n.b[m.to] = m.promo != 0 ? (white ? m.promo : -m.promo) : p;
    n.b[m.from] = 0;
    if (m.ep) n.b[(m.from ~/ 8) * 8 + (m.to % 8)] = 0;
    if (m.castle) {
      if (m.to == 62) {
        n.b[61] = n.b[63];
        n.b[63] = 0;
      } else if (m.to == 58) {
        n.b[59] = n.b[56];
        n.b[56] = 0;
      } else if (m.to == 6) {
        n.b[5] = n.b[7];
        n.b[7] = 0;
      } else if (m.to == 2) {
        n.b[3] = n.b[0];
        n.b[0] = 0;
      }
    }
    if (t == 6) {
      if (white) {
        n.castle[0] = false;
        n.castle[1] = false;
      } else {
        n.castle[2] = false;
        n.castle[3] = false;
      }
    }
    for (final sq in [m.from, m.to]) {
      if (sq == 63) n.castle[0] = false;
      if (sq == 56) n.castle[1] = false;
      if (sq == 7) n.castle[2] = false;
      if (sq == 0) n.castle[3] = false;
    }
    n.ep = (t == 1 && (m.to - m.from).abs() == 16) ? (m.from + m.to) ~/ 2 : -1;
    n.half = (t == 1 || captured != 0 || m.ep) ? 0 : n.half + 1;
    n.wtm = !wtm;
    return n;
  }

  List<ChessMove> legal() {
    final res = <ChessMove>[];
    for (final m in pseudo()) {
      if (!apply(m).inCheck(wtm)) res.add(m);
    }
    return res;
  }

  bool insufficientMaterial() {
    final others = <int>[];
    for (final v in b) {
      if (v != 0 && v.abs() != 6) others.add(v.abs());
    }
    if (others.isEmpty) return true;
    return others.length == 1 && (others.first == 2 || others.first == 3);
  }
}

/// Máy chơi cờ: tìm kiếm negamax + cắt tỉa alpha-beta.
class ChessAI {
  static const List<int> _val = [0, 100, 320, 330, 500, 900, 0];
  final Random rnd;
  ChessAI(this.rnd);

  int _eval(ChessPos p) {
    var s = 0;
    for (var i = 0; i < 64; i++) {
      final v = p.b[i];
      if (v == 0) continue;
      final t = v.abs();
      final r = i ~/ 8, c = i % 8;
      var score = _val[t];
      final cd = (3.5 - (c - 3.5).abs()) + (3.5 - (r - 3.5).abs());
      if (t == 2 || t == 3) score += (cd * 4).round();
      if (t == 1) {
        final adv = v > 0 ? (6 - r) : (r - 1);
        score += adv * 6 + ((c >= 2 && c <= 5) ? 3 : 0);
      }
      s += v > 0 ? score : -score;
    }
    return s;
  }

  int _orderScore(ChessPos p, ChessMove m) {
    var s = 0;
    final cap = p.b[m.to];
    if (cap != 0) s += _val[cap.abs()] * 10 - _val[p.b[m.from].abs()];
    if (m.promo != 0) s += 800;
    return s;
  }

  int _search(ChessPos p, int depth, int alpha, int beta) {
    final moves = p.legal();
    if (moves.isEmpty) return p.inCheck(p.wtm) ? -100000 - depth : 0;
    if (p.half >= 100 || p.insufficientMaterial()) return 0;
    if (depth == 0) return _eval(p) * (p.wtm ? 1 : -1);
    moves.sort((a, b) => _orderScore(p, b).compareTo(_orderScore(p, a)));
    var best = -1000000;
    for (final m in moves) {
      final score = -_search(p.apply(m), depth - 1, -beta, -alpha);
      if (score > best) best = score;
      if (best > alpha) alpha = best;
      if (alpha >= beta) break;
    }
    return best;
  }

  ChessMove? bestMove(ChessPos p, String diff) {
    final moves = p.legal();
    if (moves.isEmpty) return null;
    if (diff == 'EASY' && rnd.nextDouble() < 0.5) {
      return moves[rnd.nextInt(moves.length)];
    }
    final depth = diff == 'HARD' ? 3 : (diff == 'MEDIUM' ? 2 : 1);
    moves.sort((a, b) => _orderScore(p, b).compareTo(_orderScore(p, a)));

    var bestScore = -10000000;
    final best = <ChessMove>[];
    for (final m in moves) {
      final score = -_search(p.apply(m), depth - 1, -1000000, 1000000);
      if (score > bestScore) {
        bestScore = score;
        best
          ..clear()
          ..add(m);
      } else if (score == bestScore) {
        best.add(m);
      }
    }
    return best[rnd.nextInt(best.length)];
  }
}
