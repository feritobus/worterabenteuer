import 'dart:math';
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

class FlashcardScreen extends ConsumerStatefulWidget {
  const FlashcardScreen({super.key});

  @override
  ConsumerState<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends ConsumerState<FlashcardScreen>
    with TickerProviderStateMixin {
  List<VocabItem> _queue = [];
  int _currentIndex = 0;
  int _pointsEarned = 0;
  bool _isFlipped = false;
  bool _loading = true;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadVocab();
  }

  Future<void> _loadVocab() async {
    final vocab = await ref.read(lessonVocabProvider.future);
    setState(() {
      _queue = List.from(vocab)..shuffle();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
      // +1 punto al ver la traducción
      setState(() => _pointsEarned += AppConstants.pointsFlashCard);
      _awardPoints();
    }
    setState(() => _isFlipped = !_isFlipped);
  }

  Future<void> _awardPoints() async {
    final child = ref.read(selectedChildProvider);
    if (child == null) return;
    await ref
        .read(firestoreServiceProvider)
        .addPoints(child.id, AppConstants.pointsFlashCard);
  }

  void _next({bool isEasy = true}) {
    if (!_isFlipped) {
      _flip(); // Forzar ver la traducción antes de avanzar
      return;
    }

    if (!isEasy) {
      // Agregar al final de la cola
      _queue.add(_queue[_currentIndex]);
    }

    if (_currentIndex >= _queue.length - 1) {
      _finish();
      return;
    }

    _flipController.reset();
    setState(() {
      _currentIndex++;
      _isFlipped = false;
    });
  }

  void _finish() {
    final lesson = ref.read(selectedLessonProvider);
    final result = SessionResult(
      pointsEarned: _pointsEarned,
      wordsAttempted: _currentIndex + 1,
      wordsCorrect: _currentIndex + 1,
      mode: 'flashcard',
      lessonTitle: lesson?.title ?? '',
    );
    context.pushReplacement(AppRoutes.studyComplete, extra: result);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(selectedLessonProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: Text(lesson?.title ?? 'Flash Cards'),
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
          : _queue.isEmpty
              ? _EmptyVocab()
              : _buildStudy(),
    );
  }

  Widget _buildStudy() {
    // Progreso (solo las originales, sin las repetidas)
    final original = ref.read(lessonVocabProvider).valueOrNull?.length ?? _queue.length;
    final progress = (_currentIndex / original).clamp(0.0, 1.0);

    return Column(
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: AppColors.paleGray,
          valueColor: const AlwaysStoppedAnimation(AppColors.sky),
        ),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Carta ${_currentIndex + 1} de ${_queue.length}',
                style: AppTextStyles.caption,
              ),
              Text(
                '🃏 Toca para voltear',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.violet),
              ),
            ],
          ),
        ),

        // Flashcard
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: GestureDetector(
              onTap: _flip,
              child: AnimatedBuilder(
                animation: _flipAnimation,
                builder: (context, child) {
                  final angle = _flipAnimation.value * pi;
                  final isShowingFront = _flipAnimation.value <= 0.5;
                  return Transform(
                    transform: Matrix4.rotationY(angle),
                    alignment: Alignment.center,
                    child: isShowingFront
                        ? _buildFront(_queue[_currentIndex])
                        : Transform(
                            transform: Matrix4.rotationY(pi),
                            alignment: Alignment.center,
                            child: _buildBack(_queue[_currentIndex]),
                          ),
                  );
                },
              ),
            ),
          ),
        ),

        // Botones (solo cuando está volteada)
        AnimatedOpacity(
          opacity: _isFlipped ? 1.0 : 0.0,
          duration: 200.ms,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isFlipped ? () => _next(isEasy: false) : null,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Difícil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.berry.withValues(alpha: 0.12),
                      foregroundColor: AppColors.berry,
                      elevation: 0,
                      minimumSize: const Size(0, 56),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isFlipped ? () => _next(isEasy: true) : null,
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text('Fácil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.grass.withValues(alpha: 0.12),
                      foregroundColor: AppColors.grass,
                      elevation: 0,
                      minimumSize: const Size(0, 56),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFront(VocabItem item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.violet.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.isWord ? '🇩🇪 Alemán' : '🇩🇪 Oración',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.violet),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              item.german,
              style: item.isWord
                  ? AppTextStyles.germanWord
                  : AppTextStyles.germanSentence,
              textAlign: TextAlign.center,
            ),
          ),
          if (item.grammarNote != null) ...[
            const SizedBox(height: 8),
            Text(
              '(${item.grammarNote})',
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.violet.withValues(alpha: 0.6)),
            ),
          ],
          const SizedBox(height: 16),
          // Speaker — IconButton consumes the tap so the card doesn't flip
          IconButton.filled(
            tooltip: 'Escuchar',
            icon: const Icon(Icons.volume_up_rounded),
            color: AppColors.cloud,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.violet,
              padding: const EdgeInsets.all(14),
            ),
            onPressed: () =>
                ref.read(ttsServiceProvider).speakGerman(item.german),
          ),
          const SizedBox(height: 16),
          Text(
            '👆 Toca para ver la traducción',
            style: AppTextStyles.caption
                .copyWith(color: AppColors.ink.withValues(alpha: 0.3)),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(VocabItem item) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.violet, AppColors.sky],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.violet.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cloud.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🇪🇸 Español',
              style: AppTextStyles.caption.copyWith(color: AppColors.cloud),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              item.spanish,
              style: AppTextStyles.headline.copyWith(color: AppColors.cloud),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '⭐ +${AppConstants.pointsFlashCard} punto',
            style: AppTextStyles.label.copyWith(
              color: AppColors.cloud.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyVocab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text('Esta lección no tiene palabras todavía',
              style: AppTextStyles.body),
        ],
      ),
    );
  }
}
