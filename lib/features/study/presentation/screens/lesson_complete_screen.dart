import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/kid_button.dart';
import '../../../study/domain/models/session_result.dart';

class LessonCompleteScreen extends StatelessWidget {
  const LessonCompleteScreen({super.key, required this.result});

  final SessionResult result;

  @override
  Widget build(BuildContext context) {
    final pct = (result.accuracy * 100).round();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: result.accuracy >= 0.7
                ? [AppColors.violet, AppColors.sky]
                : [AppColors.mint, AppColors.sky],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Trophy / emoji
                Text(
                  result.accuracy >= 0.8
                      ? '🏆'
                      : result.accuracy >= 0.5
                          ? '⭐'
                          : '💪',
                  style: const TextStyle(fontSize: 80),
                )
                    .animate()
                    .scale(
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                    ),

                const SizedBox(height: 24),

                Text(
                  result.accuracy >= 0.8
                      ? '¡Excelente!'
                      : result.accuracy >= 0.5
                          ? '¡Buen trabajo!'
                          : '¡Sigue practicando!',
                  style: AppTextStyles.display2
                      .copyWith(color: AppColors.cloud),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  result.lessonTitle,
                  style: AppTextStyles.bodyWhite.copyWith(
                    color: AppColors.cloud.withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 40),

                // Stats
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cloud.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Stat(
                        emoji: '⭐',
                        value: '${result.pointsEarned}',
                        label: 'Puntos',
                      ),
                      _Divider(),
                      _Stat(
                        emoji: '✅',
                        value: '${result.wordsCorrect}',
                        label: 'Correctas',
                      ),
                      _Divider(),
                      _Stat(
                        emoji: '🎯',
                        value: '$pct%',
                        label: 'Precisión',
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                const SizedBox(height: 48),

                // Botones
                KidButton(
                  label: '🏠 Volver a lecciones',
                  onPressed: () => context.go(AppRoutes.lessons),
                  color: AppColors.cloud,
                  textColor: AppColors.violet,
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Practicar otro modo',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.cloud.withValues(alpha: 0.8),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(
      {required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headline.copyWith(color: AppColors.cloud),
        ),
        Text(
          label,
          style: AppTextStyles.caption
              .copyWith(color: AppColors.cloud.withValues(alpha: 0.7)),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: AppColors.cloud.withValues(alpha: 0.2),
    );
  }
}
