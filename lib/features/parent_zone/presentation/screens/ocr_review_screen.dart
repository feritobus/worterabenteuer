import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../shared/widgets/kid_button.dart';
import '../../../family/domain/models/child_profile.dart';
import '../../../lessons/domain/models/vocab_item.dart';
import '../../../lessons/domain/models/lesson.dart';

class OcrReviewScreen extends ConsumerStatefulWidget {
  const OcrReviewScreen({
    super.key,
    required this.ocrResult,
    this.isManual = false,
  });

  final OcrResult ocrResult;
  final bool isManual;

  @override
  ConsumerState<OcrReviewScreen> createState() => _OcrReviewScreenState();
}

class _OcrReviewScreenState extends ConsumerState<OcrReviewScreen> {
  late List<_EditablePair> _words;
  late List<_EditablePair> _sentences;
  final _titleController = TextEditingController();
  String _selectedLevel = 'A1';
  String? _selectedChildId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _words = widget.ocrResult.words
        .map((p) => _EditablePair.from(p))
        .toList();
    _sentences = widget.ocrResult.sentences
        .map((p) => _EditablePair.from(p))
        .toList();

    // Manual mode: start with one blank row so the parent can type immediately
    if (widget.isManual && _words.isEmpty) {
      _words.add(_EditablePair.empty());
    }

    // Auto-title
    final now = DateTime.now();
    _titleController.text =
        'Vocabulario ${now.day}/${now.month}/${now.year}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final p in [..._words, ..._sentences]) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final childrenAsync = ref.watch(childrenProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: Text(widget.isManual ? 'Crear lección' : 'Revisar vocabulario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Confianza del OCR (solo cuando no es entrada manual)
          if (!widget.isManual && widget.ocrResult.confidence > 0)
            _ConfidenceBanner(confidence: widget.ocrResult.confidence),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título de lección
                  Text('Título de la lección', style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: AppTextStyles.bodyLarge,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cloud,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Asignar a niño
                  Text('Asignar a', style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  childrenAsync.when(
                    loading: () => const CircularProgressIndicator(
                        color: AppColors.violet),
                    error: (e, _) => Text('Error: $e'),
                    data: (children) => _ChildDropdown(
                      children: children,
                      selectedId: _selectedChildId,
                      onChanged: (id) =>
                          setState(() => _selectedChildId = id),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Nivel
                  Text('Nivel', style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  _LevelChips(
                    value: _selectedLevel,
                    onChanged: (v) => setState(() => _selectedLevel = v),
                  ),

                  const SizedBox(height: 28),

                  // Palabras
                  _SectionHeader(
                    title: 'Palabras',
                    count: _words.length,
                    onAdd: () => setState(
                        () => _words.add(_EditablePair.empty())),
                  ),
                  const SizedBox(height: 8),

                  if (_words.isEmpty)
                    _EmptySection(
                        message: 'No se detectaron palabras.\nAgrégalas manualmente.')
                  else
                    ..._words.asMap().entries.map((e) => _PairRow(
                          pair: e.value,
                          onDelete: () =>
                              setState(() => _words.removeAt(e.key)),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 50 * e.key),
                              duration: 300.ms,
                            )),

                  const SizedBox(height: 24),

                  // Oraciones
                  _SectionHeader(
                    title: 'Oraciones',
                    count: _sentences.length,
                    onAdd: () => setState(
                        () => _sentences.add(_EditablePair.empty())),
                  ),
                  const SizedBox(height: 8),

                  if (_sentences.isEmpty)
                    _EmptySection(
                        message: 'No se detectaron oraciones.')
                  else
                    ..._sentences.asMap().entries.map((e) => _PairRow(
                          pair: e.value,
                          isSentence: true,
                          onDelete: () =>
                              setState(() => _sentences.removeAt(e.key)),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 50 * e.key),
                              duration: 300.ms,
                            )),

                  const SizedBox(height: 32),

                  // Guardar
                  KidButton(
                    label: '✅ Guardar y asignar',
                    onPressed: _saving ? null : _save,
                    color: AppColors.grass,
                  ),

                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.grass)),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('Por favor ingresa un título para la lección.');
      return;
    }
    if (_selectedChildId == null) {
      _showError('Por favor selecciona a qué niño asignar la lección.');
      return;
    }

    final allPairs = [
      ..._words.where((p) => p.german.text.isNotEmpty),
      ..._sentences.where((p) => p.german.text.isNotEmpty),
    ];

    if (allPairs.isEmpty) {
      _showError('Agrega al menos una palabra u oración.');
      return;
    }

    setState(() => _saving = true);

