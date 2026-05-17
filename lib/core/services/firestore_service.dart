import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../features/family/domain/models/child_profile.dart';

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

  Future<void> approveScreenTime(String childId, int minutes) async {
    await _childrenRef.doc(childId).update({
      'earnedScreenTimePending': FieldValue.increment(-minutes),
      'earnedScreenTimeApproved': FieldValue.increment(minutes),
    });
  }
}
