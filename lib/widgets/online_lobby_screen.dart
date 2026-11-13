import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import '../services/friend_service.dart';
import '../screens/scan_table_screen.dart';
import '../services/lang.dart';
import '../services/settings_service.dart';
import '../services/table_service.dart';
import '../theme/ios_theme.dart';
import 'dot_background.dart';
import 'ios_widgets.dart';
import 'recess_ui.dart';
import 'table_info_card.dart';

/// Sảnh online: mở bàn (nhận mã 4 số) hoặc vào bàn bằng mã.
/// Dùng chung "bàn" (TableService) với tab Nhắn. Trả về true khi đã đủ 2 người.
class OnlineLobbyScreen extends StatefulWidget {
  /// null = chỉ vào bàn (nút "Vào bàn" ở trang chủ / "Nhập mã bàn").
  final String? gameId;
  final String gameName;

  const OnlineLobbyScreen({super.key, this.gameId, this.gameName = ''});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final TextEditingController _code = TextEditingController();
  late final TextEditingController _host =
      TextEditingController(text: AppSettings.instance.lastHost);
  final TableService _table = TableService.instance;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _host.dispose();
    // Thoát khi đang chờ mà chưa có ai vào → hủy bàn
    if (!_done && _table.isOpen && !_table.seated) _table.leave();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _code.text.trim();
    if (code.length != 4) {
      setState(() => _error = 'Mã bàn gồm 4 chữ số.');
      return;
    }
    final lan = AppSettings.instance.wsUrl.isEmpty;
    final host = _host.text.trim();
    if (lan && host.isEmpty) {
      setState(() => _error = 'Hãy nhập địa chỉ IP của chủ bàn.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final ok = await _table.join(code, host: lan ? host : null);
    if (!mounted) return;
    if (ok) {
      _done = true;
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = _table.error);
    }
  }

  Future<void> _scan() async {
    final r = await Navigator.of(context).push<Map<String, String>>(
        CupertinoPageRoute<Map<String, String>>(builder: (_) => const ScanTableScreen()));
    if (r == null || !mounted) return;
    _host.text = r['host'] ?? '';
    _code.text = r['code'] ?? '';
    _join();
  }

  Future<void> _invite(String id, String name) async {
    final ok = await PresenceService.instance.invite(id, _table.code);
    if (!mounted) return;
    showIosAlert(
        context,
        ok ? 'Đã gửi lời mời' : 'Không gửi được',
        ok
            ? '$name sẽ nhận được lời mời vào bàn ${_table.code}.'
            : '$name đang ngoại tuyến hoặc chưa mở app. Hãy gửi mã bàn cho họ.');
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = widget.gameId != null;
    return CupertinoPageScaffold(
      backgroundColor: Ios.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0x33000000),
        border: null,
        middle: Text(canCreate ? 'Chơi online' : 'Vào bàn',
            style: const TextStyle(
                color: Ios.label, fontWeight: FontWeight.w800, fontSize: 19)),
        leading: CupertinoNavigationBarBackButton(
          color: Ios.label,
          previousPageTitle: tr('Quay lại'),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: DotBackground()),
          SafeArea(
            child: AnimatedBuilder(
              animation: Listenable.merge([_table, FriendService.instance]),
              builder: (context, _) {
                // Đã đủ người ở chế độ tạo bàn → trả kết quả
                if (_table.seated && canCreate && !_done) {
                  _done = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) Navigator.of(context).pop(true);
                  });
                }
                final waiting = _table.isOpen && !_table.seated;
                final err = _error ?? _table.error;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (widget.gameName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(widget.gameName,
                              style: const TextStyle(
                                  color: Ios.label2,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                        ),
                      if (waiting)
                        _waitingCard()
                      else if (_table.busy)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: CupertinoActivityIndicator(radius: 16),
                        )
                      else ...[
                        if (canCreate) ...[
                          _card(
                            emoji: '🎲',
                            title: 'Tạo bàn mới',
                            subtitle: 'Nhận mã 4 số và gửi cho bạn bè',
                            child: IosButton(
                                label: 'Tạo bàn',
                                color: Ios.accent,
                                onPressed: _table.open),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _card(
                          emoji: '🔑',
                          title: 'Vào bàn có sẵn',
                          subtitle: AppSettings.instance.wsUrl.isEmpty
                              ? 'Nhập địa chỉ IP và mã bàn, hoặc quét mã QR của chủ bàn'
                              : 'Nhập mã bàn mà bạn bè đã gửi',
                          child: Column(
                            children: [
                              if (AppSettings.instance.wsUrl.isEmpty) ...[
                                CupertinoTextField(
                                  controller: _host,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  placeholder: tr('Địa chỉ IP của chủ bàn'),
                                  placeholderStyle: const TextStyle(color: Ios.label2),
                                  style: const TextStyle(
                                      color: Ios.label,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800),
                                  textAlign: TextAlign.center,
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  decoration: Ios.box(
                                      fill: const Color(0x33000000), radius: 18),
                                ),
                                const SizedBox(height: 10),
                              ],
                              CupertinoTextField(
                                controller: _code,
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Ios.label,
                                    fontSize: 32,
                                    letterSpacing: 10,
                                    fontWeight: FontWeight.w800),
                                placeholder: '0000',
                                placeholderStyle: const TextStyle(
                                    color: Ios.card3, fontSize: 32, letterSpacing: 10),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: Ios.box(
                                    fill: const Color(0x33000000),
                                    borderColor: Ios.teal,
                                    radius: 18),
                              ),
                              const SizedBox(height: 12),
                              IosButton(
                                  label: 'Vào bàn',
                                  color: const Color(0xFF2F6FD6),
                                  onPressed: _join),
                              if (AppSettings.instance.wsUrl.isEmpty) ...[
                                const SizedBox(height: 8),
                                IosButton(
                                    label: 'Quét mã QR',
                                    icon: CupertinoIcons.qrcode_viewfinder,
                                    color: Ios.card2,
                                    onPressed: _scan),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (err != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Text(err,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Ios.red,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String emoji,
    required String title,
    required String subtitle,
    required Widget child,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: Ios.box(radius: 28),
        child: Column(
          children: [
            Row(
              children: [
                AvatarBox(emoji: emoji, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Ios.label,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                      Text(subtitle,
                          style: const TextStyle(color: Ios.label2, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  Widget _waitingCard() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: Ios.box(radius: 28, borderColor: Ios.teal),
        child: Column(
          children: [
            const TableInfoCard(),
            if (!_table.lanMode) ...[
              const SizedBox(height: 14),
              InviteFriendsRow(
                code: _table.code,
                friends: FriendService.instance.items
                    .map((f) => {'id': f.id, 'name': f.name, 'emoji': f.emoji})
                    .toList(),
                onInvite: _invite,
              ),
            ],
            const SizedBox(height: 16),
            const CupertinoActivityIndicator(radius: 13),
            const SizedBox(height: 8),
            const Text('Đang chờ đối thủ vào bàn...',
                style: TextStyle(color: Ios.label, fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            PillButton(
                label: 'Hủy bàn',
                onTap: () {
                  _table.leave();
                  if (mounted) Navigator.of(context).pop(false);
                },
                textColor: Ios.red),
          ],
        ),
      );
}
