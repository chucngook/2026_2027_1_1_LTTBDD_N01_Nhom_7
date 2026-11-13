import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import '../services/fx.dart';
import '../services/friend_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/recess_ui.dart';
import 'share_qr_screen.dart';

/// Danh sách bạn bè (lưu trong SQLite).
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  void _confirmRemove(BuildContext context, Friend f) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Xóa bạn bè?'),
        content: Text('${f.emoji} ${f.name}'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              FriendService.instance.remove(f.id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Bạn bè',
      child: AnimatedBuilder(
        animation: FriendService.instance,
        builder: (context, _) {
          final items = FriendService.instance.items;
          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                children: [
                  Expanded(
                    child: PillButton(
                      icon: 'ic_users',
                      label: 'Mã QR của tôi',
                      onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(builder: (_) => const ShareQrScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PillButton(
                      label: 'Quét mã bạn bè',
                      fill: Ios.accent,
                      borderColor: Ios.teal,
                      onTap: () => Navigator.of(context).push(
                          CupertinoPageRoute<void>(builder: (_) => const ScanQrScreen())),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: Ios.box(radius: 26),
                  child: const Column(
                    children: [
                      Text('🤝', style: TextStyle(fontSize: 44, decoration: TextDecoration.none)),
                      SizedBox(height: 10),
                      Text('Chưa có bạn bè',
                          style: TextStyle(
                              color: Ios.label,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              decoration: TextDecoration.none)),
                      SizedBox(height: 6),
                      Text('Quét mã QR của bạn bè hoặc bấm "Kết bạn" khi cùng ngồi một bàn.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Ios.label2, fontSize: 14, decoration: TextDecoration.none)),
                    ],
                  ),
                ),
              for (final f in items)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: Ios.box(radius: 24),
                  child: Row(
                    children: [
                      AvatarBox(emoji: f.emoji, size: 46),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(f.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Ios.label,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.none)),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Fx.select();
                          _confirmRemove(context, f);
                        },
                        child: const Icon(CupertinoIcons.trash, color: Ios.red, size: 22),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
