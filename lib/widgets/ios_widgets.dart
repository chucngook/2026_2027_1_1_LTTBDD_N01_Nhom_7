import 'dart:math';
import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import '../constants/app_assets.dart';
import '../theme/ios_theme.dart';
import 'app_images.dart';
import 'dot_background.dart';

/// Hiệu ứng nhấn kiểu iOS: thu nhỏ + mờ nhẹ khi chạm.
class Tappable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;

  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedOpacity(
          opacity: _down ? 0.75 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Nút bo tròn full-width chuẩn iOS.
class IosButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final IconData? icon;

  const IosButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = Ios.accent,
    this.textColor = CupertinoColors.white,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = onPressed == null ? Ios.label2 : textColor;
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 15),
        color: color,
        disabledColor: Ios.card2,
        borderRadius: BorderRadius.circular(20),
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: TextStyle(
                    color: fg, fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// Khung màn hình game: thanh điều hướng mờ (frosted) + nút Back iOS.
class GameScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onBack;

  const GameScaffold({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Ios.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0x33000000),
        border: const Border(bottom: BorderSide(color: Ios.border, width: 0.5)),
        middle: Text(title,
            style: const TextStyle(
                color: Ios.label, fontWeight: FontWeight.w800, fontSize: 19)),
        leading: CupertinoNavigationBarBackButton(
          color: Ios.accent,
          previousPageTitle: 'Quay lại',
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        trailing: trailing,
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: DotBackground()),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

/// Ô thống kê nhỏ (Điểm, Thời gian...).
class StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatBox({
    super.key,
    required this.label,
    required this.value,
    this.color = Ios.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: Ios.box(radius: 18, borderWidth: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Ios.label2,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Tiêu đề nhóm viết hoa nhỏ màu xám (giống Settings của iOS).
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              color: Ios.label2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4)),
    );
  }
}

/// Alert 1 nút OK.
Future<void> showIosAlert(BuildContext context, String title, String message) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Hộp thoại kết quả ván chơi (xu nảy, số Token chạy lên, pháo giấy).
/// Trả về true nếu người chơi chọn "chơi lại".
Future<bool> showRoundResult(
  BuildContext context, {
  required String title,
  required String message,
  String? replayLabel,
  String closeLabel = 'Tiếp tục',
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ResultDialog(
      title: title,
      message: message,
      replayLabel: replayLabel,
      closeLabel: closeLabel,
    ),
  );
  return result ?? false;
}

class _Particle {
  final double x, delay, speed, size, rot, spin;
  final Color color;
  _Particle(this.x, this.delay, this.speed, this.size, this.rot, this.spin,
      this.color);
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> ps;
  final double t;
  _ConfettiPainter(this.ps, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in ps) {
      final k = t - p.delay;
      if (k <= 0) continue;
      final y = -20 + k * p.speed * (size.height + 60) / 0.85;
      if (y > size.height + 20) continue;
      final x = p.x * size.width + sin(t * 7 + p.rot) * 16;
      final alpha = t > 0.85 ? ((1 - t) / 0.15).clamp(0.0, 1.0) : 1.0;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot + t * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(1.5)),
        Paint()..color = p.color.op(alpha),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}

class _ResultDialog extends StatefulWidget {
  final String title;
  final String message;
  final String? replayLabel;
  final String closeLabel;

  const _ResultDialog({
    required this.title,
    required this.message,
    required this.replayLabel,
    required this.closeLabel,
  });

  @override
  State<_ResultDialog> createState() => _ResultDialogState();
}

class _ResultDialogState extends State<_ResultDialog>
    with SingleTickerProviderStateMixin {
  static final RegExp _rewardRe = RegExp(r'\+(\d+) điểm');

  late final AnimationController _c;
  late final Animation<double> _pop;
  late final int _reward;
  late final List<String> _lines;
  final List<_Particle> _ps = [];

  @override
  void initState() {
    super.initState();
    final m = _rewardRe.firstMatch(widget.message);
    _reward = m != null ? int.parse(m.group(1)!) : 0;
    _lines = widget.message
        .split('\n')
        .where((l) => l.trim().isNotEmpty && !_rewardRe.hasMatch(l))
        .toList();

    if (_reward > 0) {
      final r = Random();
      const palette = [
        Ios.accent, Ios.orange, Ios.green, Ios.blue, Ios.yellow, Ios.red, Ios.teal
      ];
      for (var i = 0; i < 44; i++) {
        _ps.add(_Particle(
          r.nextDouble(),
          r.nextDouble() * 0.35,
          0.55 + r.nextDouble() * 0.7,
          6 + r.nextDouble() * 8,
          r.nextDouble() * 6.28,
          (r.nextDouble() - 0.5) * 12,
          palette[r.nextInt(palette.length)],
        ));
      }
    }

    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..forward();
    _pop = CurvedAnimation(
        parent: _c, curve: const Interval(0, 0.35, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasReplay = widget.replayLabel != null;
    return DefaultTextStyle(
      style: const TextStyle(
          color: Ios.label, decoration: TextDecoration.none, fontSize: 15),
      child: Stack(
        children: [
          if (_reward > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                      painter: _ConfettiPainter(_ps, _c.value)),
                ),
              ),
            ),
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.9, end: 1),
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeOutBack,
              builder: (context, v, child) => Opacity(
                  opacity: ((v - 0.9) * 10).clamp(0.0, 1.0).toDouble(),
                  child: Transform.scale(scale: v, child: child)),
              child: Container(
                width: 312,
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
                decoration: BoxDecoration(
                  color: const Color(0xF20C2347),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Ios.border, width: 2),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x80000000),
                        blurRadius: 40,
                        offset: Offset(0, 16)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _pop,
                      child: _reward > 0
                          ? Image.asset(AppImages.star, width: 76, height: 76)
                          : const Opacity(opacity: 0.9, child: AppLogo(size: 64)),
                    ),
                    const SizedBox(height: 14),
                    Text(widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Ios.label,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.none)),
                    if (_reward > 0)
                      AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) {
                          final k = Curves.easeOut
                              .transform((_c.value / 0.7).clamp(0.0, 1.0));
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text('+${(_reward * k).round()}',
                                style: const TextStyle(
                                    color: Ios.amber,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    decoration: TextDecoration.none)),
                          );
                        },
                      ),
                    if (_reward > 0)
                      const Text('điểm',
                          style: TextStyle(
                              color: Ios.label2,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none)),
                    const SizedBox(height: 10),
                    for (final l in _lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(l,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Ios.label2,
                                fontSize: 14,
                                height: 1.3,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.none)),
                      ),
                    const SizedBox(height: 14),
                    IosButton(
                      label: hasReplay ? widget.replayLabel! : widget.closeLabel,
                      onPressed: () => Navigator.pop(context, hasReplay),
                    ),
                    if (hasReplay)
                      CupertinoButton(
                        padding: const EdgeInsets.only(top: 12),
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(widget.closeLabel,
                            style: const TextStyle(
                                color: Ios.label2,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "mm:ss"
String formatSeconds(int s) =>
    '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

/// Nhãn cho CupertinoSlidingSegmentedControl: chữ trắng khi được chọn, chữ đen khi chưa chọn.
Widget segmentLabel(String text, bool selected) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Text(text,
          style: TextStyle(
              color: selected ? CupertinoColors.white : Ios.label,
              fontWeight: FontWeight.w600)),
    );
