import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'player_service.dart';
import 'settings_service.dart';

/// Ba cách chơi của mỗi game 2 người.
enum PlayMode { computer, local, online }

/// Cấu hình một trận đấu, truyền từ màn chọn chế độ sang màn chơi.
class MatchConfig {
  final PlayMode mode;
  final String difficulty; // EASY | MEDIUM | HARD (khi chơi với máy)
  final OnlineSession? session; // khi chơi online

  const MatchConfig({
    required this.mode,
    this.difficulty = 'EASY',
    this.session,
  });

  bool get isOnline => mode == PlayMode.online;
  bool get isComputer => mode == PlayMode.computer;
  bool get isLocal => mode == PlayMode.local;

  /// 0 = chủ bàn (đi trước), 1 = khách. Chơi offline luôn là 0.
  int get myRole => session?.role ?? 0;
}

class _Waiter {
  final List<String> types;
  final Completer<Map<String, dynamic>> c = Completer();
  _Waiter(this.types);
}

/// Một phiên kết nối tới máy chủ trung chuyển (một "bàn" có 2 người).
class OnlineSession {
  WebSocket? _ws;
  bool _closed = false;

  /// true = bàn được giữ giữa nhiều ván (do TableService quản lý).
  bool persistent = false;

  int role = 0;
  String game = '';
  String code = '';
  String oppName = 'Đối thủ';
  String oppEmoji = '🙂';
  String oppId = '';

  final List<_Waiter> _waiters = [];
  final List<Map<String, dynamic>> _buffer = [];
  void Function(Map<String, dynamic>)? _handler;

  /// Bộ xử lý mặc định (bàn chat) – được khôi phục khi một ván kết thúc.
  void Function(Map<String, dynamic>)? defaultHandler;

  bool get isClosed => _closed;

  /// [url] != null = chơi qua Wi-Fi (kết nối thẳng tới điện thoại chủ bàn).
  /// null = dùng máy chủ ngoài đã cài trong phần Tôi.
  Future<void> connect({String? url}) async {
    final lan = url != null;
    final target = url ?? AppSettings.instance.wsUrl;
    if (target.isEmpty) {
      throw Exception('Chưa thiết lập máy chủ online. Vào Tôi → Kết nối online để nhập địa chỉ.');
    }
    try {
      _ws = await WebSocket.connect(target).timeout(const Duration(seconds: 8));
    } catch (_) {
      throw Exception(lan
          ? 'Không kết nối được tới chủ bàn. Hãy kiểm tra hai máy cùng Wi-Fi và địa chỉ IP đúng.'
          : 'Không kết nối được máy chủ. Hãy kiểm tra địa chỉ máy chủ trong phần Tôi.');
    }
    _ws!.pingInterval = const Duration(seconds: 20);
    _ws!.listen(_onData, onDone: _onDone, onError: (_) => _onDone());
    send({
      't': 'hello',
      'name': PlayerService.instance.name,
      'emoji': PlayerService.instance.emoji,
      'id': PlayerService.instance.id,
    });
  }

  void _onData(dynamic raw) {
    Map<String, dynamic> m;
    try {
      final d = jsonDecode(raw as String);
      if (d is! Map) return;
      m = Map<String, dynamic>.from(d);
    } catch (_) {
      return;
    }
    if (m['t'] == 'start') {
      role = (m['role'] as num?)?.toInt() ?? 0;
      game = (m['game'] ?? '').toString();
      final opp = m['opp'];
      if (opp is Map) {
        oppName = (opp['name'] ?? 'Đối thủ').toString();
        oppEmoji = (opp['emoji'] ?? '🙂').toString();
        oppId = (opp['id'] ?? '').toString();
      }
    }
    _dispatch(m);
  }

  void _onDone() {
    if (_closed) return;
    _dispatch({'t': 'disconnected'});
  }

  void _dispatch(Map<String, dynamic> m) {
    for (final w in List<_Waiter>.from(_waiters)) {
      if (w.types.contains(m['t'])) {
        _waiters.remove(w);
        w.c.complete(m);
        return;
      }
    }
    if (_handler != null) {
      _handler!(m);
    } else {
      _buffer.add(m);
    }
  }

  /// Nhận sự kiện (các sự kiện đến sớm được giữ lại và phát ngay).
  void setHandler(void Function(Map<String, dynamic>) cb) {
    _handler = cb;
    final pending = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    for (final m in pending) {
      cb(m);
    }
  }

  /// Trả quyền nhận sự kiện về bộ xử lý mặc định.
  void clearHandler() {
    _handler = defaultHandler;
    if (_handler != null) {
      final pending = List<Map<String, dynamic>>.from(_buffer);
      _buffer.clear();
      for (final m in pending) {
        _handler!(m);
      }
    }
  }

  void send(Map<String, dynamic> m) {
    if (_closed) return;
    try {
      _ws?.add(jsonEncode(m));
    } catch (_) {}
  }

  Future<Map<String, dynamic>> _waitFor(List<String> types) {
    final w = _Waiter([...types, 'disconnected', 'error']);
    _waiters.add(w);
    return w.c.future;
  }

  String _errText(Map<String, dynamic> m) => m['t'] == 'error'
      ? (m['msg'] ?? 'Có lỗi xảy ra.').toString()
      : 'Mất kết nối với máy chủ.';

  /// Tạo bàn mới (gameId rỗng = bàn trò chuyện), trả về mã bàn 4 số.
  Future<String> createRoom(String gameId) async {
    final f = _waitFor(['created']);
    send({'t': 'create', 'game': gameId});
    final m = await f;
    if (m['t'] != 'created') throw Exception(_errText(m));
    code = (m['code'] ?? '').toString();
    return code;
  }

  /// Chờ người thứ hai vào bàn.
  Future<void> waitForStart() async {
    final m = await _waitFor(['start']);
    if (m['t'] != 'start') throw Exception(_errText(m));
  }

  /// Vào bàn bằng mã.
  Future<void> join(String roomCode) async {
    final f = _waitFor(['start']);
    send({'t': 'join', 'code': roomCode});
    final m = await f;
    if (m['t'] != 'start') throw Exception(_errText(m));
    code = roomCode;
  }

  void close() {
    if (_closed) return;
    send({'t': 'leave'});
    _closed = true;
    _handler = null;
    defaultHandler = null;
    for (final w in _waiters) {
      if (!w.c.isCompleted) w.c.complete({'t': 'disconnected'});
    }
    _waiters.clear();
    try {
      _ws?.close();
    } catch (_) {}
  }
}
