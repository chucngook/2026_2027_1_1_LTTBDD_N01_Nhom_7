import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'settings_service.dart';

/// Danh sách hiệu ứng âm thanh (file nằm ở assets/sounds/<tên>.wav).
enum Sound {
  tap,
  flip,
  correct,
  wrong,
  win,
  lose,
  coin,
  spin,
  flap,
  eat,
  bomb,
  deal,
}

/// Phản hồi rung + âm thanh, tự tôn trọng phần Cài đặt.
class Fx {
  Fx._();

  // ── Rung ──
  static void select() {
    if (AppSettings.instance.haptics) HapticFeedback.selectionClick();
  }

  static void light() {
    if (AppSettings.instance.haptics) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (AppSettings.instance.haptics) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (AppSettings.instance.haptics) HapticFeedback.heavyImpact();
  }

  // ── Âm thanh (nhóm nhiều player để phát chồng nhau mượt) ──
  static final List<AudioPlayer> _pool = List.generate(
    5,
    (_) => AudioPlayer()..setPlayerMode(PlayerMode.lowLatency),
  );
  static int _next = 0;

  static Future<void> play(Sound s) async {
    final cfg = AppSettings.instance;
    if (!cfg.sound || cfg.volume <= 0) return;
    try {
      final player = _pool[_next++ % _pool.length];
      await player.stop();
      await player.play(AssetSource('sounds/${s.name}.wav'),
          volume: cfg.volume);
    } catch (_) {
      // Không để lỗi âm thanh làm hỏng game
    }
  }
}
