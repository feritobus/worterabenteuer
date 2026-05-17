import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/family/presentation/screens/child_selection_screen.dart';
import '../../features/family/presentation/screens/create_child_screen.dart';
import '../../features/parent_zone/presentation/screens/parent_login_screen.dart';
import '../../features/parent_zone/presentation/screens/parent_dashboard_screen.dart';
import '../../features/parent_zone/presentation/screens/import_vocab_screen.dart';
import '../../features/parent_zone/presentation/screens/ocr_review_screen.dart';
import '../../core/services/ocr_service.dart';

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
      // Placeholders para sprints futuros
      GoRoute(
        path: AppRoutes.approveScreenTime,
        builder: (context, state) => _PlaceholderScreen(title: 'Aprobar Tiempo Libre (Sprint 8)'),
      ),
      GoRoute(
        path: AppRoutes.weeklyReport,
        builder: (context, state) => _PlaceholderScreen(title: 'Reporte Semanal (Sprint 9)'),
      ),
      GoRoute(
        path: AppRoutes.lessons,
        builder: (context, state) => _PlaceholderScreen(title: 'Lecciones (Sprint 4)'),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.uri}')),
    ),
  );
});

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🚧', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String children = '/children';
  static const String createChild = '/children/new';
  static const String parentLogin = '/parent/login';
  static const String parentDashboard = '/parent/dashboard';
  static const String importVocab = '/parent/import';
  static const String ocrReview = '/parent/import/review';
  static const String approveScreenTime = '/parent/approve';
  static const String weeklyReport = '/parent/report';
  static const String lessons = '/lessons';
  static const String lessonDetail = '/lessons/:lessonId';
  static const String studyMode = '/study/:lessonId/:mode';
  static const String rewards = '/rewards';
  static const String extraVocab = '/extra-vocab/:lessonId';
}
