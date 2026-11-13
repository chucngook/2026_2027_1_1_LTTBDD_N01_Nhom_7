import 'package:flutter/cupertino.dart';
import '../services/online_service.dart';
import 'ios_widgets.dart';

/// Gắn vào State của game 2 người để đồng bộ nước đi giữa 2 máy.
/// Game chỉ cần cung cấp [config], [onNetMove], [onRematch].
mixin OnlineGameMixin<T extends StatefulWidget> on State<T> {
  MatchConfig get config;

  /// Nhận một nước đi từ đối thủ.
  void onNetMove(Map<String, dynamic> data);

  /// Cả hai đã đồng ý chơi lại: reset ván.
  void onRematch();

  bool _myRematch = false;
  bool _theirRematch = false;
  bool _leftAlerted = false;

  void netInit() {
    final s = config.session;
    if (s == null) return;
    s.setHandler(_handle);
  }

  void _handle(Map<String, dynamic> m) {
    switch (m['t']) {
      case 'move':
        final d = m['d'];
        if (d is Map && mounted) onNetMove(Map<String, dynamic>.from(d));
        break;
      case 'rematch':
        _theirRematch = true;
        _checkRematch();
        break;
      case 'peer_left':
      case 'disconnected':
        config.session?.defaultHandler?.call(m); // bàn cũng cần biết để đóng lại
        _peerLeft();
        break;
      case 'game_left':
        _opponentLeftGame();
        break;
      default:
        config.session?.defaultHandler?.call(m); // tin nhắn bàn, lời chọn game...
    }
  }

  Future<void> _opponentLeftGame() async {
    if (_leftAlerted || !mounted) return;
    _leftAlerted = true;
    await showIosAlert(context, 'Đối thủ đã rời ván', 'Bạn sẽ quay lại bàn.');
    if (mounted) Navigator.of(context).maybePop();
  }

  /// Gửi nước đi cho đối thủ.
  void sendMove(Map<String, dynamic> d) =>
      config.session?.send({'t': 'move', 'd': d});

  /// Xin chơi lại; ván mới bắt đầu khi cả hai cùng đồng ý.
  void requestRematch() {
    _myRematch = true;
    config.session?.send({'t': 'rematch'});
    _checkRematch();
  }

  void _checkRematch() {
    if (_myRematch && _theirRematch && mounted) {
      _myRematch = false;
      _theirRematch = false;
      onRematch();
    }
  }

  Future<void> _peerLeft() async {
    if (_leftAlerted || !mounted) return;
    _leftAlerted = true;
    await showIosAlert(
        context, 'Đối thủ đã rời bàn', 'Ván đấu kết thúc. Bạn sẽ quay về trang chủ.');
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void netDispose() {
    final s = config.session;
    if (s == null) return;
    s.clearHandler();
    if (s.persistent) {
      s.send({'t': 'game_left'}); // bàn vẫn giữ để tiếp tục nhắn tin
    } else {
      s.close();
    }
  }
}
