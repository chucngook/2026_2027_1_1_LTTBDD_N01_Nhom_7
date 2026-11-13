import 'package:flutter/foundation.dart';
import 'lang_en.dart';

/// Hỗ trợ 2 ngôn ngữ: Tiếng Việt (gốc) và English.
/// Mọi chữ hiển thị đi qua widget `Text` riêng (widgets/tr_text.dart) và được dịch ở đây.
class Lang {
  Lang._();

  static final ValueNotifier<String> notifier = ValueNotifier<String>('vi');
  static bool get en => notifier.value == 'en';

  static final Map<String, String> _cache = {};
  static List<MapEntry<String, String>>? _fragments;

  static bool _hasNonAscii(String s) {
    for (final c in s.codeUnits) {
      if (c > 127) return true;
    }
    return false;
  }

  /// Dịch một chuỗi tiếng Việt sang tiếng Anh (nếu đang chọn English).
  static String t(String s) {
    if (!en || s.isEmpty) return s;
    final exact = kEn[s];
    if (exact != null) return exact;
    if (!_hasNonAscii(s)) return s;

    final cached = _cache[s];
    if (cached != null) return cached;

    _fragments ??= (kEn.entries.where((e) => _hasNonAscii(e.key)).toList()
      ..sort((a, b) => b.key.length.compareTo(a.key.length)));

    var out = s;
    for (final e in _fragments!) {
      if (out.contains(e.key)) out = out.replaceAll(e.key, e.value);
    }
    if (_cache.length > 3000) _cache.clear();
    _cache[s] = out;
    return out;
  }
}

/// Dịch một chuỗi không đi qua widget Text (placeholder, tiêu đề...).
String tr(String vi) => Lang.t(vi);
