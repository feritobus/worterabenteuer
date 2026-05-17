import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../shared/widgets/kid_button.dart';
import '../../domain/models/child_profile.dart';

final _nameProvider = StateProvider<String>((ref) => '');
final _avatarProvider = StateProvider<String>((ref) => '🦊');
final _ageProvider = StateProvider<int>((ref) => 9);
final _levelProvider = StateProvider<String>((ref) => 'A1');
final _savingProvider = StateProvider<bool>((ref) => false);

class CreateChildScreen extends ConsumerStatefulWidget {
  const CreateChildScreen({super.key});

  @override
  ConsumerState<CreateChildScreen> createState() => _CreateChildScreenState();
}

class _CreateChildScreenState extends ConsumerState<CreateChildScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedAvatar = ref.watch(_avatarProvider);
    final selectedAge = ref.watch(_ageProvider);
    final selectedLevel = ref.watch(_levelProvider);
    final isSaving = ref.watch(_savingProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: const Text('Nuevo perfil'),
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
            // Avatar seleccionado grande
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.cloud,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    selectedAvatar,
                    style: const TextStyle(fontSize: 52),
                  ),
                ),
              ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            ),

            const SizedBox(height: 8),

            // Grid de avatares
            Center(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: AppConstants.avatarEmojis.map((emoji) {
                  final isSelected = emoji == selectedAvatar;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(_avatarProvider.notifier).state = emoji,
                    child: AnimatedContainer(
                      duration: 200.ms,
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.violet.withValues(alpha: 0.15)
                            : AppColors.cloud,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.violet
                              : AppColors.paleGray,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 28),

            // Nombre
            Text('¿Cómo te llamas?', style: AppTextStyles.title),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              onChanged: (v) =>
                  ref.read(_nameProvider.notifier).state = v.trim(),
              style: AppTextStyles.bodyLarge,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Nombre del niño',
                filled: true,
                fillColor: AppColors.cloud,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Edad
            Text('¿Cuántos años tienes?', style: AppTextStyles.title),
            const SizedBox(height: 12),
            _AgeSelector(
              value: selectedAge,
              onChanged: (age) {
                ref.read(_ageProvider.notifier).state = age;
                ref.read(_levelProvider.notifier).state =
                    ChildProfile.suggestedLevel(age);
              },
            ),

            const SizedBox(height: 24),

            // Nivel
            Text('Nivel de alemán', style: AppTextStyles.title),
            const SizedBox(height: 8),
            _LevelSelector(
              value: selectedLevel,
              onChanged: (level) =>
                  ref.read(_levelProvider.notifier).state = level,
            ),

            const SizedBox(height: 36),

            KidButton(
              label: '🚀 Crear perfil',
              onPressed: isSaving ? null : () => _saveChild(context, ref),
            ),

            if (isSaving) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveChild(BuildContext context, WidgetRef ref) async {
    final name = ref.read(_nameProvider).trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un nombre')),
      );
      return;
    }

    ref.read(_savingProvider.notifier).state = true;
    try {
      final child = ChildProfile(
        id: const Uuid().v4(),
        name: name,
        avatar: ref.read(_avatarProvider),
        age: ref.read(_ageProvider),
        level: ref.read(_levelProvider),
      );

      await ref.read(firestoreServiceProvider).createChild(child);

      // Reset providers
      ref.read(_nameProvider.notifier).state = '';
      ref.read(_avatarProvider.notifier).state = '🦊';
      ref.read(_ageProvider.notifier).state = 9;
      ref.read(_levelProvider.notifier).state = 'A1';

      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      ref.read(_savingProvider.notifier).state = false;
    }
  }
}

class _AgeSelector extends StatelessWidget {
  const _AgeSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AppConstants.maxAge - AppConstants.minAge + 1,
        itemBuilder: (context, i) {
          final age = AppConstants.minAge + i;
          final isSelected = age == value;
          return GestureDetector(
            onTap: () => onChanged(age),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 10),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.violet : AppColors.cloud,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.violet.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  '$age',
                  style: AppTextStyles.bodyBold.copyWith(
                    color: isSelected ? AppColors.cloud : AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LevelSelector extends StatelessWidget {
  const _LevelSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppConstants.levels.map((level) {
        final isSelected = level == value;
        final label = AppConstants.levelLabels[level] ?? level;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(level),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: EdgeInsets.only(
                right: level == AppConstants.levels.last ? 0 : 12,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.violet : AppColors.cloud,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.violet.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  Text(
                    level,
                    style: AppTextStyles.headline.copyWith(
                      color: isSelected ? AppColors.cloud : AppColors.violet,
                    ),
                  ),
                  Text(
                    label,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.cloud.withValues(alpha: 0.8)
                          : AppColors.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
