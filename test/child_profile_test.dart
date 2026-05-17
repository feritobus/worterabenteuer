import 'package:flutter_test/flutter_test.dart';
import 'package:worterabenteuer/features/family/domain/models/child_profile.dart';

void main() {
  group('ChildProfile.suggestedLevel', () {
    test('A1 for ages 7-10', () {
      for (final age in [7, 8, 9, 10]) {
        expect(ChildProfile.suggestedLevel(age), 'A1', reason: 'age $age');
      }
    });

    test('A2 for ages 11-12', () {
      for (final age in [11, 12]) {
        expect(ChildProfile.suggestedLevel(age), 'A2', reason: 'age $age');
      }
    });
  });

  group('ChildProfile defaults', () {
    test('all progress counters default to zero', () {
      final c = ChildProfile(
        id: 'x',
        name: 'Test',
        avatar: '🦊',
        age: 9,
        level: 'A1',
      );
      expect(c.totalPoints, 0);
      expect(c.effectiveTimeMinutesWeek, 0);
      expect(c.effectiveTimeMinutesTotal, 0);
      expect(c.currentStreak, 0);
      expect(c.longestStreak, 0);
      expect(c.earnedScreenTimePending, 0);
      expect(c.earnedScreenTimeApproved, 0);
      expect(c.lastActiveDate, isNull);
    });
  });
}
