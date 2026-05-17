import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/family/presentation/screens/child_selection_screen.dart';
import '../../features/family/presentation/screens/create_child_screen.dart';
import '../../features/family/domain/models/child_profile.dart';
import '../../features/parent_zone/presentation/screens/parent_login_screen.dart';
import '../../features/parent_zone/presentation/screens/parent_dashboard_screen.dart';
import '../../features/parent_zone/presentation/screens/import_vocab_screen.dart';
import '../../features/parent_zone/presentation/screens/ocr_review_screen.dart';
import '../../core/services/ocr_service.dart';
import '../../features/lessons/presentation/screens/lesson_list_screen.dart';
import '../../features/lessons/presentation/screens/lesson_detail_screen.dart';
import '../../features/study/presentation/screens/flashcard_screen.dart';
import '../../features/study/presentation/screens/keyboard_screen.dart';
import '../../features/study/presentation/screens/lesson_complete_screen.dart';
import '../../features/study/presentation/screens/handwriting_screen.dart';
import '../../features/study/presentation/screens/voice_screen.dart';
import '../../features/parent_zone/presentation/screens/approve_screen_time_screen.dart';
import '../../features/parent_zone/presentation/screens/weekly_report_screen.dart';
import '../../features/rewards/presentation/screens/rewards_screen.dart';
import '../../features/extra_vocab/presentation/screens/extra_vocab_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/study/domain/models/session_result.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;

      if (loc == AppRoutes.splash) return null;

      if (!isLoggedIn && loc != AppRoutes.login) return AppRoutes.login;
      if (isLoggedIn && loc == AppRoutes.login) return AppRoutes.children;

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.children,
        builder: (context, state) => const ChildSelectionScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const CreateChildScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.parentLogin,
        builder: (context, state) => const ParentLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentDashboard,
        builder: (context, state) => const ParentDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.editChild,
        builder: (context, state) {
          final child = state.extra as ChildProfile?;
          return CreateChildScreen(existingChild: child);
        },
      ),
      GoRoute(
        path: AppRoutes.importVocab,
        builder: (context, state) => const ImportVocabScreen(),
      ),
      GoRoute(
        path: AppRoutes.ocrReview,
        builder: (context, state) {
          final result = state.extra as OcrResult? ??
              OcrResult(words: [], sentences: [], confidence: 1.0);
          return OcrReviewScreen(ocrResult: result);
        },
      ),
      GoRoute(
        path: AppRoutes.createLesson,
        builder: (context, state) => OcrReviewScreen(
          ocrResult: OcrResult(words: [], sentences: [], confidence: 0),
          isManual: true,
        ),
      ),
      // Placeholders para sprints futuros
      GoRoute(
        path: AppRoutes.approveScreenTime,
        builder: (context, state) => const ApproveScreenTimeScreen(),
      ),
      GoRoute(
        path: AppRoutes.weeklyReport,
        builder: (context, state) => const WeeklyReportScreen(),
      ),
      GoRoute(
        path: AppRoutes.rewards,
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: AppRoutes.extraVocab,
        builder: (context, state) => const ExtraVocabScreen(),
      ),
      // Sprint 4 — Lessons & Study
      GoRoute(
        path: AppRoutes.lessons,
        builder: (context, state) => const LessonListScreen(),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) => const LessonDetailScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.studyFlashcard,
        builder: (context, state) => const FlashcardScreen(),
      ),
      GoRoute(
        path: AppRoutes.studyKeyboard,
        builder: (context, state) => const KeyboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.studyVoice,
        builder: (context, state) => const VoiceScreen(),
      ),
      GoRoute(
        path: AppRoutes.studyHandwriting,
        builder: (context, state) => const HandwritingScreen(),
      ),
      GoRoute(
        path: AppRoutes.studyComplete,
        builder: (context, state) {
          final result = state.extra as SessionResult? ??
              SessionResult(
                pointsEarned: 0,
                wordsAttempted: 0,
                wordsCorrect: 0,
                mode: 'flashcard',
                lessonTitle: '',
              );
          return LessonCompleteScreen(result: result);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String children = '/children';
  static const String createChild = '/children/new';
  static const String parentLogin = '/parent/login';
  static const String parentDashboard = '/parent/dashboard';
  static const String editChild = '/parent/edit-child';
  static const String importVocab = '/parent/import';
  static const String ocrReview = '/parent/import/review';
  static const String createLesson = '/parent/create-lesson';
  static const String approveScreenTime = '/parent/approve';
  static const String weeklyReport = '/parent/report';
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lessons/detail';
  static const String studyFlashcard = '/study/flashcard';
  static const String studyKeyboard = '/study/keyboard';
  static const String studyVoice = '/study/voice';
  static const String studyHandwriting = '/study/handwriting';
  static const String studyComplete = '/study/complete';
  static const String rewards = '/rewards';
  static const String extraVocab = '/extra-vocab';
}
