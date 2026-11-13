import 'package:flutter/cupertino.dart' hide Text;
import 'widgets/tr_text.dart';
import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/services.dart';
import 'screens/game_router.dart';
import 'screens/splash_screen.dart';
import 'services/app_nav.dart';
import 'services/friend_service.dart';
import 'services/music_service.dart';
import 'services/player_service.dart';
import 'services/settings_service.dart';
import 'services/table_service.dart';
import 'theme/ios_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  await PlayerService.instance.load();
  await FriendService.instance.load();

  // Game online chọn trong bàn → mở màn hình game; lời mời của bạn bè → hộp thoại
  TableService.instance.startGame = GameRouter.openTableGame;
  PresenceService.instance.onInvited = _showInvite;

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const MyApp());

  MusicService.instance.start(); // luôn có nhạc nền (đổi sang nhạc game khi vào game)
  PresenceService.instance.init();
}

void _showInvite(Map<String, dynamic> from, String code) {
  final ctx = rootNavKey.currentContext;
  if (ctx == null) return;
  showCupertinoDialog<void>(
    context: ctx,
    builder: (dc) => CupertinoAlertDialog(
      title: const Text('Lời mời vào bàn'),
      content: Text('${from['emoji']} ${from['name']} mời bạn vào bàn $code'),
      actions: [
        CupertinoDialogAction(
            onPressed: () => Navigator.pop(dc), child: const Text('Từ chối')),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () async {
            Navigator.pop(dc);
            final ok = await TableService.instance.join(code);
            if (ok) homeTabNotifier.value = 1;
          },
          child: const Text('Tham gia'),
        ),
      ],
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final MusicObserver _observer = MusicObserver();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, _) => CupertinoApp(
        title: 'Playtime',
        debugShowCheckedModeBanner: false,
        navigatorKey: rootNavKey,
        navigatorObservers: [_observer],
        theme: const CupertinoThemeData(
          brightness: Brightness.dark,
          primaryColor: Ios.accent,
          scaffoldBackgroundColor: Ios.bg,
          barBackgroundColor: Ios.bg,
          textTheme: CupertinoTextThemeData(
            textStyle: TextStyle(fontFamily: 'Baloo2', color: Ios.label, fontSize: 17),
          ),
        ),
        // Cỡ chữ Thường/Lớn + font tròn "Baloo2" (nếu chưa cài font sẽ dùng font hệ thống)
        builder: (ctx, child) {
          final mq = MediaQuery.of(ctx);
          return MediaQuery(
            data: mq.copyWith(
                textScaler: TextScaler.linear(AppSettings.instance.largeText ? 1.2 : 1.0)),
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontFamily: 'Baloo2'),
              child: child!,
            ),
          );
        },
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
