import 'package:flutter_test/flutter_test.dart';
import 'package:worterabenteuer/core/constants/app_constants.dart';

void main() {
  group('Point values match the schema', () {
    test('canonical point rewards', () {
      expect(AppConstants.pointsFlashCard, 1);
      expect(AppConstants.pointsTyped, 2);
      expect(AppConstants.pointsHandwritten, 7);
      expect(AppConstants.pointsVoice, 7);
      expect(AppConstants.pointsPerfectRound, 20);
    });

    test('handwriting > keyboard > flashcard (skill ordering)', () {
      expect(AppConstants.pointsHandwritten,
          greaterThan(AppConstants.pointsTyped));
      expect(AppConstants.pointsTyped,
          greaterThan(AppConstants.pointsFlashCard));
    });

    test('voice == handwriting (both peak modes)', () {
      expect(AppConstants.pointsVoice, AppConstants.pointsHandwritten);
    });
  });

  group('Screen-time rules', () {
    test('1 effective minute = 2.5 minutes of screen time', () {
      expect(AppConstants.screenTimeRatio, 2.5);
    });
  });

  group('Handwriting tolerance by age', () {
    test('younger kids get more error tolerance', () {
      final young = AppConstants.handwritingToleranceByAge['young']!;
      final middle = AppConstants.handwritingToleranceByAge['middle']!;
      final older = AppConstants.handwritingToleranceByAge['older']!;
      expect(young, greaterThanOrEqualTo(middle));
      expect(middle, greaterThanOrEqualTo(older));
      expect(older, 0); // 11-12yo expected to be exact
    });
  });

  group('Age bounds', () {
    test('target ages 7-12', () {
      expect(AppConstants.minAge, 7);
      expect(AppConstants.maxAge, 12);
    });
  });

  group('Avatars', () {
    test('at least 12 avatar options', () {
      expect(AppConstants.avatarEmojis.length, greaterThanOrEqualTo(12));
    });

    test('no duplicate avatars', () {
      final set = AppConstants.avatarEmojis.toSet();
      expect(set.length, AppConstants.avatarEmojis.length);
    });
  });
}
