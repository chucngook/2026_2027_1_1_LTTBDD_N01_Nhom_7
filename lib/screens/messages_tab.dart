import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import '../constants/app_assets.dart';
import '../services/fx.dart';
import '../services/friend_service.dart';
import '../services/lang.dart';
import '../services/player_service.dart';
import '../services/settings_service.dart';
import '../services/table_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/online_lobby_screen.dart';
import '../widgets/recess_ui.dart';
import '../widgets/table_info_card.dart';
import 'server_screen.dart';

/// Tab "Nhắn": trò chuyện trong "bàn". Chưa vào bàn thì hiện nút Mở bàn / Nhập mã bàn.
class MessagesTab extends StatefulWidget {
  final bool active;
  final double bottomInset;
  const MessagesTab({super.key, required this.active, required this.bottomInset});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final TableService _table = TableService.instance;
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _table.addListener(_onTable);
  }

  @override
  void dispose() {
    _table.removeListener(_onTable);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onTable() {
    final n = _table.takeNotice();
    if (n != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showIosAlert(context, 'Thông báo', n);
      });
    }
    if (_table.messages.length != _lastCount) {
      _lastCount = _table.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });
    }
  }

  bool get _hasServer => AppSettings.instance.wsUrl.isNotEmpty;

  void _openServer() => Navigator.of(context)
      .push(CupertinoPageRoute<void>(builder: (_) => const ServerScreen()));

  Future<void> _openTable() async {
    Fx.select();
    await _table.open();
  }

  Future<void> _joinTable() async {
    Fx.select();
    await Navigator.of(context).push<bool>(
        CupertinoPageRoute<bool>(builder: (_) => const OnlineLobbyScreen()));
  }

  void _send() {
    final t = _input.text.trim();
    if (t.isEmpty) return;
    Fx.play(Sound.tap);
    _table.sendChat(t);
    _input.clear();
  }

  void _pickGame() {
    Fx.select();
    final games = AppAssets.getAllGamesWithAssets()
        .where((g) => g['versus'] == true && g['soon'] != true)
        .toList();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Chọn game để chơi cùng nhau'),
        actions: [
          for (final g in games)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _table.pickGame(g['id'] as String);
              },
              child: Text(g['name'] as String),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
      ),
    );
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

  // ───────── Giao diện ─────────
  Widget _empty() => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RcIcon('ic_chat', size: 76, color: Ios.label),
              const SizedBox(height: 18),
              const Text('Vào bàn để trò chuyện',
                  style: TextStyle(
                      color: Ios.label,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none)),
              const SizedBox(height: 8),
              const Text(
                  'Vào bàn hoặc mở bàn là nhắn chung được. Chưa cần bắt đầu trò chơi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Ios.label2,
                      fontSize: 15,
                      height: 1.35,
                      decoration: TextDecoration.none)),
              const SizedBox(height: 22),
              if (_table.busy)
                const CupertinoActivityIndicator(radius: 14)
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    PillButton(
                        label: 'Mở bàn',
                        fill: Ios.accent,
                        borderColor: Ios.teal,
                        onTap: _openTable),
                    const SizedBox(width: 10),
                    PillButton(label: 'Nhập mã bàn', onTap: _joinTable),
                  ],
                ),
              if (!_hasServer) ...[
                const SizedBox(height: 18),
                Tappable(
                  onTap: _openServer,
                  child: const Text('Chơi qua Wi-Fi: hai máy cần cùng một mạng Wi-Fi ›',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Ios.yellow,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none)),
                ),
              ],
              if (_table.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(_table.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Ios.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none)),
                ),
            ],
          ),
        ),
      );

  Widget _bubble(TableMessage m) {
    if (m.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0x33000000), borderRadius: BorderRadius.circular(14)),
            child: Text(m.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Ios.label2, fontSize: 12, decoration: TextDecoration.none)),
          ),
        ),
      );
    }
    final mine = m.id == PlayerService.instance.id;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: Ios.box(
          fill: mine ? Ios.accent.op(0.55) : Ios.card2,
          borderColor: mine ? Ios.teal : Ios.border,
          radius: 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine)
              Text('${m.emoji} ${m.name}',
                  style: const TextStyle(
                      color: Ios.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.none)),
            Text(m.text,
                style: const TextStyle(
                    color: Ios.label,
                    fontSize: 16,
                    height: 1.25,
                    decoration: TextDecoration.none)),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    final friend = FriendService.instance.isFriend(_table.oppId);
    if (!_table.seated) {
      return Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        padding: const EdgeInsets.all(14),
        decoration: Ios.box(radius: 24, borderColor: Ios.teal),
        child: Column(
          children: [
            const TableInfoCard(),
            if (!_table.lanMode && FriendService.instance.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              InviteFriendsRow(
                code: _table.code,
                friends: FriendService.instance.items
                    .map((f) => {'id': f.id, 'name': f.name, 'emoji': f.emoji})
                    .toList(),
                onInvite: _invite,
              ),
            ],
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      padding: const EdgeInsets.all(12),
      decoration: Ios.box(radius: 24, borderColor: Ios.green.op(0.7)),
      child: Row(
        children: [
          AvatarBox(emoji: _table.oppEmoji, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_table.oppName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Ios.label,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.none)),
                Text('Bàn ${_table.code} • đang trực tuyến',
                    style: const TextStyle(
                        color: Ios.green, fontSize: 12, decoration: TextDecoration.none)),
              ],
            ),
          ),
          if (!friend && _table.oppId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: PillButton(
                label: 'Kết bạn',
                height: 38,
                fontSize: 13,
                onTap: () async {
                  await FriendService.instance
                      .add(_table.oppId, _table.oppName, _table.oppEmoji);
                  Fx.play(Sound.correct);
                },
              ),
            ),
          PillButton(
              label: 'Chơi',
              height: 38,
              fontSize: 14,
              fill: Ios.accent,
              borderColor: Ios.teal,
              onTap: _pickGame),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_table, AppSettings.instance, FriendService.instance, PlayerService.instance]),
      builder: (context, _) {
        final open = _table.isOpen;
        return Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Tin nhắn',
                          style: TextStyle(
                              color: Ios.label,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.none)),
                    ),
                    if (open)
                      PillButton(
                        label: 'Rời bàn',
                        height: 38,
                        fontSize: 14,
                        textColor: Ios.red,
                        onTap: () {
                          Fx.select();
                          _table.leave();
                        },
                      ),
                  ],
                ),
              ),
            ),
            if (!open)
              Expanded(child: _empty())
            else ...[
              _tableHeader(),
              Expanded(
                child: _table.messages.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
                        itemCount: _table.messages.length,
                        itemBuilder: (_, i) => _bubble(_table.messages[i]),
                      ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(14, 6, 14, widget.bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoTextField(
                        controller: _input,
                        maxLength: 300,
                        placeholder: tr('Nhập tin nhắn...'),
                        placeholderStyle: const TextStyle(color: Ios.label2),
                        style: const TextStyle(color: Ios.label, fontSize: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        onSubmitted: (_) => _send(),
                        decoration: Ios.box(fill: const Color(0x33000000), radius: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PillButton(
                      label: 'Gửi',
                      height: 46,
                      fontSize: 15,
                      fill: Ios.accent,
                      borderColor: Ios.teal,
                      onTap: _send,
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
