import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'fx.dart';
import 'friend_service.dart';
import 'lan_info.dart';
import 'online_service.dart';
import 'player_service.dart';
import 'relay_server.dart';
import 'settings_service.dart';

class TableMessage {
  final String name, emoji, id, text;
  final int ts;
  final bool system;
  TableMessage(this.name, this.emoji, this.id, this.text, this.ts, {this.system = false});
}

/// "Bàn" online: 2 người vào cùng một bàn, nhắn tin với nhau và chọn game để chơi.
class TableService extends ChangeNotifier {
  TableService._();
  static final TableService instance = TableService._();

  OnlineSession? session;
  String code = '';
  bool seated = false; // đã đủ 2 người
  bool busy = false;
  bool inGame = false;
  String? error;
  String? notice; // thông báo một lần (ví dụ: "Đối thủ đã rời bàn")
  final List<TableMessage> messages = [];

  // ── Chơi qua Wi-Fi: điện thoại chủ bàn tự chạy máy chủ trong app ──
  RelayServer? _server;
  bool lanMode = false; // true = chơi qua Wi-Fi (không dùng máy chủ ngoài)
  String hostIp = '';
  int hostPort = 0;

  /// Nội dung mã QR của bàn (chỉ có khi mình là chủ bàn chơi qua Wi-Fi).
  String? get joinPayload => (lanMode && _server != null)
      ? jsonEncode({'app': 'playtime', 't': 'table', 'host': '$hostIp:$hostPort', 'code': code})
      : null;

  /// Được gán ở main(): mở màn hình game theo id.
  void Function(String gameId)? startGame;

  bool get isOpen => session != null;
  String get oppName => session?.oppName ?? '';
  String get oppEmoji => session?.oppEmoji ?? '🙂';
  String get oppId => session?.oppId ?? '';

  void _sys(String text) =>
      messages.add(TableMessage('', '', '', text, DateTime.now().millisecondsSinceEpoch, system: true));

  String _msg(Object e) => e.toString().replaceFirst('Exception: ', '');