    try {
      final service = ref.read(firestoreServiceProvider);
      final lessonId = const Uuid().v4();

      final lesson = Lesson(
        id: lessonId,
        title: title,
        titleSpanish: '',
        source: AppConstants.sourceCustomSheet,
        level: _selectedLevel,
        childId: _selectedChildId!,
        wordsTotal: allPairs.length,
        assignedAt: DateTime.now(),
      );

      // Build vocab items
      final vocabItems = <VocabItem>[];
      for (int i = 0; i < _words.length; i++) {
        final p = _words[i];
        if (p.german.text.isEmpty) continue;
        vocabItems.add(VocabItem(
          id: const Uuid().v4(),
          german: p.german.text.trim(),
          spanish: p.spanish.text.trim(),
          type: 'word',
          order: i,
        ));
      }
      for (int i = 0; i < _sentences.length; i++) {
        final p = _sentences[i];
        if (p.german.text.isEmpty) continue;
        vocabItems.add(VocabItem(
          id: const Uuid().v4(),
          german: p.german.text.trim(),
          spanish: p.spanish.text.trim(),
          type: 'sentence',
          order: _words.length + i,
        ));
      }

      await service.createLesson(
        childId: _selectedChildId!,
        lesson: lesson,
        vocabItems: vocabItems,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Lección guardada con ${vocabItems.length} palabras',
            ),
            backgroundColor: AppColors.grass,
          ),
        );
        // Pop back to parent dashboard
        context.go('/parent/dashboard');
      }
    } catch (e) {
      _showError('Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }
}

// ── Subwidgets ───────────────────────────────────────────────

class _ConfidenceBanner extends StatelessWidget {
  const _ConfidenceBanner({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = confidence >= 0.7 ? AppColors.grass : AppColors.warning;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: color.withValues(alpha: 0.1),
      child: Text(
        confidence >= 0.7
            ? '✅ OCR completado — $pct% de confianza. Revisa los pares.'
            : '⚠️ Confianza baja ($pct%). Revisa y corrige manualmente.',
        style: AppTextStyles.label.copyWith(color: color),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(
      {required this.title, required this.count, required this.onAdd});

  final String title;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$title ($count)', style: AppTextStyles.title),
        const Spacer(),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Agregar'),
          style: TextButton.styleFrom(foregroundColor: AppColors.violet),
        ),
      ],
    );
  }
}

class _PairRow extends StatelessWidget {
  const _PairRow({
    required this.pair,
    required this.onDelete,
    this.isSentence = false,
  });

  final _EditablePair pair;
  final VoidCallback onDelete;
  final bool isSentence;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _EditField(
              controller: pair.german,
              hint: isSentence ? 'Oración en alemán' : 'Alemán',
              color: AppColors.violet,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('→',
                style: AppTextStyles.body
                    .copyWith(color: AppColors.ink.withValues(alpha: 0.3))),
          ),
          Expanded(
            child: _EditField(
              controller: pair.spanish,
              hint: isSentence ? 'Traducción' : 'Español',
              color: AppColors.sky,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded,
                color: AppColors.error.withValues(alpha: 0.6), size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  const _EditField(
      {required this.controller, required this.hint, required this.color});

  final TextEditingController controller;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.label,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.caption,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        filled: true,
        fillColor: color.withValues(alpha: 0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _ChildDropdown extends StatelessWidget {
  const _ChildDropdown({
    required this.children,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ChildProfile> children;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Text(
        'No hay perfiles de niños. Crea uno primero.',
        style: AppTextStyles.body
            .copyWith(color: AppColors.ink.withValues(alpha: 0.5)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          hint: Text('Selecciona un niño', style: AppTextStyles.body),
          isExpanded: true,
          items: children
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Row(
                      children: [
                        Text(c.avatar,
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Text(c.name, style: AppTextStyles.bodyLarge),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _LevelChips extends StatelessWidget {
  const _LevelChips({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AppConstants.levels.map((level) {
        final selected = level == value;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: FilterChip(
            label: Text(
              '$level — ${AppConstants.levelLabels[level]}',
              style: AppTextStyles.label.copyWith(
                color: selected ? AppColors.cloud : AppColors.violet,
              ),
            ),
            selected: selected,
            onSelected: (_) => onChanged(level),
            selectedColor: AppColors.violet,
            backgroundColor: AppColors.cloud,
            side: BorderSide(
                color: selected ? AppColors.violet : AppColors.paleGray),
            checkmarkColor: AppColors.cloud,
          ),
        );
      }).toList(),
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paleGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: AppTextStyles.body
            .copyWith(color: AppColors.ink.withValues(alpha: 0.4)),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Editable pair model ─────────────────────────────────────

class _EditablePair {
  final TextEditingController german;
  final TextEditingController spanish;

  _EditablePair({required this.german, required this.spanish});

  factory _EditablePair.from(VocabPair pair) => _EditablePair(
        german: TextEditingController(text: pair.german),
        spanish: TextEditingController(text: pair.spanish),
      );

  factory _EditablePair.empty() => _EditablePair(
        german: TextEditingController(),
        spanish: TextEditingController(),
      );

  void dispose() {
    german.dispose();
    spanish.dispose();
  }
}
