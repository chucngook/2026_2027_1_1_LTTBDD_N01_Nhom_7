import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hồ sơ người chơi: không cần đăng nhập, tự cấp một cái tên vui nhộn.
class PlayerService extends ChangeNotifier {
  PlayerService._();
  static final PlayerService instance = PlayerService._();

  // (tên con vật, emoji)
  static const List<List<String>> _animals = [
    ['Hổ Vằn', '🐅'],
    ['Chim Câu', '🕊️'],
    ['Mèo Mướp', '🐱'],
    ['Cún Con', '🐶'],
    ['Thỏ Trắng', '🐰'],
    ['Gấu Trúc', '🐼'],
    ['Cáo Đỏ', '🦊'],
    ['Sư Tử', '🦁'],
    ['Cá Heo', '🐬'],
    ['Ếch Xanh', '🐸'],
    ['Vịt Vàng', '🦆'],
    ['Khỉ Con', '🐵'],
    ['Cú Mèo', '🦉'],
    ['Rùa Thần', '🐢'],
    ['Voi Con', '🐘'],
    ['Cá Mập', '🦈'],
    ['Bạch Tuộc', '🐙'],
    ['Heo Hồng', '🐷'],
    ['Gà Trống', '🐓'],
    ['Kỳ Lân', '🦄'],
    ['Hươu Cao Cổ', '🦒'],
    ['Ngựa Vằn', '🦓'],
    ['Cua Đỏ', '🦀'],
    ['Ong Mật', '🐝'],
  ];

  static const List<String> _traits = [
    'Bão Tố',
    'Vui Vẻ',
    'Siêu Tốc',
    'Lém Lỉnh',
    'Tinh Nghịch',
    'Dũng Cảm',
    'Bất Bại',
    'Mê Game',
    'Thần Tốc',
    'Ngáo Ngơ',
    'Cuồng Phong',
    'Đáng Yêu',
    'Quậy Phá',
    'Chiến Thần',
    'Hóng Hớt',
    'Lười Biếng',
    'Phi Thường',
    'Nhanh Như Chớp',
    'Thích Ăn Vặt',
    'Hay Cười',
  ];

  String id = '';
  String name = 'Người Chơi';
  String emoji = '🙂';

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    id = p.getString('player_id') ?? '';
    final savedName = p.getString('player_name');
    final savedEmoji = p.getString('player_emoji');
    if (id.isEmpty || savedName == null || savedEmoji == null) {
      id = _randomId();
      await p.setString('player_id', id);
      _roll();
      await _save();
    } else {
      name = savedName;
      emoji = savedEmoji;
    }
  }

  String _randomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random();
    return List.generate(10, (_) => chars[r.nextInt(chars.length)]).join();
  }

  void _roll() {
    final r = Random();
    final a = _animals[r.nextInt(_animals.length)];
    name = '${a[0]} ${_traits[r.nextInt(_traits.length)]}';
    emoji = a[1];
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('player_name', name);
    await p.setString('player_emoji', emoji);
  }

  /// Đổi sang một tên ngẫu nhiên khác.
  Future<void> reroll() async {
    _roll();
    notifyListeners();
    await _save();
  }

  /// Tự đặt tên (giữ nguyên avatar).
  Future<void> setName(String v) async {
    final t = v.trim();
    if (t.isEmpty) return;
    name = t.length > 24 ? t.substring(0, 24) : t;
    notifyListeners();
    await _save();
  }
}
