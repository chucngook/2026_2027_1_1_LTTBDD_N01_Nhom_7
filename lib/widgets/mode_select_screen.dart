import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import '../constants/app_assets.dart';
import '../services/fx.dart';
import '../services/lang.dart';
import '../services/online_service.dart';
import '../services/table_service.dart';
import '../theme/ios_theme.dart';
import 'app_images.dart';
import 'dot_background.dart';
import 'ios_widgets.dart';
import 'online_lobby_screen.dart';
import 'recess_ui.dart';

/// Chọn cách chơi: với máy (3 mức), với bạn (chung máy) hoặc online.
class ModeSelectScreen extends StatefulWidget {
  final String gameId;
  final String title;
  final String description;
  final Widget Function(MatchConfig config) buildGame;

  const ModeSelectScreen({
    super.key,
    required this.gameId,
    required this.title,
    required this.description,
    required this.buildGame,
  });

  @override
  State<ModeSelectScreen> createState() => _ModeSelectScreenState();
}

class _ModeSelectScreenState extends State<ModeSelectScreen> {
  bool _showLevels = false;

  void _start(MatchConfig cfg) {
    Fx.play(Sound.tap);
    Navigator.of(context).pushReplacement(CupertinoPageRoute<void>(
        settings: const RouteSettings(name: 'game'),
        builder: (_) => widget.buildGame(cfg)));
  }

  /// Chơi online dùng "bàn": nếu đã ở bàn thì chọn game ngay, chưa thì vào sảnh tạo bàn.
  Future<void> _online() async {
    Fx.select();
    final table = TableService.instance;
    if (table.seated) {
      table.pickGame(widget.gameId);
      return;
    }
    final ok = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (_) =>
            OnlineLobbyScreen(gameId: widget.gameId, gameName: widget.title),
      ),
    );
    if (ok == true && mounted) table.pickGame(widget.gameId);
  }

  Widget _option({
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color border = Ios.border,
    Widget? extra,
  }) {
    return Tappable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: Ios.box(radius: 26, borderColor: border),
        child: Column(
          children: [
            Row(
              children: [
                AvatarBox(emoji: emoji, size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: Ios.label,
                              fontSize: 20,
                              fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(color: Ios.label2, fontSize: 14)),
                    ],
                  ),
                ),
                const Icon(CupertinoIcons.chevron_right, color: Ios.label2, size: 20),
              ],
            ),
            if (extra != null) ...[const SizedBox(height: 14), extra],
          ],
        ),
      ),
    );
  }

  Widget _level(String label, String diff, Color color) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Tappable(
            onTap: () => _start(MatchConfig(mode: PlayMode.computer, difficulty: diff)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: Ios.box(
                  fill: color.op(0.22), borderColor: color, radius: 16, borderWidth: 2),
              child: Text(label,
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final game = AppAssets.getAllGamesWithAssets()
        .firstWhere((g) => g['id'] == widget.gameId);
    return CupertinoPageScaffold(
      backgroundColor: Ios.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0x33000000),
        border: null,
        middle: Text(widget.title,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SquircleImage(
                          path: game['image'] as String, size: 104, shadow: false),
                      Positioned(
                          right: -18, bottom: -6, child: PlayerBadge(game['players'] as String)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(widget.title,
                      style: const TextStyle(
                          color: Ios.label, fontSize: 30, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(widget.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Ios.label2, fontSize: 15, height: 1.35)),
                  const SizedBox(height: 22),
                  _option(
                    emoji: '🤖',
                    title: 'Chơi với máy',
                    subtitle: 'Chọn mức Dễ, Trung bình hoặc Khó',
                    onTap: () {
                      Fx.select();
                      setState(() => _showLevels = !_showLevels);
                    },
                    border: _showLevels ? Ios.teal : Ios.border,
                    extra: _showLevels
                        ? Row(
                            children: [
                              _level('Dễ', 'EASY', Ios.green),
                              _level('Trung bình', 'MEDIUM', Ios.orange),
                              _level('Khó', 'HARD', Ios.red),
                            ],
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  _option(
                    emoji: '👥',
                    title: 'Chơi với bạn',
                    subtitle: 'Hai người cùng chơi trên một máy',
                    onTap: () => _start(const MatchConfig(mode: PlayMode.local)),
                  ),
                  const SizedBox(height: 14),
                  _option(
                    emoji: '🌐',
                    title: 'Chơi online',
                    subtitle: 'Mời bạn ở máy khác bằng mã bàn',
                    border: Ios.blue.op(0.7),
                    onTap: _online,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
