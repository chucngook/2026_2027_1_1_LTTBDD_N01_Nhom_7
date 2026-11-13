import '../services/stats_service.dart';

/// Hàm dùng chung cho các game 1 người: hệ số độ khó và lưu điểm cao.
class GameService {
  GameService._();

  static bool isGuest(String username) => false;

  static int multiplier(String difficulty) =>
      difficulty == 'HARD' ? 3 : (difficulty == 'MEDIUM' ? 2 : 1);

  static String diffName(String difficulty) => difficulty == 'HARD'
      ? 'Khó'
      : (difficulty == 'MEDIUM' ? 'Trung bình' : 'Dễ');

  static String guestNote(String username) => '';

  /// Giữ chữ ký cũ cho game 1 người: ghi điểm cao và lịch sử ván chơi.
  static Future<void> reward({
    required String username,
    required int balanceBefore,
    required int amount,
    String? gameId,
    int? score,
  }) async {
    if (gameId != null && score != null && score > 0) {
      await StatsService.instance.submitScore(gameId, score);
      await StatsService.instance.recordMatch(gameId, 'played', mode: 'solo');
    }
  }
}
