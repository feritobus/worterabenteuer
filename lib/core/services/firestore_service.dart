import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../features/family/domain/models/child_profile.dart';
import '../../features/lessons/domain/models/lesson.dart';
import '../../features/lessons/domain/models/vocab_item.dart';
import '../../features/study/domain/models/study_session.dart';

final firestoreServiceProvider =
    Provider<FirestoreService>((ref) => FirestoreService());

final childrenProvider =
    StreamProvider<List<ChildProfile>>((ref) {
  return ref.watch(firestoreServiceProvider).watchChildren();
});

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _familyId => _auth.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> get _childrenRef => _db
      .collection(AppConstants.collFamilies)
      .doc(_familyId)
      .collection(AppConstants.collChildren);

  // ── Niños ──────────────────────────────────────────────

  Stream<List<ChildProfile>> watchChildren() {
    return _childrenRef
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ChildProfile.fromFirestore(doc))
            .toList());
  }

  Future<ChildProfile> createChild(ChildProfile child) async {
    final ref = _childrenRef.doc(child.id);
    await ref.set(child.toFirestore());
    return child;
  }

  Future<void> updateChild(ChildProfile child) async {
    final data = child.toFirestore()..remove('createdAt');
    await _childrenRef.doc(child.id).update(data);
  }

  Future<void> deleteChild(String childId) async {
    await _childrenRef.doc(childId).delete();
  }

  Future<void> updateScreenTimePending(
      String childId, int addMinutes) async {
    await _childrenRef.doc(childId).update({
      'earnedScreenTimePending': FieldValue.increment(addMinutes),
    });
  }

  Future<void> addPoints(String childId, int points) async {
    await _childrenRef.doc(childId).update({
      'totalPoints': FieldValue.increment(points),
    });
  }

  Future<void> approveScreenTime(String childId, int minutes) async {
    await _childrenRef.doc(childId).update({
      'earnedScreenTimePending': FieldValue.increment(-minutes),
      'earnedScreenTimeApproved': FieldValue.increment(minutes),
    });
  }

  // ── Lecciones ───────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _lessonsRef(String childId) =>
      _childrenRef
          .doc(childId)
          .collection(AppConstants.collLessons);

  CollectionReference<Map<String, dynamic>> _vocabRef(
          String childId, String lessonId) =>
      _lessonsRef(childId).doc(lessonId).collection(AppConstants.collVocabulary);

  Stream<List<Lesson>> watchLessons(String childId) {
    return _lessonsRef(childId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Lesson.fromFirestore(doc))
            .toList());
  }

  Future<void> createLesson({
    required String childId,
    required Lesson lesson,
    required List<VocabItem> vocabItems,
  }) async {
    final batch = _db.batch();

    final lessonRef = _lessonsRef(childId).doc(lesson.id);
    batch.set(lessonRef, lesson.toFirestore());

    for (final item in vocabItems) {
      final vocabRef = _vocabRef(childId, lesson.id).doc(item.id);
      batch.set(vocabRef, item.toFirestore());
    }

    await batch.commit();
  }

  Future<List<VocabItem>> getVocabItems(
      String childId, String lessonId) async {
    final snap = await _vocabRef(childId, lessonId)
        .orderBy('order')
        .get();
    return snap.docs.map((doc) => VocabItem.fromFirestore(doc)).toList();
  }

  Future<void> updateLessonStatus(
      String childId, String lessonId, String status) async {
    await _lessonsRef(childId).doc(lessonId).update({'status': status});
  }

  Future<void> updateVocabItem(
      String childId, String lessonId, VocabItem item) async {
    final data = item.toFirestore();
    await _vocabRef(childId, lessonId).doc(item.id).update(data);
  }

  Stream<List<VocabItem>> watchVocabItems(
      String childId, String lessonId) {
    return _vocabRef(childId, lessonId)
        .orderBy('order')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => VocabItem.fromFirestore(doc)).toList());
  }

  // ── Sesiones ────────────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _sessionsRef(String childId) =>
      _childrenRef.doc(childId).collection(AppConstants.collSessions);

  // ── Lesson progression ──────────────────────────────────────────────────────

  // Call when a word is dominated for the first time. Increments wordsDominated
  // and transitions lesson to 'in_progress'; checks for full completion.
  Future<void> dominateWord(
      String childId, String lessonId, VocabItem item) async {
    final batch = _db.batch();
    batch.update(_vocabRef(childId, lessonId).doc(item.id), item.toFirestore());
    batch.update(_lessonsRef(childId).doc(lessonId), {
      'wordsDominated': FieldValue.increment(1),
      'status': 'in_progress',
    });
    await batch.commit();
    await _checkLessonCompletion(childId, lessonId);
  }

  Future<void> _checkLessonCompletion(
      String childId, String lessonId) async {
    final doc = await _lessonsRef(childId).doc(lessonId).get();
    final d = doc.data();
    if (d == null) return;
    final total = d['wordsTotal'] as int? ?? 0;
    final dominated = d['wordsDominated'] as int? ?? 0;
    final alreadyPerfect = (d['status'] as String?) == 'perfect';
    if (!alreadyPerfect && total > 0 && dominated >= total) {
      await _lessonsRef(childId)
          .doc(lessonId)
          .update({'status': 'completed'});
    }
  }

  // Sets perfectRoundCompleted + extraVocabUnlocked + status='perfect'.
  Future<void> setPerfectRound(String childId, String lessonId) async {
    await _lessonsRef(childId).doc(lessonId).update({
      'perfectRoundCompleted': true,
      'extraVocabUnlocked': true,
      'status': 'perfect',
    });
  }

  // Adds extra vocab words to an existing lesson (batch write).
  Future<void> addExtraVocabToLesson({
    required String childId,
    required String lessonId,
    required List<VocabItem> items,
    required int currentWordsTotal,
  }) async {
    final batch = _db.batch();
    for (int i = 0; i < items.length; i++) {
      items[i].order = currentWordsTotal + i;
      final ref = _vocabRef(childId, lessonId).doc(items[i].id);
      batch.set(ref, items[i].toFirestore());
    }
    batch.update(_lessonsRef(childId).doc(lessonId), {
      'wordsTotal': FieldValue.increment(items.length),
    });
    await batch.commit();
  }

  Future<void> recordSession(StudySession session) async {
    await _sessionsRef(session.childId).doc(session.id).set(session.toFirestore());

    // Read child to compute streak update
    final childDoc = await _childrenRef.doc(session.childId).get();
    final data = childDoc.data();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActiveTs = data?['lastActiveDate'] as Timestamp?;
    final lastDay = lastActiveTs != null
        ? DateTime(lastActiveTs.toDate().year, lastActiveTs.toDate().month,
            lastActiveTs.toDate().day)
        : null;

    int streak = data?['currentStreak'] as int? ?? 0;
    int longest = data?['longestStreak'] as int? ?? 0;

    final update = <String, dynamic>{
      'effectiveTimeMinutesWeek': FieldValue.increment(session.estimatedMinutes),
      'effectiveTimeMinutesTotal': FieldValue.increment(session.estimatedMinutes),
    };

    if (lastDay == null || lastDay.isBefore(today.subtract(const Duration(days: 1)))) {
      // No prior session or streak broken
      streak = 1;
      update['currentStreak'] = 1;
      update['lastActiveDate'] = Timestamp.fromDate(today);
    } else if (lastDay == today.subtract(const Duration(days: 1))) {
      // Consecutive day
      streak++;
      update['currentStreak'] = streak;
      update['lastActiveDate'] = Timestamp.fromDate(today);
    }
    // lastDay == today → already counted today, skip streak update

    if (streak > longest) update['longestStreak'] = streak;

    await _childrenRef.doc(session.childId).update(update);
  }

  Future<List<StudySession>> getSessionsThisWeek(String childId) async {
    final since = DateTime.now().subtract(const Duration(days: 7));
    final snap = await _sessionsRef(childId)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .orderBy('completedAt', descending: true)
        .get();
    return snap.docs
        .map((doc) => StudySession.fromFirestore(doc))
        .toList();
  }
}
