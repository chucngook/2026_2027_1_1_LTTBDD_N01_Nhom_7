import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/table_service.dart';
import '../theme/ios_theme.dart';

/// Thông tin bàn đang chờ: mã bàn, địa chỉ IP (chơi qua Wi-Fi) và mã QR để máy kia quét.
class TableInfoCard extends StatelessWidget {
  const TableInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = TableService.instance;
    final payload = t.joinPayload;
    final addr = '${t.hostIp}:${t.hostPort}';
    return Column(
      children: [
        Row(
          children: [
            if (payload != null)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(14)),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 104,
                  backgroundColor: const Color(0xFFFFFFFF),
                ),
              ),
            if (payload != null) const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Mã bàn của bạn',
                      style: TextStyle(
                          color: Ios.label2,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none)),
                  Text(t.code,
                      style: const TextStyle(
                          color: Ios.teal,
                          fontSize: 44,
                          letterSpacing: 6,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          decoration: TextDecoration.none)),
                  if (t.lanMode) ...[
                    const SizedBox(height: 4),
                    const Text('Địa chỉ bàn',
                        style: TextStyle(
                            color: Ios.label2,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none)),
                    Text(addr,
                        style: const TextStyle(
                            color: Ios.label,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            decoration: TextDecoration.none)),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
            t.lanMode
                ? 'Máy kia chọn "Vào bàn", nhập địa chỉ IP và mã bàn (hoặc quét mã QR). Hai máy phải cùng Wi-Fi và bạn cần giữ app mở.'
                : 'Gửi mã này cho bạn bè để họ bấm "Vào bàn"',
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Ios.label2, fontSize: 13, height: 1.35, decoration: TextDecoration.none)),
      ],
    );
  }
}
