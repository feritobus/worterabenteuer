import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../features/family/domain/models/child_profile.dart';
import '../../features/lessons/domain/models/lesson.dart';
import '../../features/lessons/domain/models/vocab_item.dart';

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
}
