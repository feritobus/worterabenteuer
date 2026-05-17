import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../family/domain/models/child_profile.dart';
import '../../domain/models/lesson.dart';
import '../../domain/models/vocab_item.dart';

// Niño activo durante la sesión de estudio
final selectedChildProvider = StateProvider<ChildProfile?>((ref) => null);

// Lección seleccionada para estudiar
final selectedLessonProvider = StateProvider<Lesson?>((ref) => null);

// Lecciones del niño activo
final childLessonsProvider = StreamProvider<List<Lesson>>((ref) {
  final child = ref.watch(selectedChildProvider);
  if (child == null) return const Stream.empty();
  return ref.watch(firestoreServiceProvider).watchLessons(child.id);
});

// Vocabulario de la lección activa (carga una vez por sesión)
final lessonVocabProvider = FutureProvider<List<VocabItem>>((ref) async {
  final child = ref.watch(selectedChildProvider);
  final lesson = ref.watch(selectedLessonProvider);
  if (child == null || lesson == null) return [];
  return ref.read(firestoreServiceProvider).getVocabItems(child.id, lesson.id);
});
