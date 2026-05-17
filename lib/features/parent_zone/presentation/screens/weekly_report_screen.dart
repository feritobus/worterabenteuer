import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../family/domain/models/child_profile.dart';
import '../../../study/domain/models/study_session.dart';

// Provider: fetch weekly sessions for a specific child
final _weeklySessionsProvider =
    FutureProvider.family<List<StudySession>, String>((ref, childId) async {
  return ref.read(firestoreServiceProvider).getSessionsThisWeek(childId);
});

class WeeklyReportScreen extends ConsumerWidget {
  const WeeklyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: const Text('Reporte semanal 📊'),
      ),
      body: childrenAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.sky)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (children) {
          if (children.isEmpty) {
            return _buildEmpty();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: children.length + 1, // +1 for header
            itemBuilder: (context, i) {
              if (i == 0) return _buildHeader();
              final child = children[i - 1];
              return _ChildReportCard(child: child)
                  .animate()
                  .fadeIn(
                      delay: Duration(milliseconds: 100 * i),
                      duration: 350.ms)
                  .slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final label =
        '${_dayMonth(weekStart)} – ${_dayMonth(now)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        'Esta semana ($label)',
        style: AppTextStyles.caption
            .copyWith(color: AppColors.ink.withValues(alpha: 0.45)),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📊', style: TextStyle(fontSize: 64))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text('No hay perfiles de niños', style: AppTextStyles.headline),
          ],
        ),
      ),
    );
  }

  String _dayMonth(DateTime d) =>
      '${d.day}/${d.month}';
}

class _ChildReportCard extends ConsumerWidget {
  const _ChildReportCard({required this.child});

  final ChildProfile child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(_weeklySessionsProvider(child.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Child header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(child.avatar, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name, style: AppTextStyles.title),
                      Text(
                        '${child.level} · ${child.totalPoints} pts totales',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grass.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${child.effectiveTimeMinutesWeek} min',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grass,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 20, endIndent: 20),

          // Sessions
          sessionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.violet)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e', style: AppTextStyles.caption),
            ),
            data: (sessions) => _buildSessionsContent(sessions),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsContent(List<StudySession> sessions) {
    if (sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Sin sesiones esta semana.\nAníma a ${child.name} a estudiar 📚',
          style: AppTextStyles.body.copyWith(
            color: AppColors.ink.withValues(alpha: 0.45),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Aggregate
    final totalPoints =
        sessions.fold(0, (sum, s) => sum + s.pointsEarned);
    final totalWords =
        sessions.fold(0, (sum, s) => sum + s.wordsCorrect);
    final totalMinutes =
        sessions.fold(0, (sum, s) => sum + s.estimatedMinutes);
    final avgAccuracy = sessions.isEmpty
        ? 0.0
        : sessions.fold(0.0, (sum, s) => sum + s.accuracy) / sessions.length;

    // Mode distribution
    final modeCounts = <String, int>{};
    for (final s in sessions) {
      modeCounts[s.mode] = (modeCounts[s.mode] ?? 0) + 1;
    }
    final topMode = modeCounts.entries
        .fold<MapEntry<String, int>?>(null,
            (best, e) => best == null || e.value > best.value ? e : best)
        ?.key;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.4,
            children: [
              _KpiTile(
                emoji: '📅',
                label: 'Sesiones',
                value: '${sessions.length}',
                color: AppColors.violet,
              ),
              _KpiTile(
                emoji: '⭐',
                label: 'Puntos ganados',
                value: '$totalPoints',
                color: AppColors.sun,
              ),
              _KpiTile(
                emoji: '✅',
                label: 'Palabras correctas',
                value: '$totalWords',
                color: AppColors.grass,
              ),
              _KpiTile(
                emoji: '⏱',
                label: 'Tiempo efectivo',
                value: '$totalMinutes min',
                color: AppColors.sky,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Accuracy + top mode row
          Row(
            children: [
              Expanded(
                child: _PillStat(
                  label: 'Precisión promedio',
                  value: '${(avgAccuracy * 100).round()}%',
                  color: avgAccuracy >= 0.7
                      ? AppColors.grass
                      : AppColors.berry,
                ),
              ),
              if (topMode != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _PillStat(
                    label: 'Modo favorito',
                    value: _modeLabel(topMode),
                    color: AppColors.violet,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Last 3 sessions
          Text(
            'Últimas sesiones',
            style: AppTextStyles.label.copyWith(
              color: AppColors.ink.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          ...sessions.take(3).map((s) => _SessionRow(session: s)),
        ],
      ),
    );
  }

  String _modeLabel(String mode) {
    const labels = {
      'flashcard': '🃏 Flash Cards',
      'keyboard': '⌨️ Teclado',
      'handwriting': '✍️ Escritura',
      'voice': '🎙️ Voz',
    };
    return labels[mode] ?? mode;
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  final String emoji;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: AppTextStyles.title.copyWith(
                      color: color, fontWeight: FontWeight.w900),
                ),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillStat extends StatelessWidget {
  const _PillStat(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTextStyles.label.copyWith(
                  color: color, fontWeight: FontWeight.w800)),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    final modeEmojis = {
      'flashcard': '🃏',
      'keyboard': '⌨️',
      'handwriting': '✍️',
      'voice': '🎙️',
    };
    final emoji = modeEmojis[session.mode] ?? '📖';
    final pct = (session.accuracy * 100).round();
    final h = session.completedAt.hour.toString().padLeft(2, '0');
    final m = session.completedAt.minute.toString().padLeft(2, '0');
    final d = session.completedAt.day;
    final mo = session.completedAt.month;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.pale,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              session.lessonTitle,
              style: AppTextStyles.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${session.pointsEarned} ⭐  $pct%',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.sun,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$d/$mo $h:$m',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.ink.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
