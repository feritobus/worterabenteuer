import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class StudySession {
  final String id;
  final String childId;
  final String lessonId;
  final String lessonTitle;
  final String mode; // flashcard | keyboard | handwriting | voice
  final int pointsEarned;
  final int wordsAttempted;
  final int wordsCorrect;
  final DateTime completedAt;

  StudySession({
    required this.id,
    required this.childId,
    required this.lessonId,
    required this.lessonTitle,
    required this.mode,
    required this.pointsEarned,
    required this.wordsAttempted,
    required this.wordsCorrect,
    required this.completedAt,
  });

  factory StudySession.create({
    required String childId,
    required String lessonId,
    required String lessonTitle,
    required String mode,
    required int pointsEarned,
    required int wordsAttempted,
    required int wordsCorrect,
  }) {
    return StudySession(
      id: const Uuid().v4(),
      childId: childId,
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      mode: mode,
      pointsEarned: pointsEarned,
      wordsAttempted: wordsAttempted,
      wordsCorrect: wordsCorrect,
      completedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'childId': childId,
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        'mode': mode,
        'pointsEarned': pointsEarned,
        'wordsAttempted': wordsAttempted,
        'wordsCorrect': wordsCorrect,
        'completedAt': Timestamp.fromDate(completedAt),
      };

  factory StudySession.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return StudySession(
      id: doc.id,
      childId: d['childId'] as String? ?? '',
      lessonId: d['lessonId'] as String? ?? '',
      lessonTitle: d['lessonTitle'] as String? ?? '',
      mode: d['mode'] as String? ?? 'flashcard',
      pointsEarned: d['pointsEarned'] as int? ?? 0,
      wordsAttempted: d['wordsAttempted'] as int? ?? 0,
      wordsCorrect: d['wordsCorrect'] as int? ?? 0,
      completedAt: (d['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  double get accuracy =>
      wordsAttempted == 0 ? 0 : wordsCorrect / wordsAttempted;

  // Rough effective study time: based on mode and words attempted
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
