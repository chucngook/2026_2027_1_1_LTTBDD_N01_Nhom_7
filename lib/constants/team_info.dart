/// Thông tin nhóm và dự án – hiển thị ở trang "Giới thiệu nhóm".
/// TODO: nhóm điền thông tin thật của mình vào các hằng số dưới đây.
class TeamMember {
  final String name;
  final String studentId;
  final String role;
  final String emoji;
  const TeamMember(this.name, this.studentId, this.role, this.emoji);
}

class TeamInfo {
  TeamInfo._();

  static const String appName = 'Playtime (PT)';
  static const String version = '2.1.0';
  static const String tagline = 'Mini game cho hai người: chơi với máy, chơi chung máy hoặc chơi online';

  static const String course = 'Lập trình thiết bị di động';
  static const String classCode = '2026_2027_1_1_LTTBDD_N0x_Nhom_';
  static const String university = 'Tên trường / khoa của nhóm';
  static const String teacher = 'Giảng viên hướng dẫn';
  static const String github = 'https://github.com/ten-tai-khoan/ten-repo';

  static const List<TeamMember> members = [
    TeamMember('Họ và tên thành viên 1', 'MSSV 1', 'Nhóm trưởng • Thiết kế giao diện', '🧑‍💻'),
    TeamMember('Họ và tên thành viên 2', 'MSSV 2', 'Xử lý logic các game', '🎮'),
    TeamMember('Họ và tên thành viên 3', 'MSSV 3', 'Cơ sở dữ liệu & máy chủ online', '🗄️'),
    TeamMember('Họ và tên thành viên 4', 'MSSV 4', 'Kiểm thử & tài liệu', '📝'),
  ];

  static const List<String> features = [
    '4 game đối kháng: Ô ăn quan, Cờ ca-rô, Bắn máy bay, Cờ vua',
    'Ba cách chơi: với máy (3 mức), chung một máy, online qua mã bàn',
    '8 game một người với bảng điểm cao',
    'Nhắn tin trong bàn, kết bạn bằng mã QR, mời bạn vào bàn',
    'Nhạc nền, hiệu ứng âm thanh, rung phản hồi',
    'Đổi nền, cỡ chữ; hỗ trợ Tiếng Việt và English',
    'Lưu lịch sử ván đấu bằng cơ sở dữ liệu SQLite',
  ];

  static const List<String> tech = [
    'Flutter', 'Dart', 'SQLite', 'WebSocket', 'SharedPreferences', 'audioplayers', 'qr_flutter',
  ];
}
