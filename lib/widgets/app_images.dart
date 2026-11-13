import 'package:flutter/cupertino.dart';
import '../constants/app_assets.dart';
import '../theme/ios_theme.dart';

/// Ảnh bo góc kiểu icon iOS (squircle). Có fallback nếu thiếu file ảnh.
class SquircleImage extends StatelessWidget {
  final String path;
  final double size;
  final bool dim; // làm xám (game đang khóa)
  final bool shadow;

  const SquircleImage({
    super.key,
    required this.path,
    required this.size,
    this.dim = false,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.225);
    Widget img = Image.asset(
      path,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: Ios.card3,
        alignment: Alignment.center,
        child: Icon(CupertinoIcons.photo, color: Ios.label2, size: size * 0.4),
      ),
    );
    if (dim) {
      img = ColorFiltered(
        colorFilter: const ColorFilter.mode(Color(0xFF808080), BlendMode.saturation),
        child: img,
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadow
            ? [
                BoxShadow(
                    color: const Color(0x2E000000),
                    blurRadius: size * 0.16,
                    offset: Offset(0, size * 0.06)),
              ]
            : null,
      ),
      child: ClipRRect(borderRadius: radius, child: img),
    );
  }
}

/// Icon (ảnh) của một game theo id.
class GameIcon extends StatelessWidget {
  final String gameId;
  final double size;
  final bool dim;
  final bool shadow;

  const GameIcon(
      {super.key,
      required this.gameId,
      required this.size,
      this.dim = false,
      this.shadow = true});

  @override
  Widget build(BuildContext context) => SquircleImage(
      path: AppAssets.gameImage(gameId), size: size, dim: dim, shadow: shadow);
}

/// Logo ứng dụng.
class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) =>
      SquircleImage(path: AppImages.logo, size: size);
}

/// Đồng xu Token (ảnh).
class TokenCoin extends StatelessWidget {
  final double size;
  const TokenCoin({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) => Image.asset(
        AppImages.coin,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) =>
            Icon(CupertinoIcons.money_dollar_circle_fill,
                color: Ios.yellow, size: size),
      );
}
