import 'dart:async';
import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import '../theme/ios_theme.dart';
import '../widgets/app_images.dart';
import '../widgets/dot_background.dart';
import 'home_screen.dart';

/// Màn hình khởi động: logo xuất hiện mượt rồi chuyển sang trang chủ.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100))
      ..forward();
    _scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
    _fade = CurvedAnimation(
        parent: _c, curve: const Interval(0.2, 1, curve: Curves.easeOut));
    _timer = Timer(const Duration(milliseconds: 1900), _goHome);
  }

  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => const HomeScreen(),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Ios.bg,
      child: Stack(
        children: [
          const Positioned.fill(child: DotBackground()),
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [Ios.teal.op(0.22), Ios.teal.op(0)]),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -90,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                    colors: [Ios.blue.op(0.16), Ios.blue.op(0)]),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                    scale: _scale, child: const AppLogo(size: 132)),
                const SizedBox(height: 26),
                FadeTransition(
                  opacity: _fade,
                  child: const Column(
                    children: [
                      Text('Playtime',
                          style: TextStyle(
                              color: Ios.label,
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.none)),
                      SizedBox(height: 6),
                      Text('Chơi cùng bạn bè, mọi lúc mọi nơi',
                          style: TextStyle(
                              color: Ios.label2,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(child: CupertinoActivityIndicator(radius: 11)),
          ),
        ],
      ),
    );
  }
}
