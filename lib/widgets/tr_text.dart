import 'package:flutter/cupertino.dart' hide Text;
import 'package:flutter/cupertino.dart' as w show Text;
import '../services/lang.dart';

/// Thay thế cho `Text` của Flutter: tự dịch chuỗi tiếng Việt sang English
/// khi người dùng chọn ngôn ngữ English (và cập nhật ngay khi đổi ngôn ngữ).
class Text extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Lang.notifier,
      builder: (context, _, __) => w.Text(
        Lang.t(data),
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      ),
    );
  }
}
