class SessionResult {
  final int pointsEarned;
  final int wordsAttempted;
  final int wordsCorrect;
  final String mode; // 'flashcard' | 'keyboard' | 'handwriting' | 'voice'
  final String lessonTitle;

  const SessionResult({
    required this.pointsEarned,
    required this.wordsAttempted,
    required this.wordsCorrect,
    required this.mode,
    required this.lessonTitle,
  });

  double get accuracy =>
      wordsAttempted == 0 ? 0 : wordsCorrect / wordsAttempted;
}
