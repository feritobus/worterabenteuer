import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'child_profile.g.dart';

@HiveType(typeId: 0)
class ChildProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String avatar;

  @HiveField(3)
  int age;

  @HiveField(4)
  String level;

  @HiveField(5)
  int totalPoints;

  @HiveField(6)
  int effectiveTimeMinutesWeek;

  @HiveField(7)
  int effectiveTimeMinutesTotal;

  @HiveField(8)
  int currentStreak;

  @HiveField(9)
  int longestStreak;

  @HiveField(10)
  int earnedScreenTimePending;

  @HiveField(11)
  int earnedScreenTimeApproved;

  @HiveField(12)
  DateTime? lastActiveDate;

  @HiveField(13)
  String? colorScheme;

  ChildProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.age,
    required this.level,
    this.totalPoints = 0,
    this.effectiveTimeMinutesWeek = 0,
    this.effectiveTimeMinutesTotal = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.earnedScreenTimePending = 0,
    this.earnedScreenTimeApproved = 0,
    this.lastActiveDate,
    this.colorScheme,
  });

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'avatar': avatar,
        'age': age,
        'level': level,
        'totalPoints': totalPoints,
        'effectiveTimeMinutesWeek': effectiveTimeMinutesWeek,
        'effectiveTimeMinutesTotal': effectiveTimeMinutesTotal,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'earnedScreenTimePending': earnedScreenTimePending,
        'earnedScreenTimeApproved': earnedScreenTimeApproved,
        'lastActiveDate':
            lastActiveDate != null ? Timestamp.fromDate(lastActiveDate!) : null,
        'colorScheme': colorScheme,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory ChildProfile.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ChildProfile(
      id: doc.id,
      name: d['name'] as String? ?? '',
      avatar: d['avatar'] as String? ?? '🦊',
      age: d['age'] as int? ?? 7,
      level: d['level'] as String? ?? 'A1',
      totalPoints: d['totalPoints'] as int? ?? 0,
      effectiveTimeMinutesWeek: d['effectiveTimeMinutesWeek'] as int? ?? 0,
      effectiveTimeMinutesTotal: d['effectiveTimeMinutesTotal'] as int? ?? 0,
      currentStreak: d['currentStreak'] as int? ?? 0,
      longestStreak: d['longestStreak'] as int? ?? 0,
      earnedScreenTimePending: d['earnedScreenTimePending'] as int? ?? 0,
      earnedScreenTimeApproved: d['earnedScreenTimeApproved'] as int? ?? 0,
      lastActiveDate:
          (d['lastActiveDate'] as Timestamp?)?.toDate(),
      colorScheme: d['colorScheme'] as String?,
    );
  }

  // Nivel sugerido por edad
  static String suggestedLevel(int age) => age <= 10 ? 'A1' : 'A2';
}
