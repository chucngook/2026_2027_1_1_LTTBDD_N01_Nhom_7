// Máy chủ độc lập cho Playtime (chơi từ xa qua Internet).
//
// Chạy:   dart server/server.dart                (mặc định cổng 8080)
//         dart server/server.dart 9000           (đổi cổng)
// Hoặc đặt biến môi trường PORT (khi deploy lên Render/Fly/Railway...).
//
// Lưu ý: nếu chỉ muốn chơi qua Wi-Fi trong nhà thì KHÔNG cần chạy file này –
// một điện thoại có thể làm chủ bàn ngay trong app.
import 'dart:io';
import '../lib/services/relay_server.dart';

Future<void> main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ??
      (args.isNotEmpty ? int.tryParse(args[0]) ?? 8080 : 8080);
  final server = await RelayServer.start(port: port);
  print('Playtime server đang chạy ở cổng ${server.port}');
}
