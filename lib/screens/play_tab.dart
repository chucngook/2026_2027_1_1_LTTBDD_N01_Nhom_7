import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import '../constants/app_assets.dart';
import '../services/fx.dart';
import '../services/app_nav.dart';
import '../services/player_service.dart';
import '../services/stats_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/app_images.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/online_lobby_screen.dart';
import '../widgets/profile_card.dart';
import '../widgets/recess_ui.dart';
import 'game_router.dart';

/// Tab "Chơi": logo, Vào bàn, hồ sơ, danh sách game.
class PlayTab extends StatefulWidget {
  final VoidCallback onOpenMe;
  const PlayTab({super.key, required this.onOpenMe});

  @override
  State<PlayTab> createState() => _PlayTabState();
}

class _PlayTabState extends State<PlayTab> {
  late final List<Map<String, dynamic>> _games;
  List<String> _favs = [];
  String _sort = 'default';

  @override
  void initState() {
    super.initState();
    _games = AppAssets.getAllGamesWithAssets();
    _load();
  }

  Future<void> _load() async {
    final f = await StatsService.instance.favorites();
    final s = await StatsService.instance.sortMode();
    if (!mounted) return;
    setState(() {
      _favs = f;
      _sort = s;
    });
  }

  List<Map<String, dynamic>> get _sorted {
    final list = List<Map<String, dynamic>>.from(_games);
    if (_sort == 'fav') {
      final a = list.where((g) => _favs.contains(g['id'])).toList();
      final b = list.where((g) => !_favs.contains(g['id'])).toList();
      return [...a, ...b];
    }
    if (_sort == 'az') {
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
    }
    return list;
  }

  Future<void> _joinTable() async {
    Fx.select();
    final ok = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(builder: (_) => const OnlineLobbyScreen()),
    );
    if (ok == true) homeTabNotifier.value = 1; // sang tab Nhắn để trò chuyện trong bàn
  }

  void _pickSort() {
    Fx.select();
    Future<void> set(String m) async {
      await StatsService.instance.setSortMode(m);
      if (mounted) setState(() => _sort = m);
    }

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Sắp xếp trò chơi'),
        message: const Text('Giữ lâu vào một game để ghim làm yêu thích ★'),
        actions: [
          CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                set('default');
              },
              child: Text('Mặc định${_sort == 'default' ? '  ✓' : ''}')),
          CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                set('fav');
              },
              child: Text('Yêu thích lên đầu${_sort == 'fav' ? '  ✓' : ''}')),
          CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                set('az');
              },
              child: Text('Tên A → Z${_sort == 'az' ? '  ✓' : ''}')),
        ],
        cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
      ),
    );
  }

  Future<void> _toggleFav(String id) async {
    Fx.medium();
    Fx.play(Sound.coin);
    final f = await StatsService.instance.toggleFavorite(id);
    if (mounted) setState(() => _favs = List<String>.from(f));
  }

  @override
  Widget build(BuildContext context) {
    final games = _sorted;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Row(
                children: [
                  const SquircleImage(path: AppImages.logo, size: 44, shadow: false),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text('Playtime',
                          style: TextStyle(
                              color: Ios.label,
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.none)),
                    ),
                  ),
                  PillButton(
                    icon: 'ic_key',
                    label: 'Vào bàn',
                    fill: Ios.accent,
                    borderColor: Ios.teal,
                    height: 46,
                    fontSize: 16,
                    onTap: _joinTable,
                  ),
                  const SizedBox(width: 8),
                  Tappable(
                    onTap: widget.onOpenMe,
                    child: AnimatedBuilder(
                      animation: PlayerService.instance,
                      builder: (context, _) =>
                          AvatarBox(emoji: PlayerService.instance.emoji, size: 46),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: ProfileCard(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: PillButton(
                icon: 'ic_star',
                label: 'Sắp xếp',
                height: 42,
                fontSize: 15,
                onTap: _pickSort,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.14,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) {
                final g = games[i];
                final id = g['id'] as String;
                return GameTile(
                  game: g,
                  fav: _favs.contains(id),
                  onTap: () {
                    Fx.select();
                    GameRouter.open(context, g);
                  },
                  onLongPress: () => _toggleFav(id),
                );
              },
              childCount: games.length,
            ),
          ),
        ),
      ],
    );
  }
}
