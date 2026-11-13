import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import '../constants/team_info.dart';
import '../services/fx.dart';
import '../services/friend_service.dart';
import '../services/settings_service.dart';
import '../services/stats_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/profile_card.dart';
import '../widgets/recess_ui.dart';
import '../widgets/settings_widgets.dart';
import 'about_screen.dart';
import 'friends_screen.dart';
import 'history_screen.dart';
import 'server_screen.dart';
import 'share_qr_screen.dart';

/// Tab "Tôi": hồ sơ + toàn bộ cài đặt (Dễ nhìn, Âm thanh, Cảm giác, Trò chuyện, Nhắc chơi...).
class MeTab extends StatefulWidget {
  final bool active;
  const MeTab({super.key, required this.active});

  @override
  State<MeTab> createState() => _MeTabState();
}

class _MeTabState extends State<MeTab> {
  int _played = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MeTab old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _load();
  }

  Future<void> _load() async {
    final n = await StatsService.instance.totalPlayed();
    if (mounted) setState(() => _played = n);
  }

  void _push(Widget w) =>
      Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => w));

  // ───────── Chọn nền ─────────
  void _pickTheme() {
    Fx.select();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => AnimatedBuilder(
        animation: AppSettings.instance,
        builder: (context, _) {
          final cur = AppSettings.instance.themeIndex;
          return Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(ctx).padding.bottom),
            decoration: const BoxDecoration(
              color: Color(0xFF0C2347),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Chọn màu nền',
                    style: TextStyle(
                        color: Ios.label,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: List.generate(AppThemes.all.length, (i) {
                    final t = AppThemes.all[i];
                    return Tappable(
                      onTap: () {
                        Fx.play(Sound.tap);
                        AppSettings.instance.setTheme(i);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                colors: [t.top, t.bottom],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              border: Border.all(
                                  color: i == cur ? Ios.label : Ios.border,
                                  width: i == cur ? 3 : 1.5),
                            ),
                            child: i == cur
                                ? const Icon(CupertinoIcons.checkmark_alt,
                                    color: Ios.label, size: 30)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(t.name,
                              style: const TextStyle(
                                  color: Ios.label2,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.none)),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 18),
                IosButton(
                    label: 'Xong',
                    color: Ios.accent,
                    onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _pickLanguage() {
    Fx.select();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Ngôn ngữ / Language'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              AppSettings.instance.setLanguage('vi');
            },
            child: Text('Tiếng Việt${AppSettings.instance.language == 'vi' ? '  ✓' : ''}'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              AppSettings.instance.setLanguage('en');
            },
            child: Text('English${AppSettings.instance.language == 'en' ? '  ✓' : ''}'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
      ),
    );
  }

  void _rate() {
    Fx.select();
    int stars = AppSettings.instance.rating;
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSt) => CupertinoAlertDialog(
          title: const Text('Đánh giá Playtime'),
          content: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final on = i < stars;
                return GestureDetector(
                  onTap: () => setSt(() => stars = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: RcIcon(on ? 'ic_star_fill' : 'ic_star',
                        size: 32, color: on ? Ios.yellow : Ios.label2),
                  ),
                );
              }),
            ),
          ),
          actions: [
            CupertinoDialogAction(
                onPressed: () => Navigator.pop(ctx), child: const Text('Để sau')),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                if (stars > 0) {
                  AppSettings.instance.setRating(stars);
                  Fx.play(Sound.win);
                  showIosAlert(context, 'Cảm ơn bạn!', 'Đánh giá của bạn giúp nhóm hoàn thiện Playtime hơn.');
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }

  void _pickTime() {
    Fx.select();
    final cfg = AppSettings.instance;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        padding: const EdgeInsets.only(top: 6),
        decoration: const BoxDecoration(
          color: Color(0xFF0C2347),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Xong',
                    style: TextStyle(color: Ios.teal, fontWeight: FontWeight.w800, fontSize: 17)),
              ),
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: DateTime(2026, 1, 1, cfg.reminderHour, cfg.reminderMinute),
                onDateTimeChanged: (d) =>
                    cfg.setReminder(hour: d.hour, minute: d.minute),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switch(bool v, ValueChanged<bool> on) =>
      CupertinoSwitch(value: v, onChanged: (x) {
        Fx.select();
        on(x);
      });

  String _two(int v) => v.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([AppSettings.instance, FriendService.instance]),
      builder: (context, _) {
        final cfg = AppSettings.instance;
        final theme = AppThemes.all[cfg.themeIndex < AppThemes.all.length ? cfg.themeIndex : 0];
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
          children: [
            SafeArea(
              bottom: false,
              child: const Padding(
                padding: EdgeInsets.only(top: 14, bottom: 14),
                child: Text('Tôi',
                    style: TextStyle(
                        color: Ios.label,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        decoration: TextDecoration.none)),
              ),
            ),
            const ProfileCard(),
            const SizedBox(height: 16),
            SettingsGroup(children: [
              SettingsRow(
                icon: CupertinoIcons.clock,
                color: Ios.orange,
                title: 'Ván đã chơi',
                value: '$_played',
                chevron: true,
                onTap: () => _push(const HistoryScreen()),
              ),
              SettingsRow(
                icon: CupertinoIcons.person_2,
                color: Ios.teal,
                title: 'Bạn bè',
                value: '${FriendService.instance.items.length}',
                chevron: true,
                onTap: () => _push(const FriendsScreen()),
              ),
              SettingsRow(
                icon: CupertinoIcons.qrcode,
                color: Ios.purple,
                title: 'Chia sẻ Playtime',
                subtitle: 'Mã QR để kết bạn',
                chevron: true,
                onTap: () => _push(const ShareQrScreen()),
              ),
              SettingsRow(
                icon: CupertinoIcons.star,
                color: Ios.yellow,
                title: 'Đánh giá Playtime',
                value: cfg.rating > 0 ? '${cfg.rating}/5' : null,
                chevron: true,
                onTap: _rate,
              ),
            ]),

            const SectionLabel('Dễ nhìn'),
            SettingsGroup(children: [
              SettingsRow(
                icon: CupertinoIcons.textformat_size,
                color: Ios.orange,
                title: 'Cỡ chữ',
                trailing: PillSegmented(
                  labels: const ['Thường', 'Lớn'],
                  index: cfg.largeText ? 1 : 0,
                  onChanged: (i) {
                    Fx.select();
                    cfg.setLargeText(i == 1);
                  },
                ),
              ),
              SettingsRow(
                icon: CupertinoIcons.globe,
                color: Ios.purple,
                title: 'Ngôn ngữ',
                value: cfg.language == 'vi' ? 'Tiếng Việt' : 'English',
                chevron: true,
                onTap: _pickLanguage,
              ),
              SettingsRow(
                icon: CupertinoIcons.paintbrush,
                color: Ios.blue,
                title: 'Giao diện',
                value: theme.name,
                chevron: true,
                onTap: _pickTheme,
              ),
            ]),

            const SectionLabel('Âm thanh'),
            SettingsGroup(children: [
              SettingsRow(
                icon: CupertinoIcons.speaker_2_fill,
                color: Ios.blue,
                title: 'Âm thanh trò chơi',
                trailing: _switch(cfg.sound, (v) {
                  cfg.setSound(v);
                  if (v) Fx.play(Sound.tap);
                }),
              ),
              SettingsRow(
                icon: CupertinoIcons.music_note,
                color: Ios.teal,
                title: 'Nhạc nền',
                subtitle: 'Playtime Bossa 8-bit',
                trailing: _switch(cfg.music, cfg.setMusic),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.speaker_fill, size: 18, color: Ios.label2),
                    Expanded(
                      child: CupertinoSlider(
                        value: cfg.volume,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        activeColor: Ios.teal,
                        onChanged: (v) => cfg.setVolume(v),
                        onChangeEnd: (_) => Fx.play(Sound.coin),
                      ),
                    ),
                    const Icon(CupertinoIcons.speaker_3_fill, size: 18, color: Ios.label2),
                  ],
                ),
              ),
            ]),

            const SectionLabel('Cảm giác'),
            SettingsGroup(children: [
              SettingsRow(
                icon: CupertinoIcons.device_phone_portrait,
                color: Ios.orange,
                title: 'Rung phản hồi',
                subtitle: 'Rung nhẹ khi chạm, thắng, thua',
                trailing: _switch(cfg.haptics, (v) {
                  cfg.setHaptics(v);
                  if (v) Fx.medium();
                }),
              ),
            ]),

            const SectionLabel('Trò chuyện'),
            SettingsGroup(children: [
              SettingsRow(
                icon: CupertinoIcons.bell,
                color: Ios.yellow,
                title: 'Âm báo tin nhắn',
                trailing: _switch(cfg.chatSound, cfg.setChatSound),
              ),
              SettingsRow(
                icon: CupertinoIcons.lock,
                color: Ios.green,
                title: 'Chỉ nhận lời mời từ bạn bè',
                trailing: _switch(cfg.friendsOnlyInvites, cfg.setFriendsOnly),
              ),
              SettingsRow(
                icon: CupertinoIcons.wifi,
                color: Ios.blue,
                title: 'Kết nối online',
                value: cfg.serverUrl.isEmpty ? 'Wi-Fi' : 'Máy chủ',
                chevron: true,
                onTap: () => _push(const ServerScreen()),
              ),
            ]),

            const SectionLabel('Nhắc chơi'),
            SettingsGroup(children: [
              SettingsRow(
                icon: CupertinoIcons.alarm,
                color: Ios.red,
                title: 'Nhắc tôi chơi mỗi ngày',
                subtitle: 'Hiện lời nhắc khi mở app sau giờ hẹn',
                trailing: _switch(cfg.reminderOn, (v) => cfg.setReminder(on: v)),
              ),
              if (cfg.reminderOn)
                SettingsRow(
                  icon: CupertinoIcons.time,
                  color: Ios.orange,
                  title: 'Giờ nhắc',
                  value: '${_two(cfg.reminderHour)}:${_two(cfg.reminderMinute)}',
                  chevron: true,
                  onTap: _pickTime,
                ),
            ]),

            const SectionLabel('Thông tin'),
            SettingsGroup(children: [
              SettingsRow(
                icon: CupertinoIcons.info,
                color: Ios.teal,
                title: 'Giới thiệu nhóm',
                chevron: true,
                onTap: () => _push(const AboutScreen()),
              ),
              const SettingsRow(
                icon: CupertinoIcons.device_phone_portrait,
                color: Ios.label2,
                title: 'Phiên bản',
                value: TeamInfo.version,
              ),
            ]),
          ],
        );
      },
    );
  }
}
