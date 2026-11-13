import 'package:flutter/cupertino.dart';
import '../constants/app_assets.dart';
import '../services/app_nav.dart';
import '../services/fx.dart';
import '../services/settings_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/dot_background.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/recess_ui.dart';
import 'me_tab.dart';
import 'messages_tab.dart';
import 'play_tab.dart';

/// Khung chính: 3 tab (Chơi / Nhắn / Tôi) với thanh tab kính mờ ở đáy.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    homeTabNotifier.addListener(_onTab);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminder());
  }

  @override
  void dispose() {
    homeTabNotifier.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() => setState(() {});

  /// Nhắc chơi: nếu đã quá giờ hẹn và hôm nay chưa chơi ván nào thì nhắc một lần.
  Future<void> _checkReminder() async {
    final cfg = AppSettings.instance;
    if (!cfg.reminderOn) return;
    final now = DateTime.now();
    final due = DateTime(now.year, now.month, now.day, cfg.reminderHour, cfg.reminderMinute);
    final today = AppSettings.today();
    if (now.isBefore(due) || cfg.lastPlayDate == today || cfg.reminderShownDate == today) {
      return;
    }
    await cfg.markReminderShown();
    if (!mounted) return;
    final games = AppAssets.getAllGamesWithAssets().where((g) => g['soon'] != true).toList();
    games.shuffle();
    Fx.play(Sound.coin);
    showIosAlert(context, 'Đến giờ chơi rồi!',
        'Hôm nay bạn chưa chơi ván nào. Thử "${games.first['name']}" nhé?');
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.of(context).viewInsets.bottom > 0;
    final tab = homeTabNotifier.value;
    return CupertinoPageScaffold(
      backgroundColor: Ios.bg,
      child: Stack(
        children: [
          const Positioned.fill(child: DotBackground()),
          IndexedStack(
            index: tab,
            children: [
              PlayTab(onOpenMe: () => homeTabNotifier.value = 2),
              MessagesTab(active: tab == 1, bottomInset: keyboard ? 8 : 96),
              MeTab(active: tab == 2),
            ],
          ),
          if (!keyboard)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: PtTabBar(
                index: tab,
                onChanged: (i) {
                  if (i != tab) Fx.select();
                  homeTabNotifier.value = i;
                },
              ),
            ),
        ],
      ),
    );
  }
}
