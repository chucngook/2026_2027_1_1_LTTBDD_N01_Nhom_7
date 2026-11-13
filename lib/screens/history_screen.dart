import 'package:flutter/cupertino.dart' hide Text;
import '../widgets/tr_text.dart';
import '../constants/app_assets.dart';
import '../services/stats_service.dart';
import '../theme/ios_theme.dart';
import '../widgets/app_images.dart';
import '../widgets/page_scaffold.dart';

/// Lịch sử các ván đã chơi (đọc từ bảng matches trong SQLite).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, Object?>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await StatsService.instance.recent();
    if (!mounted) return;
    setState(() {
      _rows = r;
      _loading = false;
    });
  }

  String _time(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}  ${two(d.day)}/${two(d.month)}';
  }

  void _confirmClear() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Xóa lịch sử?'),
        content: const Text('Toàn bộ ván đã chơi sẽ bị xóa khỏi máy.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
              await StatsService.instance.clearHistory();
              _load();
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = {
      for (final g in AppAssets.getAllGamesWithAssets()) g['id'] as String: g
    };
    return PageScaffold(
      title: 'Ván đã chơi',
      trailing: _rows.isEmpty
          ? null
          : CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _confirmClear,
              child: const Icon(CupertinoIcons.trash, color: Ios.label, size: 22),
            ),
      child: _loading
          ? const Center(child: CupertinoActivityIndicator(radius: 14))
          : _rows.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('Chưa có ván nào. Hãy chơi thử một game nhé!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Ios.label2, fontSize: 16, decoration: TextDecoration.none)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(18),
                  itemCount: _rows.length,
                  itemBuilder: (_, i) {
                    final r = _rows[i];
                    final g = games[r['game_id']];
                    final res = r['result'] as String;
                    final label = res == 'win'
                        ? 'Thắng'
                        : (res == 'loss' ? 'Thua' : (res == 'draw' ? 'Hòa' : 'Đã chơi'));
                    final color = res == 'win'
                        ? Ios.green
                        : (res == 'loss' ? Ios.red : (res == 'draw' ? Ios.yellow : Ios.blue));
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: Ios.box(radius: 22),
                      child: Row(
                        children: [
                          if (g != null)
                            SquircleImage(path: g['image'] as String, size: 44, shadow: false),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(g != null ? g['name'] as String : '${r['game_id']}',
                                    style: const TextStyle(
                                        color: Ios.label,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.none)),
                                Text(_time(r['played_at'] as int),
                                    style: const TextStyle(
                                        color: Ios.label2,
                                        fontSize: 12,
                                        decoration: TextDecoration.none)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                                color: color.op(0.25), borderRadius: BorderRadius.circular(12)),
                            child: Text(label,
                                style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.none)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
