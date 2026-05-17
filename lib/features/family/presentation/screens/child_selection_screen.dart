import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/widgets/progress_bar.dart';
import '../../domain/models/child_profile.dart';

class ChildSelectionScreen extends ConsumerWidget {
  const ChildSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F4FF), Color(0xFFE8EEF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '¿Quién soy hoy? 👋',
                      style: AppTextStyles.headline,
                    ),
                    // Acceso discreto a zona de padres
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.parentLogin),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cloud,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.ink.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: AppColors.violet,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: childrenAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.violet,
                    ),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      'Error al cargar perfiles\n$e',
                      style: AppTextStyles.body,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (children) {
                    if (children.isEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        context.push(AppRoutes.createChild);
                      });
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.violet,
                        ),
                      );
                    }
                    return _ChildGrid(children: children);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildGrid extends StatelessWidget {
  const _ChildGrid({required this.children});

  final List<ChildProfile> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
        ),
        itemCount: children.length + 1, // +1 para el botón agregar
        itemBuilder: (context, index) {
          if (index == children.length) {
            return _AddChildCard()
                .animate()
                .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
                .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 100 * index));
          }
          return _ChildCard(child: children[index])
              .animate()
              .fadeIn(delay: Duration(milliseconds: 100 * index), duration: 400.ms)
              .slideY(begin: 0.2, end: 0, delay: Duration(milliseconds: 100 * index));
        },
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    // Progreso semanal: asumimos meta de 60 min/semana
    final weeklyGoal = 60;
    final progress =
        (child.effectiveTimeMinutesWeek / weeklyGoal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.lessons,
        extra: child,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.pale,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  child.avatar,
                  style: const TextStyle(fontSize: 38),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Nombre
            Text(
              child.name,
              style: AppTextStyles.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 4),

            // Nivel
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                child.level,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.violet,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Progreso semanal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: KidProgressBar(
                value: progress,
                label: '${child.effectiveTimeMinutesWeek} min esta semana',
              ),
            ),

            const SizedBox(height: 8),

            // Puntos
            Text(
              '⭐ ${child.totalPoints} pts',
              style: AppTextStyles.label.copyWith(
                color: AppColors.sun,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddChildCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.createChild),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.violet.withValues(alpha: 0.3),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                size: 32,
                color: AppColors.violet,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Nuevo niño',
              style: AppTextStyles.label.copyWith(
                color: AppColors.violet,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
