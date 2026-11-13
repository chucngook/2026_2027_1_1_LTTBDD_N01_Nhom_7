import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../theme/ios_theme.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/page_scaffold.dart';

/// Quét mã QR của bàn (do chủ bàn hiển thị). Trả về {host, code}.
class ScanTableScreen extends StatefulWidget {
  const ScanTableScreen({super.key});

  @override
  State<ScanTableScreen> createState() => _ScanTableScreenState();
}

class _ScanTableScreenState extends State<ScanTableScreen> {
  bool _handled = false;

  void _onRaw(String raw) {
    if (_handled) return;
    try {
      final m = jsonDecode(raw);
      if (m is Map && m['app'] == 'playtime' && m['t'] == 'table') {
        _handled = true;
        Navigator.of(context).pop(<String, String>{
          'host': (m['host'] ?? '').toString(),
          'code': (m['code'] ?? '').toString(),
        });
        return;
      }
    } catch (_) {}
    showIosAlert(context, 'Mã không hợp lệ', 'Mã QR này không phải của một bàn Playtime.');
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Quét mã bàn',
      child: Container(
        margin: const EdgeInsets.all(18),
        decoration: Ios.box(radius: 28, borderColor: Ios.teal, borderWidth: 2),
        clipBehavior: Clip.antiAlias,
        child: MobileScanner(
          onDetect: (capture) {
            for (final b in capture.barcodes) {
              final raw = b.rawValue;
              if (raw != null) {
                _onRaw(raw);
                break;
              }
            }
          },
        ),
      ),
    );
  }
}
