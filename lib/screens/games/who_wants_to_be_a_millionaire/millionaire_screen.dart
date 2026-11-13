import 'package:flutter/cupertino.dart' hide Text;
import '../../../widgets/tr_text.dart';
import '../../../services/fx.dart';
import '../../../data/game_service.dart';
import '../../../theme/ios_theme.dart';
import '../../../widgets/difficulty_selector_screen.dart';
import '../../../widgets/ios_widgets.dart';

class MillionaireScreen extends StatefulWidget {
  final String username;
  final int currentTokens;

  const MillionaireScreen(
      {super.key, required this.username, required this.currentTokens});

  @override
  State<MillionaireScreen> createState() => _MillionaireScreenState();
}

class _Question {
  final String text;
  final List<String> options;
  final int answer;
  _Question(this.text, this.options, this.answer);
}

class _MillionaireScreenState extends State<MillionaireScreen> {
  static const List<int> _milestones = [100, 200, 500, 1000, 2000];

  // Phần tử đầu tiên của 'a' luôn là đáp án đúng (sẽ được xáo trộn khi chơi)
  static const List<Map<String, Object>> _bank = [
    {'q': 'Thủ đô của nước Việt Nam là gì?', 'a': ['Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng']},
    {'q': 'Ngôn ngữ lập trình chính dùng cho Flutter là gì?', 'a': ['Dart', 'Java', 'Python', 'C++']},
    {'q': 'Hành tinh nào gần Mặt Trời nhất?', 'a': ['Sao Thủy', 'Sao Kim', 'Trái Đất', 'Sao Hỏa']},
    {'q': 'Đại dương nào lớn nhất thế giới?', 'a': ['Thái Bình Dương', 'Đại Tây Dương', 'Ấn Độ Dương', 'Bắc Băng Dương']},
    {'q': 'Cơ sở dữ liệu cục bộ phổ biến trong Flutter là gì?', 'a': ['SQLite', 'MongoDB', 'Oracle', 'PostgreSQL']},
    {'q': 'Vịnh Hạ Long thuộc tỉnh nào?', 'a': ['Quảng Ninh', 'Hải Phòng', 'Thanh Hóa', 'Nghệ An']},
    {'q': 'Quốc gia nào có diện tích lớn nhất thế giới?', 'a': ['Nga', 'Canada', 'Trung Quốc', 'Hoa Kỳ']},
    {'q': '1 byte bằng bao nhiêu bit?', 'a': ['8', '4', '16', '2']},
    {'q': 'Nguyên tố hóa học có ký hiệu "O" là gì?', 'a': ['Oxy', 'Vàng', 'Bạc', 'Osmi']},
    {'q': 'Tác giả của "Truyện Kiều" là ai?', 'a': ['Nguyễn Du', 'Nguyễn Trãi', 'Hồ Xuân Hương', 'Nguyễn Đình Chiểu']},
    {'q': 'Hệ điều hành iOS do công ty nào phát triển?', 'a': ['Apple', 'Google', 'Microsoft', 'Samsung']},
    {'q': 'Thủ đô của Nhật Bản là thành phố nào?', 'a': ['Tokyo', 'Kyoto', 'Osaka', 'Nagoya']},
  ];

  bool _isStarted = false;
  String _difficulty = 'EASY';

  List<_Question> _qs = [];
  int _index = 0;
  bool _used5050 = false;
  List<int> _hidden = [];
  bool _answered = false;
  bool _finished = false;
  int? _selected;
  int _gen = 0;

  void _startGame(String diff) {
    final picked = [..._bank]..shuffle();
    final qs = picked.take(5).map((m) {
      final opts = List<String>.from(m['a'] as List);
      final correct = opts.first;
      opts.shuffle();
      return _Question(m['q'] as String, opts, opts.indexOf(correct));
    }).toList();

    setState(() {
      _difficulty = diff;
      _qs = qs;
      _index = 0;
      _used5050 = false;
      _hidden = [];
      _answered = false;
      _finished = false;
      _selected = null;
      _gen++;
      _isStarted = true;
    });
  }

  Future<void> _select(int i) async {
    if (_answered || _finished) return;
    Fx.medium(); Fx.play(Sound.tap);
    final gen = _gen;
    setState(() {
      _answered = true;
      _selected = i;
    });

    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted || gen != _gen) return;

