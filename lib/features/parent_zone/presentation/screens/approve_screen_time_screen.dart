import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../family/domain/models/child_profile.dart';

class ApproveScreenTimeScreen extends ConsumerStatefulWidget {
  const ApproveScreenTimeScreen({super.key});

  @override
  ConsumerState<ApproveScreenTimeScreen> createState() =>
      _ApproveScreenTimeScreenState();
}

class _ApproveScreenTimeScreenState
    extends ConsumerState<ApproveScreenTimeScreen> {
  // childId → minutes being approved (starts at pending value, editable)
  final Map<String, int> _approving = {};
  final Map<String, bool> _saving = {};

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: const Text('Aprobar tiempo libre 🎮'),
      ),
      body: childrenAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.grass)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (children) {
          final withPending =
              children.where((c) => c.earnedScreenTimePending > 0).toList();

          if (withPending.isEmpty) {
            return _buildEmpty(children.isEmpty);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: withPending.length,
            itemBuilder: (context, i) {
              final child = withPending[i];
              _approving.putIfAbsent(child.id, () => child.earnedScreenTimePending);

              return _ChildApprovalCard(
                child: child,
                minutes: _approving[child.id]!,
                isSaving: _saving[child.id] ?? false,
                onChanged: (val) => setState(() => _approving[child.id] = val),
                onApprove: () => _approve(child),
              )
                  .animate()
                  .fadeIn(delay: Duration(milliseconds: 80 * i), duration: 350.ms)
                  .slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }

  Future<void> _approve(ChildProfile child) async {
    final mins = _approving[child.id] ?? 0;
    if (mins <= 0) return;

    setState(() => _saving[child.id] = true);
    await ref.read(firestoreServiceProvider).approveScreenTime(child.id, mins);
    setState(() {
      _saving[child.id] = false;
      _approving.remove(child.id);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${child.name} recibe $mins min de tiempo libre'),
          backgroundColor: AppColors.grass,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildEmpty(bool noChildren) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              noChildren
                  ? 'No hay perfiles de niños'
                  : '¡Todo aprobado!',
              style: AppTextStyles.headline,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              noChildren
                  ? 'Crea un perfil primero desde el panel principal.'
                  : 'No hay tiempo pendiente de aprobar.\nLos niños deben estudiar más para ganar tiempo libre.',
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

class _ChildApprovalCard extends StatelessWidget {
  const _ChildApprovalCard({
    required this.child,
    required this.minutes,
    required this.isSaving,
    required this.onChanged,
    required this.onApprove,
  });

  final ChildProfile child;
  final int minutes;
  final bool isSaving;
  final ValueChanged<int> onChanged;
  final VoidCallback onApprove;

  // 1 study min = 2.5 screen-time min
  static const double _ratio = 2.5;

  @override
  Widget build(BuildContext context) {
    final screenMinutes = (minutes * _ratio).round();
    final pending = child.earnedScreenTimePending;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.grass.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(child.avatar, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name, style: AppTextStyles.title),
                    Text(
                      'Estudió y ganó $pending min de crédito',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.5),
                      ),
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
                  '${child.earnedScreenTimeApproved} min aprobados',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grass,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Conversion display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grass.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCell(
                  label: 'Crédito ganado',
                  value: '$minutes min',
                  emoji: '📚',
                  color: AppColors.violet,
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.grass, size: 20),
                _StatCell(
                  label: 'Tiempo de pantalla',
                  value: _formatTime(screenMinutes),
                  emoji: '🎮',
                  color: AppColors.grass,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Slider
          Text(
            '¿Cuánto aprobar?',
            style: AppTextStyles.label.copyWith(
              color: AppColors.ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('0', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: minutes.toDouble(),
                  min: 0,
                  max: pending.toDouble(),
                  divisions: pending > 0 ? pending : 1,
                  activeColor: AppColors.grass,
                  inactiveColor: AppColors.paleGray,
                  label: '$minutes min',
                  onChanged: (v) => onChanged(v.round()),
                ),
              ),
              Text('$pending', style: const TextStyle(fontSize: 12)),
            ],
          ),

          Row(
            children: [
              // Approve all shortcut
              TextButton(
                onPressed: () => onChanged(pending),
                child: Text(
                  'Todo ($pending min)',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grass),
                ),
              ),
              const Spacer(),
              // Approve button
              ElevatedButton(
                onPressed: (minutes > 0 && !isSaving) ? onApprove : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.grass,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        '✅ Aprobar $minutes min',
                        style: AppTextStyles.label
                            .copyWith(color: Colors.white),
                      ),
              ),
            ],
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

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  final String label;
  final String value;
  final String emoji;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.title.copyWith(
                color: color, fontWeight: FontWeight.w800)),
        Text(label,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.ink.withValues(alpha: 0.5))),
      ],
    );
  }
}
