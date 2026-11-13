import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import '../theme/ios_theme.dart';
import 'ios_widgets.dart';

/// Tiêu đề nhóm cài đặt (ví dụ: "Dễ nhìn").
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 22, 6, 10),
        child: Text(text,
            style: const TextStyle(
                color: Ios.label2,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                decoration: TextDecoration.none)),
      );
}

/// Nhóm các hàng cài đặt trong một khối kính mờ, có đường kẻ giữa các hàng.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const SettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Container(
            height: 1,
            margin: const EdgeInsets.only(left: 62),
            color: Ios.separator));
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: Ios.box(radius: 24),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

/// Một hàng cài đặt: icon màu, tiêu đề, giá trị / công tắc / mũi tên.
class SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    this.color = Ios.blue,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.chevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.op(0.28), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Ios.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(
                          color: Ios.label2,
                          fontSize: 12,
                          decoration: TextDecoration.none)),
              ],
            ),
          ),
          if (value != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(value!,
                  style: const TextStyle(
                      color: Ios.label2,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.none)),
            ),
          if (trailing != null) Padding(padding: const EdgeInsets.only(left: 8), child: trailing),
          if (chevron)
            const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(CupertinoIcons.chevron_right, size: 18, color: Ios.label2),
            ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Tappable(pressedScale: 0.99, onTap: onTap, child: row);
  }
}

/// Bộ chọn dạng viên thuốc (ví dụ: Thường | Lớn).
class PillSegmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const PillSegmented(
      {super.key, required this.labels, required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: const Color(0x33000000),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(labels.length, (i) {
            final sel = i == index;
            return Tappable(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? Ios.accent : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                        color: sel ? Ios.label : Ios.label2,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none)),
              ),
            );
          }),
        ),
      );
}
