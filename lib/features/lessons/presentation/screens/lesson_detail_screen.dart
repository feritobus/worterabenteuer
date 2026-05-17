import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../providers/lesson_providers.dart';

class LessonDetailScreen extends ConsumerWidget {
  const LessonDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(selectedLessonProvider);
    final child = ref.watch(selectedChildProvider);

    if (lesson == null || child == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final progress = lesson.wordsTotal > 0
        ? lesson.wordsDominated / lesson.wordsTotal
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: Text(lesson.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de progreso
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.violetSky,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: AppTextStyles.headline
                        .copyWith(color: AppColors.cloud),
                  ),
                  if (lesson.titleSpanish.isNotEmpty)
                    Text(
                      lesson.titleSpanish,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.cloud.withValues(alpha: 0.8),
                      ),
                    ),
                  const SizedBox(height: 16),
                  KidProgressBar(
                    value: progress,
                    color: AppColors.cloud,
                    backgroundColor: AppColors.cloud.withValues(alpha: 0.3),
                    height: 10,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${lesson.wordsDominated} de ${lesson.wordsTotal} palabras dominadas',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.cloud.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

            const SizedBox(height: 28),

            Text('¿Cómo quieres practicar?', style: AppTextStyles.headline)
                .animate()
                .fadeIn(delay: 150.ms),

            const SizedBox(height: 4),

            Text(
              'Hablar y escribir a mano valen más puntos',
              style: AppTextStyles.body
                  .copyWith(color: AppColors.ink.withValues(alpha: 0.5)),
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 20),

            // Modos
            ..._modes.asMap().entries.map((e) {
              final mode = e.value;
              return _ModeButton(
                emoji: mode.emoji,
                title: mode.title,
                points: mode.points,
                badge: mode.badge,
                color: mode.color,
                onTap: () => context.push(mode.route),
                isLocked: mode.requiresPerfect &&
                    !lesson.perfectRoundCompleted,
              )
                  .animate()
                  .fadeIn(
                      delay: Duration(milliseconds: 100 * (e.key + 3)),
                      duration: 350.ms)
                  .slideX(begin: 0.1, end: 0);
            }),

            const SizedBox(height: 16),

            // Nota de vocabulario extra
            if (lesson.extraVocabUnlocked)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('🌟', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Vocabulario extra desbloqueado!',
                            style: AppTextStyles.label
                                .copyWith(color: AppColors.sun),
                          ),
                          Text(
                            'Completaste la ronda perfecta',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 600.ms),
          ],
        ),
      ),
    );
  }

  static final _modes = [
    _ModeInfo(
      emoji: '🃏',
      title: 'Flash Cards',
      points: '+1 pt por carta',
      color: AppColors.sky,
      route: AppRoutes.studyFlashcard,
    ),
    _ModeInfo(
      emoji: '🎙️',
      title: 'Hablar',
      points: '+7 pts',
      badge: 'MEJOR',
      color: AppColors.grass,
      route: AppRoutes.studyVoice,
      requiresPerfect: true,
    ),
    _ModeInfo(
      emoji: '⌨️',
      title: 'Teclado',
      points: '+2 pts',
      color: AppColors.mint,
      route: AppRoutes.studyKeyboard,
    ),
    _ModeInfo(
      emoji: '✍️',
      title: 'Escribir a mano',
      points: '+7 pts',
      badge: 'MEJOR',
      color: AppColors.violet,
      route: AppRoutes.studyHandwriting,
      requiresPerfect: true,
    ),
  ];
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.emoji,
    required this.title,
    required this.points,
    required this.color,
    required this.onTap,
    this.badge,
    this.isLocked = false,
  });

  final String emoji;
  final String title;
  final String points;
  final String? badge;
  final Color color;
  final VoidCallback onTap;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isLocked
              ? AppColors.paleGray
              : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isLocked
                ? AppColors.paleGray
                : color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: TextStyle(
                  fontSize: 32,
                  color: isLocked ? Colors.grey.withValues(alpha: 0.5) : null),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.title.copyWith(
                      color: isLocked
                          ? AppColors.ink.withValues(alpha: 0.3)
                          : AppColors.ink,
                    ),
                  ),
                  Text(
                    points,
                    style: AppTextStyles.label.copyWith(
                      color: isLocked
                          ? AppColors.ink.withValues(alpha: 0.2)
                          : color,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null && !isLocked)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.cloud,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (isLocked)
              const Icon(Icons.lock_outline_rounded,
                  color: Colors.grey, size: 20),
            if (!isLocked && badge == null)
              Icon(Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _ModeInfo {
  final String emoji;
  final String title;
  final String points;
  final String? badge;
  final Color color;
  final String route;
  final bool requiresPerfect;

  const _ModeInfo({
    required this.emoji,
    required this.title,
    required this.points,
    required this.color,
    required this.route,
    this.badge,
    this.requiresPerfect = false,
  });
}
