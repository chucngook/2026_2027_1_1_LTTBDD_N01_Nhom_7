import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import '../theme/ios_theme.dart';
import 'app_images.dart';
import 'ios_widgets.dart';

/// Icon dạng ảnh (PNG trắng) tô màu khi hiển thị.
class RcIcon extends StatelessWidget {
  final String name; // ví dụ: ic_key
  final double size;
  final Color color;
  const RcIcon(this.name, {super.key, this.size = 22, this.color = Ios.label});

  @override
  Widget build(BuildContext context) => Image.asset(
        'assets/images/ui/$name.png',
        width: size,
        height: size,
        color: color,
        errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
      );
}

/// Avatar tròn chứa emoji đại diện.
class AvatarBox extends StatelessWidget {
  final String emoji;
  final double size;
  final bool inset;
  const AvatarBox({super.key, required this.emoji, this.size = 56, this.inset = false});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Ios.card2,
          border: Border.all(
              color: inset ? Ios.accent : Ios.border, width: inset ? 3 : 1.5),
        ),
        child: Text(emoji,
            style: TextStyle(fontSize: size * 0.52, decoration: TextDecoration.none)),
      );
}

/// Nút viên thuốc kính mờ (Vào bàn, Sửa, Sắp xếp...).
class PillButton extends StatelessWidget {
  final String? icon;
  final String label;
  final VoidCallback? onTap;
  final Color fill;
  final Color borderColor;
  final Color textColor;
  final double height;
  final double fontSize;
  final double radius;

  const PillButton({
    super.key,
    this.icon,
    required this.label,
    required this.onTap,
    this.fill = Ios.card2,
    this.borderColor = Ios.border,
    this.textColor = Ios.label,
    this.height = 46,
    this.fontSize = 16,
    this.radius = -1,
  });

  @override
  Widget build(BuildContext context) => Tappable(
        onTap: onTap,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: Ios.box(
              fill: fill,
              borderColor: borderColor,
              radius: radius < 0 ? height / 2 : radius,
              borderWidth: 1.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                RcIcon(icon!, size: fontSize + 4, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: TextStyle(
                      color: textColor,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none)),
            ],
          ),
        ),
      );
}

/// Huy hiệu số người chơi (người + số).
class PlayerBadge extends StatelessWidget {
  final String text;
  const PlayerBadge(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0x66000000),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RcIcon('ic_users', size: 13, color: Ios.label),
            const SizedBox(width: 4),
            Text(text,
                style: const TextStyle(
                    color: Ios.label,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.none)),
          ],
        ),
      );
}

/// Thẻ game: icon ở góc trái trên, tên ở dưới, huy hiệu số người ở góc phải.
class GameTile extends StatelessWidget {
  final Map<String, dynamic> game;
  final bool fav;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const GameTile({
    super.key,
    required this.game,
    required this.fav,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final tint = Color(game['tint'] as int);
    final soon = game['soon'] == true;
    final players = game['players'] as String;
    return GestureDetector(
      onLongPress: onLongPress,
      child: Tappable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: Ios.box(
            radius: 26,
            borderColor: tint.op(soon ? 0.25 : 0.55),
            gradient: LinearGradient(
              colors: [tint.op(soon ? 0.12 : 0.38), tint.op(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SquircleImage(
                      path: game['image'] as String, size: 58, shadow: false, dim: soon),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(game['name'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: soon ? Ios.label2 : Ios.label,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.none)),
                      Text(players == '1' ? '1 người chơi' : '$players người chơi',
                          style: const TextStyle(
                              color: Ios.label2,
                              fontSize: 12,
                              decoration: TextDecoration.none)),
                    ],
                  ),
                ],
              ),
              Positioned(top: 0, right: 0, child: PlayerBadge(players)),
              if (fav)
                const Positioned(
                  top: 30,
                  right: 2,
                  child: RcIcon('ic_star_fill', size: 18, color: Ios.yellow),
                ),
              if (soon)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0x66000000),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('SẮP CÓ',
                        style: TextStyle(
                            color: Ios.label,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.none)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Thanh tab ở đáy: nền kính mờ, tab đang chọn có bong bóng tròn sáng sau icon.
class PtTabBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const PtTabBar({super.key, required this.index, required this.onChanged});

  static const _items = [
    ['ic_gamepad', 'Chơi'],
    ['ic_chat', 'Nhắn'],
    ['ic_person', 'Tôi'],
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          decoration: const BoxDecoration(
            color: Color(0x55061A3A),
            border: Border(top: BorderSide(color: Ios.border, width: 1.2)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: List.generate(_items.length, (i) {
                final sel = i == index;
                return Expanded(
                  child: Tappable(
                    pressedScale: 0.94,
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          width: sel ? 64 : 40,
                          height: 36,
                          decoration: BoxDecoration(
                            color: sel ? Ios.accent : const Color(0x00000000),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: RcIcon(_items[i][0],
                                size: 25, color: sel ? Ios.label : Ios.label2),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(_items[i][1],
                            style: TextStyle(
                                color: sel ? Ios.label : Ios.label2,
                                fontSize: 12,
                                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                                decoration: TextDecoration.none)),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

/// Thẻ người chơi (tên + điểm), sáng viền khi đến lượt.
class PlayerCard extends StatelessWidget {
  final String name;
  final String sub;
  final Widget? leading;
  final bool active;
  const PlayerCard({
    super.key,
    required this.name,
    required this.sub,
    this.leading,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: Ios.box(
          fill: active ? Ios.accent.op(0.30) : Ios.card,
          borderColor: active ? Ios.teal : Ios.border,
          radius: 20,
          borderWidth: active ? 2 : 1.5,
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Ios.label,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.none)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Ios.label2,
                          fontSize: 12,
                          decoration: TextDecoration.none)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Hàng ngang các bạn bè để mời vào bàn.
class InviteFriendsRow extends StatelessWidget {
  final String code;
  final Future<void> Function(String friendId, String friendName) onInvite;
  final List<Map<String, String>> friends; // id, name, emoji
  const InviteFriendsRow({
    super.key,
    required this.code,
    required this.friends,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Mời bạn bè vào bàn',
            style: TextStyle(
                color: Ios.label2,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none)),
        const SizedBox(height: 8),
        SizedBox(
          height: 46,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: friends
                .map((f) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: PillButton(
                        label: '${f['emoji']} ${f['name']}',
                        height: 42,
                        fontSize: 14,
                        onTap: () => onInvite(f['id']!, f['name']!),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
