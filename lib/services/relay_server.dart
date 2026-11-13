// Máy chủ trung chuyển của Playtime (chỉ dùng dart:io, KHÔNG phụ thuộc Flutter).
// Dùng ở hai nơi:
//  - Trong app: một điện thoại làm "chủ bàn" (chơi qua Wi-Fi, không cần máy chủ riêng).
//  - Độc lập:   `dart server/server.dart` (chơi từ xa qua Internet).
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class _Client {
  final WebSocket ws;
  String name = 'Ẩn danh';
  String emoji = '🙂';
  String id = '';
  bool presence = false;
  _Room? room;
  _Client(this.ws);

  void send(Map<String, dynamic> m) {
    try {
      ws.add(jsonEncode(m));
    } catch (_) {}
  }
}

class _Room {
  final String code;
  final String game;
  final _Client host;
  _Client? guest;
  _Room(this.code, this.game, this.host);

  _Client? other(_Client c) => identical(c, host) ? guest : host;
}

class RelayServer {
  RelayServer._(this._http);

  final HttpServer _http;
  final Set<_Client> _clients = {};
  final Map<String, _Room> _rooms = {};
  final Map<String, _Client> _presence = {};
  final Random _rng = Random();

  /// Cổng đang lắng nghe (có thể khác cổng yêu cầu nếu cổng đó đang bận).
  int get port => _http.port;

  static Future<RelayServer> start({int port = 8765}) async {
    HttpServer http;
    try {
      http = await HttpServer.bind(InternetAddress.anyIPv4, port);
    } catch (_) {
      http = await HttpServer.bind(InternetAddress.anyIPv4, 0); // cổng bận → chọn cổng khác
    }
    final s = RelayServer._(http);
    s._serve();
    return s;
  }

  Future<void> stop() async {
    for (final c in List<_Client>.from(_clients)) {
      try {
        await c.ws.close();
      } catch (_) {}
    }
    _clients.clear();
    _rooms.clear();
    _presence.clear();
    try {
      await _http.close(force: true);
    } catch (_) {}
  }

  void _serve() {
    _http.listen((req) async {
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        try {
          final ws = await WebSocketTransformer.upgrade(req);
          ws.pingInterval = const Duration(seconds: 20);
          final c = _Client(ws);
          _clients.add(c);
          ws.listen(
            (data) => _handle(c, data),
            onDone: () => _cleanup(c),
            onError: (_) => _cleanup(c),
          );
        } catch (_) {}
      } else {
        req.response
          ..statusCode = HttpStatus.ok
          ..write('Playtime server OK')
          ..close();
      }
    });
  }

  String _newCode() {
    for (var i = 0; i < 200; i++) {
      final c = (1000 + _rng.nextInt(9000)).toString();
      if (!_rooms.containsKey(c)) return c;
    }
    return (10000 + _rng.nextInt(90000)).toString();
  }

  void _leaveRoom(_Client c) {
    final r = c.room;
    if (r == null) return;
    c.room = null;
    final o = r.other(c);
    if (o != null) {
      o.room = null;
      o.send({'t': 'peer_left'});
    }
    _rooms.remove(r.code);
  }

  void _cleanup(_Client c) {
    _clients.remove(c);
    _leaveRoom(c);
    if (c.presence && _presence[c.id] == c) _presence.remove(c.id);
  }

  void _handle(_Client c, dynamic raw) {
    Map<String, dynamic> m;
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is! Map) return;
      m = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    switch (m['t']) {
      case 'hello':
        c.name = (m['name'] ?? 'Ẩn danh').toString();
        c.emoji = (m['emoji'] ?? '🙂').toString();
        c.id = (m['id'] ?? '').toString();
        break;

      case 'presence':
        c.name = (m['name'] ?? 'Ẩn danh').toString();
        c.emoji = (m['emoji'] ?? '🙂').toString();
        c.id = (m['id'] ?? '').toString();
        c.presence = true;
        if (c.id.isNotEmpty) _presence[c.id] = c;
        break;

      case 'invite':
        final target = _presence[(m['to'] ?? '').toString()];
        if (target == null) {
          c.send({'t': 'invite_result', 'ok': false});
        } else {
          target.send({
            't': 'invited',
            'code': (m['code'] ?? '').toString(),
            'from': {'id': c.id, 'name': c.name, 'emoji': c.emoji},
          });
          c.send({'t': 'invite_result', 'ok': true});
        }
        break;

      case 'create':
        _leaveRoom(c);
        final code = _newCode();
        final room = _Room(code, (m['game'] ?? '').toString(), c);
        _rooms[code] = room;
        c.room = room;
        c.send({'t': 'created', 'code': code});
        break;

      case 'join':
        final room = _rooms[(m['code'] ?? '').toString()];
        if (room == null) {
          c.send({'t': 'error', 'msg': 'Không tìm thấy bàn này.'});
        } else if (room.guest != null) {
          c.send({'t': 'error', 'msg': 'Bàn đã đủ người.'});
        } else if (identical(room.host, c)) {
          c.send({'t': 'error', 'msg': 'Bạn đang là chủ bàn.'});
        } else {
          _leaveRoom(c);
          room.guest = c;
          c.room = room;
          room.host.send({
            't': 'start',
            'role': 0,
            'game': room.game,
            'opp': {'name': c.name, 'emoji': c.emoji, 'id': c.id}
          });
          c.send({
            't': 'start',
            'role': 1,
            'game': room.game,
            'opp': {'name': room.host.name, 'emoji': room.host.emoji, 'id': room.host.id}
          });
        }
        break;

      case 'move':
        c.room?.other(c)?.send({'t': 'move', 'd': m['d']});
        break;

      case 'rematch':
        c.room?.other(c)?.send({'t': 'rematch'});
        break;

      case 'pick':
        c.room?.other(c)?.send({'t': 'pick', 'game': (m['game'] ?? '').toString()});
        break;

      case 'game_left':
        c.room?.other(c)?.send({'t': 'game_left'});
        break;

      case 'rchat':
        final text = (m['text'] ?? '').toString().trim();
        final r = c.room;
        if (text.isEmpty || r == null) return;
        final msg = {
          't': 'rchat',
          'name': c.name,
          'emoji': c.emoji,
          'id': c.id,
          'text': text.length > 300 ? text.substring(0, 300) : text,
          'ts': DateTime.now().millisecondsSinceEpoch,
        };
        r.host.send(msg);
        r.guest?.send(msg);
        break;

      case 'leave':
        _leaveRoom(c);
        break;
    }
  }
}
