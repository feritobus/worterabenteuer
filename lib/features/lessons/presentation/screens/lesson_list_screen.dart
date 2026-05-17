import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../providers/lesson_providers.dart';
import '../../domain/models/lesson.dart';

class LessonListScreen extends ConsumerWidget {
  const LessonListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final lessonsAsync = ref.watch(childLessonsProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: child == null
            ? const Text('Mis lecciones')
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(child.avatar, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(child.name),
                ],
              ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (child != null) ...[
            // Rewards shortcut
            GestureDetector(
              onTap: () => context.push(AppRoutes.rewards),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.grass.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '🎮 ${child.earnedScreenTimeApproved}min',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.grass,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            // Points chip
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '⭐ ${child.totalPoints}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.sun,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              '¿Qué aprendemos hoy? 📚',
              style: AppTextStyles.headline,
            ).animate().fadeIn(duration: 400.ms),
          ),
          Expanded(
            child: lessonsAsync.when(
              loading: () => const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.violet)),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (lessons) {
                if (lessons.isEmpty) {
                  return _EmptyLessons(childName: child?.name ?? '');
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: lessons.length,
                  itemBuilder: (context, i) => _LessonCard(
                    lesson: lessons[i],
                    onTap: () {
                      ref.read(selectedLessonProvider.notifier).state =
                          lessons[i];
                      context.push(AppRoutes.lessonDetail);
                    },
                  )
                      .animate()
                      .fadeIn(
                          delay: Duration(milliseconds: 80 * i),
                          duration: 350.ms)
                      .slideX(begin: 0.1, end: 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onTap});

  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(lesson.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusInfo.borderColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: statusInfo.borderColor.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Progreso circular
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: lesson.wordsTotal > 0
                        ? lesson.wordsDominated / lesson.wordsTotal
                        : 0,
                    strokeWidth: 5,
                    backgroundColor:
                        statusInfo.borderColor.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(statusInfo.borderColor),
                  ),
                  Text(
                    statusInfo.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: AppTextStyles.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              statusInfo.borderColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusInfo.label,
                          style: AppTextStyles.caption.copyWith(
                            color: statusInfo.borderColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lesson.wordsDominated}/${lesson.wordsTotal} palabras dominadas · ${lesson.level}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.ink.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusInfo(
            emoji: '▶', label: 'Continuar', borderColor: AppColors.grass);
      case 'completed':
        return _StatusInfo(
            emoji: '✓', label: 'Completada', borderColor: AppColors.sky);
      case 'perfect':
        return _StatusInfo(
            emoji: '🌟', label: 'Perfecta', borderColor: AppColors.gold);
      default:
        return _StatusInfo(
            emoji: '⭐', label: 'Asignada', borderColor: AppColors.violet);
    }
  }
}

class _StatusInfo {
  final String emoji;
  final String label;
  final Color borderColor;

  const _StatusInfo(
      {required this.emoji,
      required this.label,
      required this.borderColor});
}

class _EmptyLessons extends StatelessWidget {
  const _EmptyLessons({required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📚', style: TextStyle(fontSize: 64))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'Aún no hay lecciones',
              style: AppTextStyles.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Un papá o mamá debe importar\nel vocabulario desde la zona de padres 🔐',
              style: AppTextStyles.body.copyWith(
                color: AppColors.ink.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
