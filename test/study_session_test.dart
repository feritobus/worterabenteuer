import 'package:flutter_test/flutter_test.dart';
import 'package:worterabenteuer/features/study/domain/models/study_session.dart';

void main() {
  StudySession make({
    required String mode,
    required int wordsAttempted,
    int wordsCorrect = 0,
  }) =>
      StudySession(
        id: 'test',
        childId: 'child',
        lessonId: 'lesson',
        lessonTitle: 'Test',
        mode: mode,
        pointsEarned: 0,
        wordsAttempted: wordsAttempted,
        wordsCorrect: wordsCorrect,
        completedAt: DateTime(2026, 5, 17),
      );

  group('StudySession.accuracy', () {
    test('zero attempts → 0', () {
      expect(make(mode: 'flashcard', wordsAttempted: 0).accuracy, 0);
    });

    test('matches wordsCorrect/wordsAttempted', () {
      expect(
        make(mode: 'voice', wordsAttempted: 4, wordsCorrect: 2).accuracy,
        0.5,
      );
    });
  });

  group('StudySession.estimatedMinutes', () {
    test('mirrors SessionResult.estimatedMinutes table', () {
      expect(make(mode: 'flashcard', wordsAttempted: 6).estimatedMinutes, 2);
      expect(make(mode: 'keyboard', wordsAttempted: 3).estimatedMinutes, 2);
      expect(make(mode: 'handwriting', wordsAttempted: 5).estimatedMinutes, 4);
      expect(make(mode: 'voice', wordsAttempted: 9).estimatedMinutes, 3);
    });

    test('clamped to [1, 60]', () {
      expect(make(mode: 'handwriting', wordsAttempted: 200).estimatedMinutes, 60);
      expect(make(mode: 'flashcard', wordsAttempted: 0).estimatedMinutes, 1);
    });
  });

  group('StudySession.create', () {
    test('generates a non-empty UUID and sets completedAt to now', () {
      final before = DateTime.now();
      final s = StudySession.create(
        childId: 'c1',
        lessonId: 'l1',
        lessonTitle: 'My lesson',
        mode: 'voice',
        pointsEarned: 7,
        wordsAttempted: 5,
        wordsCorrect: 5,
      );
      final after = DateTime.now();
      expect(s.id, isNotEmpty);
      expect(s.id.length, greaterThan(20));
      expect(
        s.completedAt.isAfter(before.subtract(const Duration(seconds: 1))) &&
            s.completedAt
                .isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
      );
    });
  });
}
