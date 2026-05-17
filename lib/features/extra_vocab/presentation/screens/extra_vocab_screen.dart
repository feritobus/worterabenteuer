import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../lessons/presentation/providers/lesson_providers.dart';
import '../../../lessons/domain/models/vocab_item.dart';

// ── Hardcoded A1 theme packs ─────────────────────────────────────────────────

class _ThemePack {
  final String id;
  final String emoji;
  final String title;
  final String titleEs;
  final List<_Word> words;

  const _ThemePack({
    required this.id,
    required this.emoji,
    required this.title,
    required this.titleEs,
    required this.words,
  });
}

class _Word {
  final String german;
  final String spanish;
  const _Word(this.german, this.spanish);
}

const _packs = [
  _ThemePack(
    id: 'animals',
    emoji: '🐾',
    title: 'Tiere',
    titleEs: 'Animales',
    words: [
      _Word('der Hund', 'el perro'),
      _Word('die Katze', 'el gato'),
      _Word('der Fisch', 'el pez'),
      _Word('der Vogel', 'el pájaro'),
      _Word('der Hase', 'el conejo'),
      _Word('die Maus', 'el ratón'),
      _Word('der Bär', 'el oso'),
      _Word('das Pferd', 'el caballo'),
    ],
  ),
  _ThemePack(
    id: 'food',
    emoji: '🍎',
    title: 'Essen & Früchte',
    titleEs: 'Comida y frutas',
    words: [
      _Word('der Apfel', 'la manzana'),
      _Word('die Banane', 'el plátano'),
      _Word('die Orange', 'la naranja'),
      _Word('die Erdbeere', 'la fresa'),
      _Word('das Brot', 'el pan'),
      _Word('die Milch', 'la leche'),
      _Word('der Käse', 'el queso'),
      _Word('das Ei', 'el huevo'),
    ],
  ),
  _ThemePack(
    id: 'home',
    emoji: '🏠',
    title: 'Zuhause',
    titleEs: 'En casa',
    words: [
      _Word('das Haus', 'la casa'),
      _Word('das Zimmer', 'el cuarto'),
      _Word('die Küche', 'la cocina'),
      _Word('das Bett', 'la cama'),
      _Word('die Tür', 'la puerta'),
      _Word('das Fenster', 'la ventana'),
      _Word('der Tisch', 'la mesa'),
      _Word('der Stuhl', 'la silla'),
    ],
  ),
  _ThemePack(
    id: 'colors',
    emoji: '🎨',
    title: 'Farben',
    titleEs: 'Colores',
    words: [
      _Word('rot', 'rojo'),
      _Word('blau', 'azul'),
      _Word('grün', 'verde'),
      _Word('gelb', 'amarillo'),
      _Word('schwarz', 'negro'),
      _Word('weiß', 'blanco'),
      _Word('orange', 'anaranjado'),
      _Word('lila', 'morado'),
    ],
  ),
  _ThemePack(
    id: 'clothes',
    emoji: '👗',
    title: 'Kleidung',
    titleEs: 'Ropa',
    words: [
      _Word('das Hemd', 'la camisa'),
      _Word('die Hose', 'los pantalones'),
      _Word('die Jacke', 'la chaqueta'),
      _Word('der Schuh', 'el zapato'),
      _Word('die Mütze', 'el gorro'),
      _Word('das Kleid', 'el vestido'),
      _Word('der Rock', 'la falda'),
      _Word('der Mantel', 'el abrigo'),
    ],
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class ExtraVocabScreen extends ConsumerStatefulWidget {
  const ExtraVocabScreen({super.key});

  @override
  ConsumerState<ExtraVocabScreen> createState() => _ExtraVocabScreenState();
}

class _ExtraVocabScreenState extends ConsumerState<ExtraVocabScreen> {
  final Set<String> _addedPacks = {};
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(selectedLessonProvider);

    if (lesson == null || !lesson.perfectRoundCompleted) {
      return Scaffold(
        backgroundColor: AppColors.pale,
        appBar: AppBar(title: const Text('Vocabulario Extra 🌟')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text('Aún no desbloqueado', style: AppTextStyles.headline),
                const SizedBox(height: 8),
                Text(
                  'Completa una ronda perfecta de escritura\npara desbloquear paquetes extra.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: const Text('Vocabulario Extra 🌟'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¡Ronda perfecta completada!',
                  style: AppTextStyles.headline,
                ),
                const SizedBox(height: 4),
                Text(
                  'Agrega un paquete de palabras extra a "${lesson.title}"',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: _packs.length,
              itemBuilder: (context, i) {
                final pack = _packs[i];
                final added = _addedPacks.contains(pack.id);
                return _PackCard(
                  pack: pack,
                  added: added,
                  onTap: added ? null : () => _previewPack(context, pack),
                )
                    .animate()
                    .fadeIn(
                        delay: Duration(milliseconds: 80 * i),
                        duration: 350.ms)
                    .slideX(begin: 0.08, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _previewPack(BuildContext context, _ThemePack pack) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackPreviewSheet(
        pack: pack,
        saving: _saving,
        onAdd: () => _addPack(context, pack),
      ),
    );
  }

  Future<void> _addPack(BuildContext context, _ThemePack pack) async {
    if (_saving) return;
    setState(() => _saving = true);

    final child = ref.read(selectedChildProvider);
    final lesson = ref.read(selectedLessonProvider);
    if (child == null || lesson == null) {
      setState(() => _saving = false);
      return;
    }

    final uuid = const Uuid();
    final items = pack.words
        .map((w) => VocabItem(
              id: uuid.v4(),
              german: w.german,
              spanish: w.spanish,
              type: 'word',
              order: 0, // set by addExtraVocabToLesson
            ))
        .toList();

    await ref.read(firestoreServiceProvider).addExtraVocabToLesson(
          childId: child.id,
          lessonId: lesson.id,
          items: items,
          currentWordsTotal: lesson.wordsTotal,
        );

    setState(() {
      _addedPacks.add(pack.id);
      _saving = false;
    });

    if (context.mounted) {
      Navigator.of(context).pop(); // close sheet
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${pack.emoji} ${pack.words.length} palabras de ${pack.titleEs} agregadas'),
          backgroundColor: AppColors.grass,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

// ── Pack card ─────────────────────────────────────────────────────────────────

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.added,
    required this.onTap,
  });

  final _ThemePack pack;
  final bool added;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: added
              ? AppColors.grass.withValues(alpha: 0.07)
              : AppColors.cloud,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: added
                ? AppColors.grass.withValues(alpha: 0.35)
                : AppColors.gold.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(pack.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pack.title, style: AppTextStyles.title),
                  Text(
                    pack.titleEs,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pack.words.length} palabras',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (added)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.grass, size: 28)
            else
              Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.gold.withValues(alpha: 0.7), size: 28),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet preview ──────────────────────────────────────────────────────

class _PackPreviewSheet extends StatelessWidget {
  const _PackPreviewSheet({
    required this.pack,
    required this.saving,
    required this.onAdd,
  });

  final _ThemePack pack;
  final bool saving;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.paleGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Text(pack.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pack.title, style: AppTextStyles.headline),
                    Text(
                      pack.titleEs,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Word list (max 6 shown)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              shrinkWrap: true,
              itemCount: pack.words.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final w = pack.words[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(w.german, style: AppTextStyles.bodyBold),
                      ),
                      Text(
                        w.spanish,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: saving ? null : onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.ink,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: saving
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(
                        '🌟 Agregar ${pack.words.length} palabras a mi lección',
                        style: AppTextStyles.bodyBold,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