    if (i == _qs[_index].answer) {
      Fx.play(Sound.correct);
      if (_index < _qs.length - 1) {
        setState(() {
          _index++;
          _answered = false;
          _selected = null;
          _hidden = [];
        });
      } else {
        _finish(_milestones.last, 'Xuất sắc! Bạn đã vượt qua mọi câu hỏi.');
      }
    } else {
      Fx.play(Sound.wrong);
      final safe = _index >= 3 ? _milestones[2] : 0;
      _finish(safe, 'Trả lời sai! Bạn giữ mốc an toàn: $safe điểm.');
    }
  }

  void _use5050() {
    if (_used5050 || _answered) return;
    Fx.heavy(); Fx.play(Sound.tap);
    final correct = _qs[_index].answer;
    final wrongs = [
      for (var i = 0; i < 4; i++)
        if (i != correct) i
    ]..shuffle();
    setState(() {
      _used5050 = true;
      _hidden = [wrongs[0], wrongs[1]];
    });
  }

  void _confirmWalkAway() {
    if (_answered) return;
    final bank = _index == 0 ? 0 : _milestones[_index - 1];
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Dừng cuộc chơi?'),
        content: Text('Bạn sẽ nhận $bank điểm (chưa nhân độ khó).'),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tiếp tục')),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _finish(bank, 'Bạn đã dừng cuộc chơi.');
            },
            child: const Text('Dừng & nhận'),
          ),
        ],
      ),
    );
  }

  Future<void> _finish(int base, String msg) async {
    if (_finished) return;
    _finished = true;
    Fx.play(base > 0 ? Sound.win : Sound.lose);
    final mult = GameService.multiplier(_difficulty);
    final total = base * mult;

    await GameService.reward(
      username: widget.username,
      balanceBefore: widget.currentTokens,
      amount: total,
      gameId: 'millionaire',
      score: total,
    );
    if (!mounted) return;

    await showRoundResult(
      context,
      title: 'Kết quả',
      message:
          '$msg\nĐộ khó: ${GameService.diffName(_difficulty)} (×$mult)\nTổng điểm: +$total điểm${GameService.guestNote(widget.username)}',
    );
    if (!mounted) return;
    Navigator.of(context).pop(total);
  }

  Widget _ladder() {
    return Row(
      children: List.generate(_milestones.length, (i) {
        final done = i < _index;
        final current = i == _index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == _milestones.length - 1 ? 0 : 6),
            child: Column(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: done
                        ? Ios.green
                        : (current ? Ios.amber : Ios.card3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text('${_milestones[i]}',
                    style: TextStyle(
                        color: current ? Ios.amber : Ios.label2,
                        fontSize: 11,
                        fontWeight:
                            current ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _option(int i) {
    final q = _qs[_index];
    final hidden = _hidden.contains(i);
    Color bg = Ios.card;
    Color border = Ios.separator;
    if (_answered) {
      if (i == q.answer) {
        bg = Ios.green.op(0.18);
        border = Ios.green;
      } else if (i == _selected) {
        bg = Ios.red.op(0.18);
        border = Ios.red;
      }
    }
    return AnimatedOpacity(
      opacity: hidden ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: hidden,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Tappable(
            onTap: () => _select(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border, width: 1.2),
                boxShadow: _answered ? null : Ios.shadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                        color: Ios.card2, shape: BoxShape.circle),
                    child: Text(['A', 'B', 'C', 'D'][i],
                        style: const TextStyle(
                            color: Ios.amber, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(q.options[i],
                        style: const TextStyle(
                            color: Ios.label,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isStarted) {
      return DifficultySelectorScreen(
        gameTitle: 'Ai Là Triệu Phú',
        gameId: 'millionaire',
        gameDescription:
            'Trả lời 5 câu hỏi liên tiếp. Độ khó càng cao, tiền thưởng nhân lên càng lớn!',
        onPlayPressed: _startGame,
      );
    }

    final q = _qs[_index];
    return GameScaffold(
      title: 'Triệu Phú • ${GameService.diffName(_difficulty)}',
      onBack: () {
        _gen++;
        setState(() => _isStarted = false);
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _ladder(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: _used5050 ? Ios.card2 : Ios.blue,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _used5050 ? null : _use5050,
                    child: Text(_used5050 ? 'Đã dùng 50:50' : '50 : 50',
                        style: TextStyle(
                            color: _used5050
                                ? Ios.label2
                                : CupertinoColors.white,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    color: Ios.card2,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: _answered ? null : _confirmWalkAway,
                    child: const Text('Dừng cuộc chơi',
                        style: TextStyle(
                            color: Ios.red, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text('Câu ${_index + 1}/${_qs.length} • ${_milestones[_index]} điểm',
                      style: TextStyle(
                          color: CupertinoColors.white.op(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(q.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          height: 1.3)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: List.generate(4, _option),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