  /// Mở một bàn mới và chờ bạn bè vào.
  /// Chưa cài máy chủ ngoài → chơi qua Wi-Fi: máy này tự làm chủ bàn.
  Future<void> open() async {
    if (session != null || busy) return;
    busy = true;
    error = null;
    notifyListeners();
    final s = OnlineSession()..persistent = true;
    RelayServer? srv;
    final useLan = AppSettings.instance.wsUrl.isEmpty;
    try {
      String? url;
      if (useLan) {
        final ip = await LanInfo.localIp();
        if (ip == null) {
          throw Exception('Không tìm thấy địa chỉ Wi-Fi của máy. Hãy bật Wi-Fi rồi thử lại.');
        }
        srv = await RelayServer.start();
        hostIp = ip;
        hostPort = srv.port;
        url = 'ws://127.0.0.1:${srv.port}';
      }
      await s.connect(url: url);
      code = await s.createRoom('');
      _server = srv;
      lanMode = useLan;
      session = s;
      s.setHandler(_onEvent);
      s.defaultHandler = _onEvent;
      messages.clear();
      _sys('Đã mở bàn $code. Gửi mã này cho bạn bè để họ vào bàn.');
      busy = false;
      notifyListeners();
      _awaitGuest(s);
    } catch (e) {
      s.close();
      await srv?.stop();
      error = _msg(e);
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _awaitGuest(OnlineSession s) async {
    try {
      await s.waitForStart();
      if (session != s) return;
      seated = true;
      _sys('${s.oppEmoji} ${s.oppName} đã vào bàn.');
      notifyListeners();
    } catch (_) {
      if (session == s) _closed('Bàn đã đóng.');
    }
  }

  static String _lanUrl(String h) {
    var x = h.trim().replaceAll(RegExp(r'^(ws|wss|http|https)://'), '');
    x = x.split('/').first;
    if (!x.contains(':')) x = '$x:8765';
    return 'ws://$x';
  }

  /// Vào bàn của người khác bằng mã. [host] = địa chỉ IP của chủ bàn (chơi qua Wi-Fi).
  Future<bool> join(String roomCode, {String? host}) async {
    if (busy) return false;
    if (session != null) leave();
    busy = true;
    error = null;
    notifyListeners();
    final s = OnlineSession()..persistent = true;
    final lan = host != null && host.trim().isNotEmpty;
    try {
      await s.connect(url: lan ? _lanUrl(host) : null);
      await s.join(roomCode);
      if (lan) AppSettings.instance.setLastHost(host);
      session = s;
      code = roomCode;
      seated = true;
      lanMode = lan;
      s.setHandler(_onEvent);
      s.defaultHandler = _onEvent;
      messages.clear();
      _sys('Bạn đã vào bàn $roomCode cùng ${s.oppEmoji} ${s.oppName}.');
      busy = false;
      notifyListeners();
      return true;
    } catch (e) {
      s.close();
      error = _msg(e);
      busy = false;
      notifyListeners();
      return false;
    }
  }

  void leave() {
    session?.close();
    _reset();
    notifyListeners();
  }

  void _reset() {
    _server?.stop();
    _server = null;
    lanMode = false;
    hostIp = '';
    hostPort = 0;
    session = null;
    code = '';
    seated = false;
    inGame = false;
    messages.clear();
  }

  void _closed(String text) {
    session?.close();
    _reset();
    notice = text;
    notifyListeners();
  }

  void sendChat(String text) {
    final t = text.trim();
    if (t.isEmpty || session == null) return;
    session!.send({'t': 'rchat', 'text': t});
  }

  /// Chọn một game để cả hai cùng chơi.
  void pickGame(String gameId) {
    if (!seated || inGame || session == null) return;
    session!.send({'t': 'pick', 'game': gameId});
    _launch(gameId);
  }

  void _launch(String gameId) {
    inGame = true;
    notifyListeners();
    startGame?.call(gameId);
  }

  /// Gọi khi màn hình game đóng lại.
  void gameClosed() {
    inGame = false;
    notifyListeners();
  }

  void _onEvent(Map<String, dynamic> m) {
    switch (m['t']) {
      case 'rchat':
        final msg = TableMessage(
          (m['name'] ?? '').toString(),
          (m['emoji'] ?? '🙂').toString(),
          (m['id'] ?? '').toString(),
          (m['text'] ?? '').toString(),
          (m['ts'] as num?)?.toInt() ?? 0,
        );
        messages.add(msg);
        if (msg.id != PlayerService.instance.id && AppSettings.instance.chatSound) {
          Fx.play(Sound.tap);
        }
        notifyListeners();
        break;
      case 'pick':
        if (!inGame) _launch((m['game'] ?? '').toString());
        break;
      case 'peer_left':
      case 'disconnected':
        _closed(m['t'] == 'peer_left' ? 'Đối thủ đã rời bàn.' : 'Mất kết nối với máy chủ.');
        break;
    }
  }

  String? takeNotice() {
    final n = notice;
    notice = null;
    return n;
  }
}

/// Kết nối "có mặt" luôn mở để nhận lời mời vào bàn từ bạn bè.
class PresenceService extends ChangeNotifier {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  WebSocket? _ws;
  Timer? _retry;
  String _url = '';
  bool online = false;
  Completer<bool>? _inviteWait;

  /// Được gán ở main(): hiển thị hộp thoại lời mời.
  void Function(Map<String, dynamic> from, String code)? onInvited;

  void init() {
    AppSettings.instance.addListener(() {
      if (AppSettings.instance.wsUrl != _url) start();
    });
    start();
  }

  Future<void> start() async {
    _retry?.cancel();
    try {
      _ws?.close();
    } catch (_) {}
    online = false;
    _url = AppSettings.instance.wsUrl;
    if (_url.isEmpty) {
      notifyListeners();
      return;
    }
    try {
      final ws = await WebSocket.connect(_url).timeout(const Duration(seconds: 6));
      ws.pingInterval = const Duration(seconds: 20);
      _ws = ws;
      online = true;
      ws.add(jsonEncode({
        't': 'presence',
        'name': PlayerService.instance.name,
        'emoji': PlayerService.instance.emoji,
        'id': PlayerService.instance.id,
      }));
      ws.listen(_onData, onDone: _lost, onError: (_) => _lost());
    } catch (_) {
      _lost();
    }
    notifyListeners();
  }

  void _lost() {
    online = false;
    notifyListeners();
    _retry?.cancel();
    if (AppSettings.instance.wsUrl.isNotEmpty) {
      _retry = Timer(const Duration(seconds: 12), start);
    }
  }

  void _onData(dynamic raw) {
    try {
      final m = jsonDecode(raw as String);
      if (m is! Map) return;
      if (m['t'] == 'invited') {
        final from = Map<String, dynamic>.from(m['from'] as Map);
        if (AppSettings.instance.friendsOnlyInvites &&
            !FriendService.instance.isFriend((from['id'] ?? '').toString())) {
          return;
        }
        onInvited?.call(from, (m['code'] ?? '').toString());
      } else if (m['t'] == 'invite_result') {
        _inviteWait?.complete(m['ok'] == true);
        _inviteWait = null;
      }
    } catch (_) {}
  }

  /// Mời một người bạn (đang online) vào bàn. Trả về true nếu lời mời đã được gửi tới họ.
  Future<bool> invite(String friendId, String code) async {
    if (!online || _ws == null) return false;
    _inviteWait = Completer<bool>();
    _ws!.add(jsonEncode({'t': 'invite', 'to': friendId, 'code': code}));
    return _inviteWait!.future.timeout(const Duration(seconds: 5), onTimeout: () => false);
  }
}
