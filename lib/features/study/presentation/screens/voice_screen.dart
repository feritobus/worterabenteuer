import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../lessons/presentation/providers/lesson_providers.dart';
import '../../../lessons/domain/models/vocab_item.dart';
import '../../../study/domain/models/session_result.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen>
    with SingleTickerProviderStateMixin {
  List<VocabItem> _vocab = [];
  int _currentIndex = 0;
  int _pointsEarned = 0;
  int _wordsCorrect = 0;
  bool _loading = true;

  final SpeechToText _speech = SpeechToText();
  bool _speechAvailable = false;
  bool _listening = false;
  String _spokenText = '';
  bool? _isCorrect;
  bool _showResult = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initSpeech();
    _loadVocab();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: (_) => setState(() => _listening = false),
    );
    setState(() => _speechAvailable = available);
  }

  Future<void> _loadVocab() async {
    final vocab = await ref.read(lessonVocabProvider.future);
    setState(() {
      _vocab = List.from(vocab);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      setState(() => _listening = false);
    }
  }

  VocabItem get _current => _vocab[_currentIndex];

  // ── Matching (same tolerance logic as handwriting) ───────────────────────────

  int _tolerance(int age) {
    if (age <= 8) return AppConstants.handwritingToleranceByAge['young']!;
    if (age <= 10) return AppConstants.handwritingToleranceByAge['middle']!;
    return AppConstants.handwritingToleranceByAge['older']!;
  }

  bool _isMatch(String spoken, String target, int age) {
    // Strip article prefixes common in German vocab (der/die/das/ein/eine)
    String clean(String s) {
      var t = s.toLowerCase().trim();
      for (final art in ['der ', 'die ', 'das ', 'ein ', 'eine ']) {
        if (t.startsWith(art)) return t.substring(art.length).trim();
      }
      return t;
    }

    final s = clean(spoken);
    final tgt = clean(target);
    if (s == tgt) return true;
    final tol = _tolerance(age);
    return tol > 0 && _levenshtein(s, tgt) <= tol;
  }

  int _levenshtein(String a, String b) {
    final m = a.length, n = b.length;
    final dp = List.generate(m + 1, (_) => List.filled(n + 1, 0));
    for (int i = 0; i <= m; i++) dp[i][0] = i;
    for (int j = 0; j <= n; j++) dp[0][j] = j;
    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (a[i - 1] == b[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          final sub = dp[i - 1][j - 1];
          final del = dp[i - 1][j];
          final ins = dp[i][j - 1];
          dp[i][j] = 1 + (sub < del ? (sub < ins ? sub : ins) : (del < ins ? del : ins));
        }
      }
    }
    return dp[m][n];
  }

  // ── Mic control ──────────────────────────────────────────────────────────────

  Future<void> _toggleListening() async {
    if (_showResult) return;
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    setState(() {
      _listening = true;
      _spokenText = '';
    });

    await _speech.listen(
      onResult: _onResult,
      localeId: 'de_DE',
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 2),
      partialResults: true,
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    setState(() => _spokenText = result.recognizedWords);

    if (result.finalResult && _spokenText.isNotEmpty) {
      _evaluateAnswer();
    }
  }

  Future<void> _evaluateAnswer() async {
    await _speech.stop();
    final child = ref.read(selectedChildProvider);
    final age = child?.age ?? 9;
    final correct = _isMatch(_spokenText, _current.german, age);

    setState(() {
      _isCorrect = correct;
      _showResult = true;
      _listening = false;
    });

    await _persistResult(correct);
  }

  Future<void> _persistResult(bool correct) async {
    final child = ref.read(selectedChildProvider);
    final lesson = ref.read(selectedLessonProvider);
    if (child == null || lesson == null) return;

    final fs = ref.read(firestoreServiceProvider);
    final item = _current;

    item.voiceAttempts++;
    if (correct) {
      item.voiceCorrect++;
      // Bonus only applies once the word is already dominated (schema rule)
      if (item.dominated) item.voiceBonus = true;
      setState(() {
        _pointsEarned += AppConstants.pointsVoice;
        _wordsCorrect++;
      });
      await fs.addPoints(child.id, AppConstants.pointsVoice);
    }

    await fs.updateVocabItem(child.id, lesson.id, item);
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  void _next() {
    if (_currentIndex < _vocab.length - 1) {
      setState(() {
        _currentIndex++;
        _showResult = false;
        _isCorrect = null;
        _spokenText = '';
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    final lesson = ref.read(selectedLessonProvider);
    context.pushReplacement(
      AppRoutes.studyComplete,
      extra: SessionResult(
        pointsEarned: _pointsEarned,
        wordsAttempted: _vocab.length,
        wordsCorrect: _wordsCorrect,
        mode: 'voice',
        lessonTitle: lesson?.title ?? '',
      ),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(selectedLessonProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: Text(lesson?.title ?? 'Hablar'),
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.grass))
          : _vocab.isEmpty
              ? const Center(child: Text('Esta lección no tiene palabras 📭'))
              : _buildStudy(),
    );
  }

  Widget _buildStudy() {
    final progress = (_currentIndex + 1) / _vocab.length;
    final item = _current;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          minHeight: 6,
          backgroundColor: AppColors.paleGray,
          valueColor: const AlwaysStoppedAnimation(AppColors.grass),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
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
                      '🎤 $_wordsCorrect correctas',
                      style: AppTextStyles.caption.copyWith(color: AppColors.grass),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Prompt card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.grass.withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
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
                      if (item.grammarNote != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.grammarNote!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.4),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms).scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1)),

                const SizedBox(height: 36),

                // Mic area
                if (!_showResult) _buildMicArea() else _buildResultBanner(item),

                const SizedBox(height: 24),

                // Action button
                if (_showResult)
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.grass,
                        foregroundColor: AppColors.cloud,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
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
                  ).animate().fadeIn(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMicArea() {
    return Column(
      children: [
        // Spoken text preview
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          alignment: Alignment.center,
          child: _spokenText.isNotEmpty
              ? Text(
                  '"$_spokenText"',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                )
              : _listening
                  ? Text(
                      'Escuchando...',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grass.withValues(alpha: 0.7),
                      ),
                    )
                  : Text(
                      _speechAvailable
                          ? 'Toca el micrófono para hablar'
                          : 'Micrófono no disponible',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.35),
                      ),
                    ),
        ),

        const SizedBox(height: 24),

        // Mic button
        GestureDetector(
          onTap: _speechAvailable ? _toggleListening : null,
          child: _listening
              ? AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  ),
                  child: _micCircle(active: true),
                )
              : _micCircle(active: false),
        ),

        const SizedBox(height: 16),

        // Skip button
        TextButton(
          onPressed: _evaluateAnswer,
          child: Text(
            'Saltar palabra',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.ink.withValues(alpha: 0.35),
            ),
          ),
        ),
      ],
    );
  }

  Widget _micCircle({required bool active}) {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.grass : AppColors.grass.withValues(alpha: 0.12),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.grass.withValues(alpha: 0.4),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ]
            : [],
      ),
      child: Icon(
        active ? Icons.mic_rounded : Icons.mic_none_rounded,
        size: 48,
        color: active ? Colors.white : AppColors.grass,
      ),
    );
  }

  Widget _buildResultBanner(VocabItem item) {
    final correct = _isCorrect == true;
    final color = correct ? AppColors.grass : AppColors.berry;
    final tts = ref.read(ttsServiceProvider);

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
            correct ? '🎉 ¡Muy bien!' : '❌ Casi...',
            style: AppTextStyles.bodyBold.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_spokenText.isNotEmpty)
            Text(
              'Escuché: "$_spokenText"',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.ink.withValues(alpha: 0.5),
                fontStyle: FontStyle.italic,
              ),
            ),
          if (!correct) ...[
            const SizedBox(height: 4),
            Text(
              'La respuesta es: "${item.german}"',
              style: AppTextStyles.bodyBold.copyWith(color: color),
            ),
          ],
          if (correct) ...[
            const SizedBox(height: 4),
            Text(
              '+${AppConstants.pointsVoice} puntos ⭐  |  🎙️ bono de voz',
              style: AppTextStyles.label.copyWith(color: AppColors.sun),
            ),
          ],
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => tts.speakGerman(item.german),
            icon: const Icon(Icons.volume_up_rounded, size: 18),
            label: const Text('Escuchar pronunciación'),
            style: TextButton.styleFrom(
              foregroundColor: color,
              textStyle: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0);
  }
}
