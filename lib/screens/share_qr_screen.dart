import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/fx.dart';
import '../services/friend_service.dart';
import '../services/lang.dart';
import '../services/player_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/recess_ui.dart';

/// Mã QR riêng của mỗi người chơi để bạn bè quét và kết bạn.
class ShareQrScreen extends StatelessWidget {
  const ShareQrScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PlayerService.instance;
    final payload = FriendService.myPayload();
    return PageScaffold(
      title: 'Chia sẻ Playtime',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: payload,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: const Color(0xFFFFFFFF),
                  ),
                  const SizedBox(height: 10),
                  Text('${p.emoji}  ${p.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xFF0A2F6B),
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Bạn bè quét mã này trong Playtime để kết bạn với bạn.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Ios.label2, fontSize: 15, height: 1.35)),
            const SizedBox(height: 20),
            IosButton(
              label: 'Quét mã của bạn bè',
              icon: CupertinoIcons.qrcode_viewfinder,
              color: Ios.accent,
              onPressed: () => Navigator.of(context)
                  .push(CupertinoPageRoute<void>(builder: (_) => const ScanQrScreen())),
            ),
            const SizedBox(height: 10),
            IosButton(
              label: 'Sao chép mã của tôi',
              color: Ios.card2,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: payload));
                Fx.play(Sound.correct);
                if (context.mounted) {
                  showIosAlert(context, 'Đã sao chép', 'Gửi mã này cho bạn bè để họ dán vào mục "Quét mã".');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Quét mã QR của bạn bè (hoặc dán mã) để thêm vào danh sách bạn bè.
class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final TextEditingController _paste = TextEditingController();
  bool _handled = false;

  @override
  void dispose() {
    _paste.dispose();
    super.dispose();
  }

  Future<void> _addFrom(String raw) async {
    final f = FriendService.parse(raw);
    if (f == null) {
      if (!_handled) showIosAlert(context, 'Mã không hợp lệ', 'Đây không phải mã kết bạn của Playtime.');
      return;
    }
    if (_handled) return;
    _handled = true;
    if (f.id == PlayerService.instance.id) {
      _handled = false;
      showIosAlert(context, 'Ồ!', 'Đây là mã của chính bạn.');
      return;
    }
    await FriendService.instance.add(f.id, f.name, f.emoji);
    Fx.play(Sound.correct);
    if (!mounted) return;
    await showIosAlert(context, 'Đã kết bạn!', '${f.emoji} ${f.name} đã được thêm vào danh sách bạn bè.');
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Quét mã bạn bè',
      child: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(18),
              decoration: Ios.box(radius: 28, borderColor: Ios.teal, borderWidth: 2),
              clipBehavior: Clip.antiAlias,
              child: MobileScanner(
                onDetect: (capture) {
                  for (final b in capture.barcodes) {
                    final raw = b.rawValue;
                    if (raw != null && !_handled) {
                      _addFrom(raw);
                      break;
                    }
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _paste,
                    placeholder: tr('Hoặc dán mã bạn bè vào đây'),
                    placeholderStyle: const TextStyle(color: Ios.label2),
                    style: const TextStyle(color: Ios.label, fontSize: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: Ios.box(fill: const Color(0x33000000), radius: 18),
                  ),
                ),
                const SizedBox(width: 8),
                PillButton(
                    label: 'Thêm',
                    fill: Ios.accent,
                    borderColor: Ios.teal,
                    onTap: () => _addFrom(_paste.text.trim())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
