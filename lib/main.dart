import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'features/auth/presentation/screens/firebase_setup_screen.dart';
import 'features/family/domain/models/child_profile.dart';
import 'features/lessons/domain/models/lesson.dart';
import 'features/lessons/domain/models/vocab_item.dart';
// Genera este archivo ejecutando: flutterfire configure
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Refuse to start with placeholder Firebase config — would crash silently
  // at first Auth/Firestore call.
  if (_isPlaceholderFirebaseConfig()) {
    runApp(const FirebaseSetupScreen(
      errorMessage: 'lib/firebase_options.dart contiene valores placeholder '
          '(TU_API_KEY_*). Ejecuta `flutterfire configure` para reemplazarlos.',
    ));
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(FirebaseSetupScreen(errorMessage: e.toString()));
    return;
  }

  // Hive (almacenamiento local)
  await Hive.initFlutter();
  Hive.registerAdapter(ChildProfileAdapter());
  Hive.registerAdapter(LessonAdapter());
  Hive.registerAdapter(VocabItemAdapter());

  runApp(
    const ProviderScope(
      child: WoerterAbenteuerApp(),
    ),
  );
}

bool _isPlaceholderFirebaseConfig() {
  try {
    final opts = DefaultFirebaseOptions.currentPlatform;
    return opts.apiKey.startsWith('TU_') ||
        opts.projectId.startsWith('TU_') ||
        opts.appId.startsWith('TU_');
  } catch (_) {
    // currentPlatform throws on unsupported platforms — treat as misconfigured
    return true;
  }
}
