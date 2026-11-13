import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import '../services/fx.dart';
import '../services/lang.dart';
import '../services/player_service.dart';
import '../theme/ios_theme.dart';
import 'recess_ui.dart';

/// Thẻ hồ sơ: avatar, tên vui tự cấp và nút Sửa.
class ProfileCard extends StatelessWidget {
  final String buttonLabel;
  const ProfileCard({super.key, this.buttonLabel = 'Sửa'});

  static void rename(BuildContext context) {
    Fx.select();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Đổi tên của bạn'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              PlayerService.instance.reroll();
              Fx.play(Sound.correct);
            },
            child: const Text('Tên vui ngẫu nhiên'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _custom(context);
            },
            child: const Text('Tự đặt tên'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  static void _custom(BuildContext context) {
    final ctrl = TextEditingController(text: PlayerService.instance.name);
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Tên của bạn'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: ctrl,
            maxLength: 24,
            autofocus: true,
            placeholder: tr('Nhập tên...'),
          ),
        ),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              PlayerService.instance.setName(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PlayerService.instance,
      builder: (context, _) {
        final p = PlayerService.instance;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: Ios.box(
            radius: 30,
            borderColor: Ios.teal.op(0.6),
            gradient: LinearGradient(
              colors: [Ios.accent.op(0.45), Ios.card],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              AvatarBox(emoji: p.emoji, size: 66, inset: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Xin chào! Bạn là',
                        style: TextStyle(
                            color: Ios.label2,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none)),
                    const SizedBox(height: 2),
                    Text(p.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Ios.label,
                            fontSize: 21,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.none)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PillButton(
                icon: 'ic_pencil',
                label: buttonLabel,
                height: 42,
                fontSize: 15,
                onTap: () => rename(context),
              ),
            ],
          ),
        );
      },
    );
  }
}
