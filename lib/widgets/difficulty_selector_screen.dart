import 'package:flutter/cupertino.dart' hide Text;
import 'tr_text.dart';
import '../services/fx.dart';
import '../theme/ios_theme.dart';
import '../constants/app_assets.dart';
import 'app_images.dart';
import 'ios_widgets.dart';

/// Màn hình chọn độ khó dùng chung cho các game (giao diện sáng kiểu iOS).
class DifficultySelectorScreen extends StatefulWidget {
  final String gameTitle;
  final String gameDescription;
  final String gameId; // dùng để lấy ảnh icon game
  final void Function(String difficulty) onPlayPressed;

  const DifficultySelectorScreen({
    super.key,
    required this.gameTitle,
    required this.gameDescription,
    required this.gameId,
    required this.onPlayPressed,
  });

  @override
  State<DifficultySelectorScreen> createState() =>
      _DifficultySelectorScreenState();
}

class _DifficultySelectorScreenState extends State<DifficultySelectorScreen> {
  String _difficulty = 'EASY';

  Color get _color => _difficulty == 'EASY'
      ? Ios.green
      : (_difficulty == 'MEDIUM' ? Ios.orange : Ios.red);

  IconData get _icon => _difficulty == 'EASY'
      ? CupertinoIcons.smiley_fill
      : (_difficulty == 'MEDIUM'
          ? CupertinoIcons.bolt_fill
          : CupertinoIcons.flame_fill);

  String get _name => _difficulty == 'EASY'
      ? 'Dễ'
      : (_difficulty == 'MEDIUM' ? 'Trung bình' : 'Khó');

  Color get _glow {
    final g = AppAssets.getAllGamesWithAssets()
        .where((e) => e['id'] == widget.gameId)
        .toList();
    if (g.isEmpty) return Ios.accent;
    return List<Color>.from(g.first['colors'] as List).first;
  }

  int get _mult => _difficulty == 'EASY' ? 1 : (_difficulty == 'MEDIUM' ? 2 : 3);

  void _showHelp() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hướng dẫn'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
              'Chọn độ khó bằng thanh phân đoạn. Độ khó càng cao, điểm khi chiến thắng càng được nhân lớn (×1, ×2, ×3).'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Ios.bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: Ios.bg.op(0.92),
        border: null,
        middle: Text(widget.gameTitle,
            style: const TextStyle(
                color: Ios.label, fontWeight: FontWeight.w600)),
        leading: CupertinoNavigationBarBackButton(
          color: Ios.accent,
          previousPageTitle: 'Quay lại',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showHelp,
          child: const Icon(CupertinoIcons.question_circle,
              color: Ios.accent, size: 24),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              SizedBox(
                width: 230,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                            colors: [_glow.op(0.38), _glow.op(0)]),
                      ),
                    ),
                    GameIcon(gameId: widget.gameId, size: 136),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(widget.gameTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Ios.label,
                      fontSize: 28,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(widget.gameDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Ios.label2, fontSize: 15, height: 1.4)),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<String>(
                  groupValue: _difficulty,
                  backgroundColor: Ios.card,
                  thumbColor: _color,
                  padding: const EdgeInsets.all(3),
                  children: {
                    'EASY': segmentLabel('Dễ', _difficulty == 'EASY'),
                    'MEDIUM': segmentLabel('Vừa', _difficulty == 'MEDIUM'),
                    'HARD': segmentLabel('Khó', _difficulty == 'HARD'),
                  },
                  onValueChanged: (v) {
                    if (v == null) return;
                    Fx.select();
                    setState(() => _difficulty = v);
                  },
                ),
              ),
              const SizedBox(height: 16),

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Ios.card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Ios.border, width: 2.5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration:
                          BoxDecoration(color: _color, shape: BoxShape.circle),
                      child: Icon(_icon, color: CupertinoColors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Độ khó: $_name',
                              style: const TextStyle(
                                  color: Ios.label,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          const Text('Hệ số điểm thưởng',
                              style:
                                  TextStyle(color: Ios.label2, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text('×$_mult',
                        style: TextStyle(
                            color: _color,
                            fontSize: 28,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              IosButton(
                label: 'Chơi ngay',
                icon: CupertinoIcons.play_fill,
                color: _color,
                onPressed: () {
                  Fx.play(Sound.tap);
                  widget.onPlayPressed(_difficulty);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
