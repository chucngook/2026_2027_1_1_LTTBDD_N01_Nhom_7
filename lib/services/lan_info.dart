import 'dart:io';

/// Tìm địa chỉ IP Wi-Fi của máy (để máy kia kết nối vào).
class LanInfo {
  LanInfo._();

  static Future<String?> localIp() async {
    try {
      final ifs = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      String? best;
      var bestScore = -1000;
      for (final i in ifs) {
        final n = i.name.toLowerCase();
        for (final a in i.addresses) {
          final ip = a.address;
          var s = 0;
          if (ip.startsWith('192.168.')) {
            s += 30;
          } else if (ip.startsWith('10.')) {
            s += 25;
          } else if (RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip)) {
            s += 20;
          } else if (ip.startsWith('169.254.')) {
            s -= 50;
          } else {
            s += 1;
          }
          if (n.startsWith('en') || n.startsWith('wlan') || n.startsWith('wl') || n.contains('wifi')) {
            s += 10;
          }
          if (n.contains('utun') || n.contains('awdl') || n.contains('llw') ||
              n.contains('pdp') || n.contains('rmnet') || n.contains('tun') ||
              n.contains('docker') || n.contains('veth')) {
            s -= 40;
          }
          // 'bridge' là cầu nối của điểm truy cập cá nhân (hotspot) trên iPhone: vẫn dùng được,
          // chỉ ưu tiên thấp hơn Wi-Fi thật (en0).
          if (n.contains('bridge')) s -= 5;
          if (s > bestScore) {
            bestScore = s;
            best = ip;
          }
        }
      }
      return bestScore > -20 ? best : null;
    } catch (_) {
      return null;
    }
  }
}
