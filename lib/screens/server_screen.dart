import 'dart:io';
import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import '../services/lan_info.dart';
import '../services/lang.dart';
import '../services/settings_service.dart';
import '../services/table_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/recess_ui.dart';

/// Nhập địa chỉ máy chủ online và kiểm tra kết nối.
class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  late final TextEditingController _c =
      TextEditingController(text: AppSettings.instance.serverUrl);
  bool _testing = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _test() async {
    await AppSettings.instance.setServerUrl(_c.text);
    final url = AppSettings.instance.wsUrl;
    if (url.isEmpty) {
      showIosAlert(context, 'Chưa nhập địa chỉ', 'Hãy nhập địa chỉ máy chủ trước.');
      return;
    }
    setState(() => _testing = true);
    try {
      final ws = await WebSocket.connect(url).timeout(const Duration(seconds: 6));
      await ws.close();
      PresenceService.instance.start();
      if (mounted) {
        showIosAlert(context, 'Kết nối thành công', 'Máy chủ đang hoạt động. Bạn có thể chơi online!');
      }
    } catch (_) {
      if (mounted) {
        showIosAlert(context, 'Không kết nối được',
            'Hãy kiểm tra máy chủ đã chạy chưa, địa chỉ có đúng không, và điện thoại có cùng mạng không.');
      }
    }
    if (mounted) setState(() => _testing = false);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Máy chủ online',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: Ios.box(radius: 24, borderColor: Ios.teal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chơi qua Wi-Fi (không cần máy chủ)',
                      style: TextStyle(
                          color: Ios.label, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text(
                      'Để trống ô địa chỉ bên dưới. Một máy bấm "Mở bàn" rồi đọc địa chỉ IP và mã bàn cho máy kia; máy kia chọn "Vào bàn" và nhập hoặc quét mã QR. Hai máy phải cùng Wi-Fi.',
                      style: TextStyle(color: Ios.label2, fontSize: 14, height: 1.4)),
                  const SizedBox(height: 10),
                  FutureBuilder<String?>(
                    future: LanInfo.localIp(),
                    builder: (context, snap) => Text(
                        '${tr('Địa chỉ IP của máy này')}: ${snap.data ?? '—'}',
                        style: const TextStyle(
                            color: Ios.teal, fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: Ios.box(radius: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Máy chủ ngoài (tùy chọn, để chơi từ xa)',
                      style: TextStyle(
                          color: Ios.label, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    controller: _c,
                    placeholder: '192.168.1.5:8080',
                    placeholderStyle: const TextStyle(color: Ios.label2),
                    style: const TextStyle(color: Ios.label),
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: Ios.box(fill: const Color(0x33000000), radius: 16),
                    onChanged: (v) => AppSettings.instance.setServerUrl(v),
                  ),
                  const SizedBox(height: 12),
                  IosButton(
                      label: _testing ? 'Đang kiểm tra...' : 'Kiểm tra kết nối',
                      color: Ios.accent,
                      onPressed: _testing ? null : _test),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
                tr('Chạy máy chủ bằng lệnh "dart server/server.dart" trên máy tính. Hai người chơi nhập cùng một địa chỉ và dùng chung mạng (hoặc máy chủ đã được đưa lên Internet, dạng wss://...).'),
                style: const TextStyle(color: Ios.label2, fontSize: 14, height: 1.4)),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: PresenceService.instance,
              builder: (_, __) => Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: PresenceService.instance.online ? Ios.green : Ios.card3),
                  ),
                  const SizedBox(width: 8),
                  Text(PresenceService.instance.online ? 'Đang kết nối máy chủ' : 'Chưa kết nối máy chủ',
                      style: const TextStyle(color: Ios.label2, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
