import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/router/app_router.dart';

final _loginLoadingProvider = StateProvider<bool>((ref) => false);
final _loginErrorProvider = StateProvider<String?>((ref) => null);

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(_loginLoadingProvider);
    final error = ref.watch(_loginErrorProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.violetSkyVertical,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo
                Text('🇩🇪', style: const TextStyle(fontSize: 72))
                    .animate()
                    .scale(
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                    ),

                const SizedBox(height: 20),

                // Nombre de la app
                Text(
                  'WörterAbenteuer',
                  style: AppTextStyles.display2.copyWith(
                    color: AppColors.cloud,
                    shadows: [
                      Shadow(
                        color: AppColors.ink.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 600.ms),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Aprende alemán jugando',
                  style: AppTextStyles.bodyWhite.copyWith(
                    color: AppColors.cloud.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                const Spacer(flex: 2),

                // Botones de login
                if (!isLoading) ...[
                  // Google
                  _GoogleSignInButton(
                    onPressed: () => _signInWithGoogle(context, ref),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 500.ms)
                      .slideY(begin: 0.3, end: 0, delay: 700.ms, duration: 500.ms),

                  const SizedBox(height: 16),

                  // Apple (solo iOS/macOS)
                  if (AuthService.isAppleSignInAvailable)
                    _AppleSignInButton(
                      onPressed: () => _signInWithApple(context, ref),
                    )
                        .animate()
                        .fadeIn(delay: 900.ms, duration: 500.ms)
                        .slideY(begin: 0.3, end: 0, delay: 900.ms, duration: 500.ms),
                ] else ...[
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cloud),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Iniciando sesión...',
                    style: AppTextStyles.labelWhite,
                  ),
                ],

                // Error
                if (error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.cloud.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      error,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.cloud,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                const Spacer(flex: 1),

                // Nota para padres
                Text(
                  'Solo los papás pueden registrarse · Los niños no necesitan cuenta',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.cloud.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context, WidgetRef ref) async {
    ref.read(_loginLoadingProvider.notifier).state = true;
    ref.read(_loginErrorProvider.notifier).state = null;

    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle();
      if (user != null && context.mounted) {
        context.go(AppRoutes.children);
        return;
      }
    } catch (e) {
      if (context.mounted) {
        ref.read(_loginErrorProvider.notifier).state =
            'No se pudo iniciar sesión con Google. Intenta de nuevo.';
      }
    }
    if (context.mounted) {
      ref.read(_loginLoadingProvider.notifier).state = false;
    }
  }

  Future<void> _signInWithApple(BuildContext context, WidgetRef ref) async {
    ref.read(_loginLoadingProvider.notifier).state = true;
    ref.read(_loginErrorProvider.notifier).state = null;

    try {
      final user = await ref.read(authServiceProvider).signInWithApple();
      if (user != null && context.mounted) {
        context.go(AppRoutes.children);
      }
    } catch (e) {
      ref.read(_loginErrorProvider.notifier).state =
          'No se pudo iniciar sesión con Apple. Intenta de nuevo.';
    } finally {
      ref.read(_loginLoadingProvider.notifier).state = false;
    }
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cloud,
          foregroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono Google
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paleGray, width: 1),
              ),
              child: Center(
                child: Text('G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF4285F4),
                      fontFamily: 'sans-serif',
                    )),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Continuar con Google',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.cloud,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.apple, size: 28, color: AppColors.cloud),
            const SizedBox(width: 12),
            Text(
              'Continuar con Apple',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.cloud,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
