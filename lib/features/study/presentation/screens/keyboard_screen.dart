import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../lessons/presentation/providers/lesson_providers.dart';
import '../../../lessons/domain/models/vocab_item.dart';
import '../../../study/domain/models/session_result.dart';

class KeyboardScreen extends ConsumerStatefulWidget {
  const KeyboardScreen({super.key});

  @override
  ConsumerState<KeyboardScreen> createState() => _KeyboardScreenState();
}

class _KeyboardScreenState extends ConsumerState<KeyboardScreen> {
  List<VocabItem> _vocab = [];
  int _currentIndex = 0;
  int _pointsEarned = 0;
  int _correctCount = 0;
  bool _loading = true;
  bool _showResult = false;
  bool _isCorrect = false;

  final _answerController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadVocab();
  }

  Future<void> _loadVocab() async {
    final vocab = await ref.read(lessonVocabProvider.future);
    setState(() {
      _vocab = List.from(vocab);
      _loading = false;
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _verify() {
    if (_showResult) {
      _next();
      return;
    }

    final answer = _answerController.text.trim();
    if (answer.isEmpty) return;

    final correct = _vocab[_currentIndex].german;
    final isCorrect = answer.toLowerCase() == correct.toLowerCase();

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
      setState(() {
        _correctCount++;
        _pointsEarned += AppConstants.pointsTyped;
      });
      _awardPoints();
    }
  }

  Future<void> _awardPoints() async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;
    await ref
        .read(firestoreServiceProvider)
        .addPoints(child.id, AppConstants.pointsTyped);
  }

  void _next() {
    if (_currentIndex >= _vocab.length - 1) {
      _finish();
      return;
    }
    setState(() {
      _currentIndex++;
      _showResult = false;
      _isCorrect = false;
      _answerController.clear();
    });
    _focusNode.requestFocus();
  }

  void _finish() {
    final lesson = ref.read(selectedLessonProvider);
    final result = SessionResult(
      pointsEarned: _pointsEarned,
      wordsAttempted: _vocab.length,
      wordsCorrect: _correctCount,
      mode: 'keyboard',
      lessonTitle: lesson?.title ?? '',
    );
    context.pushReplacement(AppRoutes.studyComplete, extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(selectedLessonProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(lesson?.title ?? 'Teclado'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '⭐ $_pointsEarned',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.sun,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.violet))
          : _vocab.isEmpty
              ? _buildEmpty()
              : _buildStudy(),
    );
  }

  Widget _buildStudy() {
    final item = _vocab[_currentIndex];
    final progress = (_currentIndex + 1) / _vocab.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: AppColors.paleGray,
          valueColor: const AlwaysStoppedAnimation(AppColors.mint),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Column(
              children: [
                // Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} de ${_vocab.length}',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '✅ $_correctCount correctas',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.grass),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Pregunta: español → escribir alemán
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mint.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '¿Cómo se dice en alemán?',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.spanish,
                        style: AppTextStyles.headline,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1)),

                const SizedBox(height: 24),

                // Input
                if (!_showResult) ...[
                  _GermanTextField(
                    controller: _answerController,
                    focusNode: _focusNode,
                    onSubmit: _verify,
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 10),
                  _GermanSpecialKeys(
                    controller: _answerController,
                    focusNode: _focusNode,
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.mint,
                        foregroundColor: AppColors.cloud,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        '✅ Verificar',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.cloud),
                      ),
                    ),
                  ),
                ] else ...[
                  // Resultado
                  _ResultBanner(
                    isCorrect: _isCorrect,
                    correctAnswer: item.german,
                    userAnswer: _answerController.text.trim(),
                    points: AppConstants.pointsTyped,
                    onPronounce: () =>
                        ref.read(ttsServiceProvider).speakGerman(item.german),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.violet,
                        foregroundColor: AppColors.cloud,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentIndex >= _vocab.length - 1
                            ? '🏁 Terminar'
                            : '➡️ Siguiente',
                        style: AppTextStyles.bodyBold
                            .copyWith(color: AppColors.cloud),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('Esta lección no tiene palabras todavía 📭'),
    );
  }
}

class _GermanTextField extends StatelessWidget {
  const _GermanTextField({
    required this.controller,
    required this.focusNode,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => onSubmit(),
      style: AppTextStyles.headline.copyWith(color: AppColors.violet),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: 'Escribe en alemán...',
        hintStyle: AppTextStyles.body
            .copyWith(color: AppColors.ink.withValues(alpha: 0.3)),
        filled: true,
        fillColor: AppColors.cloud,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide:
              const BorderSide(color: AppColors.violet, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        // Hint sobre caracteres especiales alemanes
        suffixIcon: Tooltip(
          message: 'ü ö ä ß — usa el teclado alemán',
          child: Icon(Icons.info_outline_rounded,
              color: AppColors.ink.withValues(alpha: 0.3)),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.isCorrect,
    required this.correctAnswer,
    required this.userAnswer,
    required this.points,
    required this.onPronounce,
  });

  final bool isCorrect;
  final String correctAnswer;
  final String userAnswer;
  final int points;
  final VoidCallback onPronounce;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.grass : AppColors.berry;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            isCorrect ? '🎉 ¡Correcto!' : '❌ Casi...',
            style: AppTextStyles.headline.copyWith(color: color),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              'Tú escribiste: "$userAnswer"',
              style: AppTextStyles.body.copyWith(
                color: AppColors.ink.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'La respuesta es: "$correctAnswer"',
              style: AppTextStyles.bodyBold.copyWith(color: color),
            ),
          ],
          if (isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              '+$points puntos ⭐',
              style: AppTextStyles.label.copyWith(color: AppColors.sun),
            ),
          ],
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onPronounce,
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Escuchar pronunciación'),
            style: TextButton.styleFrom(foregroundColor: color),
          ),
        ],
      ),
    );
  }
}

class _GermanSpecialKeys extends StatelessWidget {
  const _GermanSpecialKeys({
    required this.controller,
    required this.focusNode,
  });

  final TextEditingController controller;
  final FocusNode focusNode;

  static const _keys = ['ä', 'ö', 'ü', 'Ä', 'Ö', 'Ü', 'ß'];

  void _insert(String char) {
    final text = controller.text;
    final sel = controller.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, char);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + char.length),
    );
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: _keys.map((k) => _KeyButton(label: k, onTap: () => _insert(k))).toList(),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.violet.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyBold.copyWith(color: AppColors.violet),
          ),
        ),
      ),
    );
  }
}
