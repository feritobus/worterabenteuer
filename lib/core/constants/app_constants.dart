class AppConstants {
  AppConstants._();

  // Idiomas
  static const String targetLanguage = 'de'; // alemán
  static const String targetLocale = 'de-DE';
  static const String uiLanguage = 'es'; // español de México

  // Plataformas mínimas
  static const int androidMinSdk = 24; // Android 7.0
  static const String iosMinVersion = '13.0';

  // Puntos por actividad
  static const int pointsFlashCard = 1;
  static const int pointsTyped = 2;
  static const int pointsHandwritten = 7;
  static const int pointsVoice = 7;
  static const int pointsPerfectRound = 20;
  static const double pointsExtraVocabMultiplier = 1.5;

  // Tiempo
  static const int idleTimeoutSeconds = 15;
  static const double screenTimeRatio = 2.5; // 1 min efectivo = 2.5 min pantalla
  static const int perfectRoundBonusMinutes = 5;

  // Tolerancia de escritura por edad
  static const Map<String, int> handwritingToleranceByAge = {
    'young': 2,  // 7-8 años
    'middle': 1, // 9-10 años
    'older': 0,  // 11-12 años
  };

  // Niveles
  static const List<String> levels = ['A1', 'A2'];
  static const Map<String, String> levelLabels = {
    'A1': 'Principiante',
    'A2': 'Elemental',
  };

  // Fuentes de vocabulario
  static const String sourcePaulLisa = 'paul_lisa_co';
  static const String sourceDabei = 'dabei';
  static const String sourceCustomSheet = 'custom_sheet';
  static const String sourceAnton = 'anton';

  // Colecciones Firestore
  static const String collFamilies = 'families';
  static const String collChildren = 'children';
  static const String collLessons = 'lessons';
  static const String collVocabulary = 'vocabulary';
  static const String collSessions = 'sessions';
  static const String collAchievements = 'achievements';
  static const String collVocabLibrary = 'vocab_library';
  static const String collExtraVocabThemes = 'extra_vocab_themes';

  // Hive type IDs
  static const int hiveChildProfile = 0;
  static const int hiveLesson = 1;
  static const int hiveVocabItem = 2;
  static const int hiveStudySession = 3;

  // Secure storage keys
  static const String keyParentPin = 'parent_pin';
  static const String keyParentPinSet = 'parent_pin_set';

  // Avatares disponibles
  static const List<String> avatarEmojis = [
    '🦊', '🐸', '🐧', '🐰', '🦄', '🐶',
    '🐱', '🐼', '🦁', '🐯', '🐨', '🐵',
    '🦋', '🐙', '🦕', '🐬',
  ];

  // Edad mínima y máxima
  static const int minAge = 7;
  static const int maxAge = 12;
}
