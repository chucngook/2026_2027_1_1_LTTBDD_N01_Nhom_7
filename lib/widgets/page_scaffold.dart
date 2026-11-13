import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import '../services/lang.dart';
import '../theme/ios_theme.dart';
import 'dot_background.dart';

/// Khung cho các màn phụ: nền kính mờ + thanh tiêu đề trong suốt có nút quay lại.
class PageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;
  const PageScaffold({super.key, required this.title, required this.child, this.trailing});

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
          color: Ios.label,
          previousPageTitle: tr('Quay lại'),
          onPressed: () => Navigator.of(context).maybePop(),
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
