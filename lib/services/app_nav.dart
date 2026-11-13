import 'package:flutter/cupertino.dart';

/// Khóa điều hướng gốc (để mở game / hộp thoại từ dịch vụ nền).
final GlobalKey<NavigatorState> rootNavKey = GlobalKey<NavigatorState>();

/// Tab đang chọn ở màn hình chính: 0 Chơi, 1 Nhắn, 2 Tôi.
final ValueNotifier<int> homeTabNotifier = ValueNotifier<int>(0);
