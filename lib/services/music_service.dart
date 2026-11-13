import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'settings_service.dart';

/// Nhạc nền: luôn phát nhạc menu, vào game thì đổi sang nhạc game.
class MusicService with WidgetsBindingObserver {
  MusicService._();
  static final MusicService instance = MusicService._();

  final AudioPlayer _player = AudioPlayer();
  bool _inGame = false;
  bool _started = false;
  String? _current;
  bool _paused = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _player.setReleaseMode(ReleaseMode.loop);
    WidgetsBinding.instance.addObserver(this);
    AppSettings.instance.addListener(_apply);
    await _apply();
  }

  void setInGame(bool v) {
    if (_inGame == v) return;
    _inGame = v;
    _apply();
  }

  double get _vol => (AppSettings.instance.volume * 0.45).clamp(0.0, 1.0).toDouble();

  Future<void> _apply() async {
    try {
      final cfg = AppSettings.instance;
      if (!cfg.music || cfg.volume <= 0) {
        await _player.stop();
        _current = null;
        return;
      }
      final want = _inGame ? 'game' : 'menu';
      if (_current == want) {
        await _player.setVolume(_vol);
        return;
      }
      await _player.stop();
      _current = want;
      if (!_paused) await _player.play(AssetSource('music/$want.wav'), volume: _vol);
    } catch (_) {
      // Không để lỗi âm thanh làm hỏng app
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
        _paused = true;
        _player.pause();
      } else if (state == AppLifecycleState.resumed) {
        _paused = false;
        if (_current != null && AppSettings.instance.music) {
          _player.resume();
        } else {
          _apply();
        }
      }
    } catch (_) {}
  }
}

/// Theo dõi điều hướng: route tên 'game' → nhạc game, ngược lại → nhạc menu.
class MusicObserver extends NavigatorObserver {
  bool _isGame(Route<dynamic>? r) => r?.settings.name == 'game';

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isGame(route)) MusicService.instance.setInGame(true);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    MusicService.instance.setInGame(_isGame(newRoute));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isGame(route) && !_isGame(previousRoute)) {
      MusicService.instance.setInGame(false);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isGame(route) && !_isGame(previousRoute)) {
      MusicService.instance.setInGame(false);
    }
  }
}
