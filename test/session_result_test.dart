import 'package:flutter_test/flutter_test.dart';
import 'package:worterabenteuer/features/study/domain/models/session_result.dart';

void main() {
  group('SessionResult.accuracy', () {
    test('returns 0 when no words attempted', () {
      final r = SessionResult(
        pointsEarned: 0,
        wordsAttempted: 0,
        wordsCorrect: 0,
        mode: 'flashcard',
        lessonTitle: '',
      );
      expect(r.accuracy, 0);
    });

    test('returns 1.0 on perfect run', () {
      final r = SessionResult(
        pointsEarned: 7,
        wordsAttempted: 5,
        wordsCorrect: 5,
        mode: 'handwriting',
        lessonTitle: '',
      );
      expect(r.accuracy, 1.0);
    });

    test('returns ratio for partial', () {
      final r = SessionResult(
        pointsEarned: 4,
        wordsAttempted: 4,
        wordsCorrect: 3,
        mode: 'keyboard',
        lessonTitle: '',
      );
      expect(r.accuracy, 0.75);
    });
  });

  group('SessionResult.estimatedMinutes', () {
    SessionResult make(String mode, int words) => SessionResult(
          pointsEarned: 0,
          wordsAttempted: words,
          wordsCorrect: 0,
          mode: mode,
          lessonTitle: '',
        );

    test('flashcard: 12s per word, ceil to min, clamp >=1', () {
      // 1 word * 12s = 12s → ceil(12/60) = 1 min
      expect(make('flashcard', 1).estimatedMinutes, 1);
      // 5 words * 12s = 60s → 1 min
      expect(make('flashcard', 5).estimatedMinutes, 1);
      // 6 words * 12s = 72s → ceil(1.2) = 2 min
      expect(make('flashcard', 6).estimatedMinutes, 2);
    });

    test('keyboard: 25s per word', () {
      // 3 words * 25s = 75s → 2 min
      expect(make('keyboard', 3).estimatedMinutes, 2);
    });

    test('handwriting: 40s per word', () {
      // 5 words * 40s = 200s → ceil(3.33) = 4 min
      expect(make('handwriting', 5).estimatedMinutes, 4);
    });

    test('voice: 20s per word', () {
      // 9 words * 20s = 180s → 3 min
      expect(make('voice', 9).estimatedMinutes, 3);
    });

    test('unknown mode falls back to 20s', () {
      expect(make('unknown', 3).estimatedMinutes, 1); // 60s → 1
    });

    test('clamped to 60 max', () {
      // 200 handwritten words = 8000s = 134min → clamped to 60
      expect(make('handwriting', 200).estimatedMinutes, 60);
    });

    test('minimum 1 minute even for tiny sessions', () {
      // 0 words → 0s → ceil(0)=0 → clamp(1) = 1
      expect(make('flashcard', 0).estimatedMinutes, 1);
    });
  });
}
