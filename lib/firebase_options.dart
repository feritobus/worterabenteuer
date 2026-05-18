// ESTE ARCHIVO ES UN PLACEHOLDER.
// Para generar el archivo real, ejecuta:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Sigue las instrucciones en SETUP.md

// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web no está soportado en V1');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma. '
          'Ejecuta: flutterfire configure',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAoA4xnvo8lRZ9APnzh_0ehEE6Z_gsFhOo',
    appId: '1:91875643342:android:fd98d0bee4c1068fc9659f',
    messagingSenderId: '91875643342',
    projectId: 'worterabenteuer',
    storageBucket: 'worterabenteuer.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: 'TU_APP_ID_IOS',
    messagingSenderId: '91875643342',
    projectId: 'worterabenteuer',
    storageBucket: 'worterabenteuer.firebasestorage.app',
    iosClientId: 'TU_IOS_CLIENT_ID',
    iosBundleId: 'com.feritobus.worterabenteuer',
  );
}
