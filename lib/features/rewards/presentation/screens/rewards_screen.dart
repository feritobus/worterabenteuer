import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../lessons/presentation/providers/lesson_providers.dart';
import '../../../family/domain/models/child_profile.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(selectedChildProvider);
    final childrenAsync = ref.watch(childrenProvider);

    // Use live data if available, fall back to selectedChild
    final liveChild = childrenAsync.valueOrNull
            ?.where((c) => c.id == child?.id)
            .firstOrNull ??
        child;

    if (liveChild == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final approved = liveChild.earnedScreenTimeApproved;
    final pending = liveChild.earnedScreenTimePending;
    final screenMinutes = (approved * AppConstants.screenTimeRatio).round();

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: Text('Mis premios 🎮'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Hero card — approved screen time
            _HeroCard(
              child: liveChild,
              approvedMinutes: approved,
              screenMinutes: screenMinutes,
            ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

            const SizedBox(height: 20),

            // Pending card
            if (pending > 0)
              _PendingCard(pendingMinutes: pending)
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 350.ms)
                  .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // How it works
            _HowItWorksCard()
                .animate()
                .fadeIn(delay: 250.ms, duration: 350.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // Points summary
            _PointsCard(child: liveChild)
                .animate()
                .fadeIn(delay: 350.ms, duration: 350.ms)
                .slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.child,
    required this.approvedMinutes,
    required this.screenMinutes,
  });

  final ChildProfile child;
  final int approvedMinutes;
  final int screenMinutes;

  @override
  Widget build(BuildContext context) {
    final hasTime = approvedMinutes > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasTime
              ? [AppColors.grass, AppColors.mint]
              : [AppColors.violet, AppColors.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: (hasTime ? AppColors.grass : AppColors.violet)
                .withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            child.avatar,
            style: const TextStyle(fontSize: 56),
          ).animate().scale(
              delay: 100.ms,
              duration: 600.ms,
              curve: Curves.elasticOut),

          const SizedBox(height: 12),

          Text(
            child.name,
            style: AppTextStyles.headline.copyWith(color: Colors.white),
          ),

          const SizedBox(height: 20),

          if (hasTime) ...[
            Text(
              '🎮',
              style: const TextStyle(fontSize: 48),
            ).animate().scale(
                delay: 200.ms,
                duration: 600.ms,
                curve: Curves.elasticOut),
            const SizedBox(height: 8),
            Text(
              _formatTime(screenMinutes),
              style: AppTextStyles.headline.copyWith(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'de tiempo libre aprobado',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ] else ...[
            Text(
              '📚',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              'Sigue estudiando para ganar tiempo libre',
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h\n${m}min';
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.pendingMinutes});

  final int pendingMinutes;

  @override
  Widget build(BuildContext context) {
    final screenMinutes =
        (pendingMinutes * AppConstants.screenTimeRatio).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sun.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.sun.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esperando aprobación',
                  style: AppTextStyles.label.copyWith(color: AppColors.sun),
                ),
                Text(
                  '$pendingMinutes min de crédito → '
                  '${_formatTime(screenMinutes)} de pantalla',
                  style: AppTextStyles.body,
                ),
                Text(
                  'Un papá o mamá debe aprobarlo',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes min';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo funciona? 💡', style: AppTextStyles.title),
          const SizedBox(height: 12),
          _Rule(
            emoji: '📚',
            text:
                '1 minuto estudiando alemán → ${AppConstants.screenTimeRatio} minutos de pantalla',
          ),
          const SizedBox(height: 8),
          _Rule(
            emoji: '✍️',
            text: 'Escribir y hablar dan más puntos (7 pts cada uno)',
          ),
          const SizedBox(height: 8),
          _Rule(
            emoji: '🏆',
            text: 'Ronda perfecta → ¡+20 puntos extra!',
          ),
          const SizedBox(height: 8),
          _Rule(
            emoji: '✅',
            text: 'Un papá o mamá aprueba el tiempo desde su zona',
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.emoji, required this.text});

  final String emoji;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: AppTextStyles.body),
        ),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MiniStat(
            emoji: '⭐',
            value: '${child.totalPoints}',
            label: 'puntos totales',
          ),
          _MiniStat(
            emoji: '🔥',
            value: '${child.currentStreak}',
            label: 'días seguidos',
          ),
          _MiniStat(
            emoji: '📅',
            value: '${child.effectiveTimeMinutesWeek}',
            label: 'min esta semana',
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.emoji, required this.value, required this.label});

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w900)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: AppColors.ink.withValues(alpha: 0.5))),
      ],
    );
  }
}
