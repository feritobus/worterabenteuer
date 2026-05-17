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

  // Rough effective study time per mode (mirrors StudySession.estimatedMinutes)
  int get estimatedMinutes {
    const secsPerWord = {
      'flashcard': 12,
      'keyboard': 25,
      'handwriting': 40,
      'voice': 20,
    };
    final secs = (secsPerWord[mode] ?? 20) * wordsAttempted;
    return (secs / 60).ceil().clamp(1, 60);
  }
}
