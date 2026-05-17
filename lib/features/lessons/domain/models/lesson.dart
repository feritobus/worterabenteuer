import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'lesson.g.dart';

@HiveType(typeId: 1)
class Lesson extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String titleSpanish;

  @HiveField(3)
  String source; // 'paul_lisa_co' | 'dabei' | 'custom_sheet' | 'anton'

  @HiveField(4)
  String level; // 'A1' | 'A2'

  @HiveField(5)
  String status; // 'assigned' | 'in_progress' | 'completed' | 'perfect'

  @HiveField(6)
  int wordsTotal;

  @HiveField(7)
  int wordsDominated;

  @HiveField(8)
  int wordsWithVoiceBonus;

  @HiveField(9)
  bool perfectRoundCompleted;

  @HiveField(10)
  bool extraVocabUnlocked;

  @HiveField(11)
  DateTime? assignedAt;

  @HiveField(12)
  DateTime? completedAt;

  @HiveField(13)
  String childId;

  Lesson({
    required this.id,
    required this.title,
    required this.titleSpanish,
    required this.source,
    required this.level,
    required this.childId,
    this.status = 'assigned',
    this.wordsTotal = 0,
    this.wordsDominated = 0,
    this.wordsWithVoiceBonus = 0,
    this.perfectRoundCompleted = false,
    this.extraVocabUnlocked = false,
    this.assignedAt,
    this.completedAt,
  });

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'titleSpanish': titleSpanish,
        'source': source,
        'level': level,
        'status': status,
        'wordsTotal': wordsTotal,
        'wordsDominated': wordsDominated,
        'wordsWithVoiceBonus': wordsWithVoiceBonus,
        'perfectRoundCompleted': perfectRoundCompleted,
        'extraVocabUnlocked': extraVocabUnlocked,
        'assignedAt': assignedAt != null
            ? Timestamp.fromDate(assignedAt!)
            : FieldValue.serverTimestamp(),
        'completedAt':
            completedAt != null ? Timestamp.fromDate(completedAt!) : null,
        'childId': childId,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Lesson.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Lesson(
      id: doc.id,
      title: d['title'] as String? ?? '',
      titleSpanish: d['titleSpanish'] as String? ?? '',
      source: d['source'] as String? ?? 'custom_sheet',
      level: d['level'] as String? ?? 'A1',
      childId: d['childId'] as String? ?? '',
      status: d['status'] as String? ?? 'assigned',
      wordsTotal: d['wordsTotal'] as int? ?? 0,
      wordsDominated: d['wordsDominated'] as int? ?? 0,
      wordsWithVoiceBonus: d['wordsWithVoiceBonus'] as int? ?? 0,
      perfectRoundCompleted: d['perfectRoundCompleted'] as bool? ?? false,
      extraVocabUnlocked: d['extraVocabUnlocked'] as bool? ?? false,
      assignedAt: (d['assignedAt'] as Timestamp?)?.toDate(),
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isAssigned => status == 'assigned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted =>
      status == 'completed' || status == 'perfect';
  bool get isPerfect => status == 'perfect';
}
