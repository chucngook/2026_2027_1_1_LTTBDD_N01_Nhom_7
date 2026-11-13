import 'package:flutter/cupertino.dart';

/// Một bộ nền người chơi có thể chọn (tab Tôi → Dễ nhìn → Giao diện).
class AppThemeData {
  final String id;
  final String name;
  final Color top;
  final Color bottom;
  const AppThemeData(this.id, this.name, this.top, this.bottom);
}

class AppThemes {
  AppThemes._();
  static const List<AppThemeData> all = [
    AppThemeData('ocean', 'Đại dương', Color(0xFF0A2F6B), Color(0xFF1478C8)),
    AppThemeData('sunset', 'Hoàng hôn', Color(0xFF3A1C71), Color(0xFFD76D77)),
    AppThemeData('forest', 'Rừng xanh', Color(0xFF0B3D2E), Color(0xFF2E9E6A)),
    AppThemeData('candy', 'Kẹo ngọt', Color(0xFF4A1F7A), Color(0xFFE056A0)),
    AppThemeData('sand', 'Cát vàng', Color(0xFF5C3B14), Color(0xFFC98A3A)),
    AppThemeData('night', 'Màn đêm', Color(0xFF0B0F1A), Color(0xFF2A3350)),
  ];
}

/// Bảng màu "kính mờ": các khối là lớp trắng trong suốt nên hợp với mọi nền.
/// (Giữ tên lớp `Ios` để các màn hình cũ vẫn dùng được.)
class Ios {
  Ios._();

  // Nền mặc định (xanh nước biển); nền thật được vẽ bởi DotBackground theo chủ đề đang chọn.
  static const Color bg = Color(0xFF0A2F6B);

  // Khối kính mờ
  static const Color card = Color(0x1FFFFFFF);
  static const Color card2 = Color(0x2EFFFFFF);
  static const Color card3 = Color(0x47FFFFFF);
  static const Color separator = Color(0x26FFFFFF);
  static const Color border = Color(0x33FFFFFF);
  static const Color dot = Color(0x14FFFFFF);

  // Chữ
  static const Color label = Color(0xFFFFFFFF);
  static const Color label2 = Color(0xB8FFFFFF);

  // Màu nhấn
  static const Color blue = Color(0xFF5AB8FF);
  static const Color green = Color(0xFF4ADE80);
  static const Color orange = Color(0xFFFFA94D);
  static const Color red = Color(0xFFFF6B6B);
  static const Color purple = Color(0xFFB794F6);
  static const Color yellow = Color(0xFFFFD43B);
  static const Color teal = Color(0xFF2DD4BF);
  static const Color amber = Color(0xFFFFD43B);

  /// Màu nhấn chính của app (xanh ngọc)
  static const Color accent = Color(0xFF0FA3A3);

  /// Thiết kế phẳng, không đổ bóng.
  static const List<BoxShadow> shadow = [];

  /// Khối kính mờ bo tròn.
  static BoxDecoration box({
    Color? fill,
    Color? borderColor,
    double radius = 22,
    double borderWidth = 1.5,
    Gradient? gradient,
  }) =>
      BoxDecoration(
        color: gradient == null ? (fill ?? card) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? border, width: borderWidth),
      );
}

extension ColorOpacityX on Color {
  /// Thay cho withOpacity (đã bị đánh dấu deprecated ở Flutter mới).
  Color op(double opacity) => withAlpha((opacity * 255).round());
}
