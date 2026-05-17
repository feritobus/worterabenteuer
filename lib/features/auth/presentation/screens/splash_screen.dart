import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/router/app_router.dart';
import 'onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted || _navigated) return;

    final authState = ref.read(authStateProvider);
    authState.when(
      data: (user) async {
        if (!mounted || _navigated) return;
        _navigated = true;
        if (user != null) {
          final seen = await hasSeenOnboarding();
          if (!mounted) return;
          context.go(seen ? AppRoutes.children : AppRoutes.onboarding);
        } else {
          context.go(AppRoutes.login);
        }
      },
      loading: () {
        // Si sigue cargando, escuchar cuando termine
        ref.listenManual(authStateProvider, (_, next) {
          if (_navigated) return;
          next.whenData((user) async {
            if (!mounted) return;
            _navigated = true;
            if (user != null) {
              final seen = await hasSeenOnboarding();
              if (!mounted) return;
              context.go(seen ? AppRoutes.children : AppRoutes.onboarding);
            } else {
              context.go(AppRoutes.login);
            }
          });
        });
      },
      error: (error, stack) {
        if (!mounted || _navigated) return;
        _navigated = true;
        context.go(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.violetSkyVertical,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bandera y emoji
              Text(
                '🇩🇪',
                style: const TextStyle(fontSize: 80),
              )
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                  )
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 24),

              // Nombre de la app
              Text(
                'WörterAbenteuer',
                style: AppTextStyles.display2.copyWith(
                  color: AppColors.cloud,
                  shadows: [
                    Shadow(
                      color: AppColors.ink.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 300.ms),

              const SizedBox(height: 12),

              // Tagline
              Text(
                'Aprende alemán jugando',
                style: AppTextStyles.bodyWhite.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppColors.cloud.withValues(alpha: 0.9),
                ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 500.ms),

              const SizedBox(height: 48),

              // Indicador de carga
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.cloud.withValues(alpha: 0.8),
                  ),
                  strokeWidth: 3,
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
