import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../data/parent_auth_service.dart';
import '../../../family/domain/models/child_profile.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: Text('Zona de Padres 🔐', style: AppTextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Salir',
            onPressed: () async {
              ref.read(parentSessionProvider.notifier).state = false;
              context.go(AppRoutes.children);
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(parentSessionProvider.notifier).state = false;
            context.go(AppRoutes.children);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de niños
            childrenAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.violet)),
              error: (e, _) => Text('Error: $e'),
              data: (children) {
                if (children.isEmpty) {
                  return _EmptyChildrenCard();
                }
                return Column(
                  children: children
                      .asMap()
                      .entries
                      .map((e) => _ChildStatCard(child: e.value)
                          .animate()
                          .fadeIn(
                              delay: Duration(milliseconds: 100 * e.key),
                              duration: 400.ms))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 24),

            Text('Acciones', style: AppTextStyles.headline),
            const SizedBox(height: 12),

            // Grid de acciones
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                _ActionCard(
                  emoji: '📤',
                  label: 'Importar vocabulario',
                  color: AppColors.violet,
                  onTap: () => context.push(AppRoutes.importVocab),
                ),
                _ActionCard(
                  emoji: '🎮',
                  label: 'Aprobar tiempo libre',
                  color: AppColors.grass,
                  onTap: () => context.push(AppRoutes.approveScreenTime),
                ),
                _ActionCard(
                  emoji: '📊',
                  label: 'Reporte semanal',
                  color: AppColors.sky,
                  onTap: () => context.push(AppRoutes.weeklyReport),
                ),
                _ActionCard(
                  emoji: '➕',
                  label: 'Nuevo niño',
                  color: AppColors.sun,
                  onTap: () => context.push(AppRoutes.createChild),
                ),
              ]
                  .asMap()
                  .entries
                  .map((e) => e.value
                      .animate()
                      .fadeIn(
                          delay: Duration(milliseconds: 80 * e.key),
                          duration: 350.ms)
                      .slideY(begin: 0.15, end: 0))
                  .toList(),
            ),

            const SizedBox(height: 24),

            // Cerrar sesión de la app
            TextButton.icon(
              onPressed: () async {
                ref.read(parentSessionProvider.notifier).state = false;
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.power_settings_new_rounded,
                  color: AppColors.berry),
              label: Text(
                'Cerrar sesión de la app',
                style: AppTextStyles.label.copyWith(color: AppColors.berry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChildStatCard extends ConsumerWidget {
  const _ChildStatCard({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(child.avatar, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(child.name, style: AppTextStyles.title),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(child.level,
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.violet,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${child.effectiveTimeMinutesWeek} min efectivos esta semana · '
                  '${child.totalPoints} pts',
                  style: AppTextStyles.caption,
                ),
                if (child.earnedScreenTimePending > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.grass.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '⏱ ${child.earnedScreenTimePending} min pendientes de aprobar',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grass,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChildrenCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          'Aún no hay perfiles de niños.\nCrea uno con el botón de abajo.',
          style: AppTextStyles.body,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
