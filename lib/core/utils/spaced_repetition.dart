class SpacedRepetitionHelper {
  /// Calculates the next review date based on consecutive correct answers.
  /// Schedule:
  /// - 0 correct (or wrong answer reset): 1 day
  /// - 1 correct: 3 days
  /// - 2 or more correct: 7 days (Graduated to Mastered)
  static DateTime calculateNextReview({
    required int consecutiveCorrect,
    required bool isAnswerCorrect,
  }) {
    final now = DateTime.now();

    if (!isAnswerCorrect) {
      // Wrong answer resets to review tomorrow
      return now.add(const Duration(days: 1));
    }

    if (consecutiveCorrect == 0) {
      // First correct answer -> schedule in 3 days
      return now.add(const Duration(days: 3));
    } else {
      // Second or subsequent correct answer -> schedule in 7 days
      return now.add(const Duration(days: 7));
    }
  }

  /// Evaluates status: 'learning' | 'review' | 'mastered'
  static String calculateStatus({
    required int consecutiveCorrect,
    required bool isAnswerCorrect,
  }) {
    if (!isAnswerCorrect) {
      return 'review';
    }
    if (consecutiveCorrect >= 1) {
      return 'mastered';
    }
    return 'review';
  }

  /// Calculates mastery percentage (0.0 to 1.0)
  static double calculateCategoryMastery({
    required int totalCategoryConcepts,
    required int masteredCount,
  }) {
    if (totalCategoryConcepts <= 0) return 0.0;
    final ratio = masteredCount / totalCategoryConcepts;
    return ratio.clamp(0.0, 1.0);
  }
}
