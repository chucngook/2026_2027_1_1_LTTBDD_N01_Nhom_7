import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import 'package:flutter/services.dart';
import '../constants/team_info.dart';
import '../services/fx.dart';
import '../theme/ios_theme.dart';
import '../widgets/app_images.dart';
import '../widgets/ios_widgets.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/recess_ui.dart';
import '../widgets/settings_widgets.dart';

/// Trang giới thiệu nhóm & ứng dụng (About).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Widget _infoRow(String k, String v, {VoidCallback? onTap}) => Tappable(
        pressedScale: 0.99,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(k,
                    style: const TextStyle(
                        color: Ios.label2,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.none)),
              ),
              Expanded(
                child: Text(v,
                    style: const TextStyle(
                        color: Ios.label,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none)),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Giới thiệu nhóm',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 40),
        children: [
          Center(child: const AppLogo(size: 96)),
          const SizedBox(height: 14),
          const Center(
            child: Text(TeamInfo.appName,
                style: TextStyle(
                    color: Ios.label,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Phiên bản ${TeamInfo.version}',
                style: TextStyle(
                    color: Ios.label2, fontSize: 14, decoration: TextDecoration.none)),
          ),
          const SizedBox(height: 10),
          const Text(TeamInfo.tagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Ios.label, fontSize: 15, height: 1.35, decoration: TextDecoration.none)),

          const SectionLabel('Tính năng nổi bật'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: Ios.box(radius: 24),
            child: Column(
              children: [
                for (final f in TeamInfo.features)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2, right: 10),
                          child: Icon(CupertinoIcons.checkmark_alt_circle_fill,
                              size: 18, color: Ios.green),
                        ),
                        Expanded(
                          child: Text(f,
                              style: const TextStyle(
                                  color: Ios.label,
                                  fontSize: 14,
                                  height: 1.3,
                                  decoration: TextDecoration.none)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SectionLabel('Nhóm thực hiện'),
          for (final m in TeamInfo.members)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: Ios.box(radius: 24),
              child: Row(
                children: [
                  AvatarBox(emoji: m.emoji, size: 50),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name,
                            style: const TextStyle(
                                color: Ios.label,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                decoration: TextDecoration.none)),
                        Text('${m.studentId} • ${m.role}',
                            style: const TextStyle(
                                color: Ios.label2,
                                fontSize: 12,
                                height: 1.3,
                                decoration: TextDecoration.none)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SectionLabel('Thông tin dự án'),
          SettingsGroup(
            children: [
              _infoRow('Môn học', TeamInfo.course),
              _infoRow('Mã lớp', TeamInfo.classCode),
              _infoRow('Trường', TeamInfo.university),
              _infoRow('Giảng viên', TeamInfo.teacher),
              _infoRow('GitHub', TeamInfo.github, onTap: () async {
                await Clipboard.setData(const ClipboardData(text: TeamInfo.github));
                Fx.play(Sound.correct);
                if (context.mounted) {
                  showIosAlert(context, 'Đã sao chép', 'Liên kết GitHub đã được sao chép.');
                }
              }),
            ],
          ),

          const SectionLabel('Công nghệ sử dụng'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in TeamInfo.tech)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: Ios.box(radius: 16, fill: Ios.card2),
                  child: Text(t,
                      style: const TextStyle(
                          color: Ios.label,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.none)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text('© 2026 Nhóm Playtime',
                style: TextStyle(
                    color: Ios.label2, fontSize: 12, decoration: TextDecoration.none)),
          ),
        ],
      ),
    );
  }
}
