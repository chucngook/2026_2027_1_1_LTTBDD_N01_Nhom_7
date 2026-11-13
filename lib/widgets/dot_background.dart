import 'package:flutter/cupertino.dart';
import '../services/settings_service.dart';
import '../theme/ios_theme.dart';

/// Nền gradient theo chủ đề đang chọn, có bong bóng và sóng nước mờ.
class DotBackground extends StatelessWidget {
  final Widget? child;
  const DotBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) {
        final i = AppSettings.instance.themeIndex;
        final t = AppThemes.all[(i >= 0 && i < AppThemes.all.length) ? i : 0];
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [t.top, t.bottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: CustomPaint(
            painter: _WavePainter(),
            child: child ?? const SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class _WavePainter extends CustomPainter {
  static const List<List<double>> _bubbles = [
    [0.12, 0.10, 26], [0.82, 0.07, 14], [0.92, 0.22, 34], [0.05, 0.34, 12],
    [0.70, 0.40, 20], [0.20, 0.55, 30], [0.90, 0.62, 16], [0.45, 0.72, 12],
    [0.08, 0.80, 22], [0.78, 0.88, 28], [0.55, 0.20, 10], [0.35, 0.92, 18],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0x1AFFFFFF);
    final fill = Paint()..color = const Color(0x0DFFFFFF);
    for (final b in _bubbles) {
      final c = Offset(size.width * b[0], size.height * b[1]);
      canvas.drawCircle(c, b[2], fill);
      canvas.drawCircle(c, b[2], ring);
    }
    // sóng nước ở đáy
    for (var k = 0; k < 3; k++) {
      final path = Path()..moveTo(0, size.height);
      final base = size.height - 70 - k * 26.0;
      for (double x = 0; x <= size.width + 8; x += 8) {
        path.lineTo(x, base + _sin(x / 70 + k) * (10 - k * 2));
      }
      path.lineTo(size.width, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = Color.fromARGB(14 + k * 4, 255, 255, 255));
    }
  }

  double _sin(double v) {
    // sin xấp xỉ (tránh import dart:math chỉ để vẽ sóng)
    var x = v % (2 * 3.14159265);
    if (x > 3.14159265) x -= 2 * 3.14159265;
    final x3 = x * x * x;
    return x - x3 / 6 + x3 * x * x / 120 - x3 * x3 * x / 5040;
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
