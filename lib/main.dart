import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'features/family/domain/models/child_profile.dart';
// Genera este archivo ejecutando: flutterfire configure
// Ver SETUP.md para instrucciones completas
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Solo orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive (almacenamiento local)
  await Hive.initFlutter();
  Hive.registerAdapter(ChildProfileAdapter());

  runApp(
    const ProviderScope(
      child: WoerterAbenteuerApp(),
    ),
  );
}
