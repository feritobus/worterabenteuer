import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/tts_service.dart';
import '../../../lessons/presentation/providers/lesson_providers.dart';
import '../../../lessons/domain/models/vocab_item.dart';
import '../../../study/domain/models/session_result.dart';

enum _StudyPhase { mainRound, reviewRound }

class HandwritingScreen extends ConsumerStatefulWidget {
  const HandwritingScreen({super.key});

  @override
  ConsumerState<HandwritingScreen> createState() => _HandwritingScreenState();
}

class _HandwritingScreenState extends ConsumerState<HandwritingScreen> {
  List<VocabItem> _mainVocab = [];
  List<VocabItem> _reviewList = [];
  int _currentIndex = 0;
  _StudyPhase _phase = _StudyPhase.mainRound;

  int _pointsEarned = 0;
  int _wordsCorrect = 0;

  late DigitalInkRecognizer _recognizer;
  bool _modelReady = false;
  bool _modelDownloading = false;

  // Ink strokes for ML Kit
  final List<InkStroke> _inkStrokes = [];
  // Strokes for painting (list of paths)
  final List<List<Offset>> _paintStrokes = [];
  List<Offset> _activeStroke = [];

  bool _recognizing = false;
  String? _recognizedText;
  bool? _isCorrect;
  bool _showResult = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _recognizer = DigitalInkRecognizer(languageCode: 'de');
    _initModel();
    _loadVocab();
  }

  Future<void> _initModel() async {
    final manager = DigitalInkRecognizerModelManager();
    final downloaded = await manager.isModelDownloaded('de');
    if (!downloaded) {
      setState(() => _modelDownloading = true);
      await manager.downloadModel('de');
      setState(() => _modelDownloading = false);
    }
    setState(() => _modelReady = true);
  }

  Future<void> _loadVocab() async {
    final vocab = await ref.read(lessonVocabProvider.future);
    setState(() {
      _mainVocab = List.from(vocab);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  VocabItem get _current =>
      _phase == _StudyPhase.mainRound ? _mainVocab[_currentIndex] : _reviewList[_currentIndex];

  List<VocabItem> get _activeList =>
      _phase == _StudyPhase.mainRound ? _mainVocab : _reviewList;

  int _tolerance(int age) {
    if (age <= 8) return AppConstants.handwritingToleranceByAge['young']!;
    if (age <= 10) return AppConstants.handwritingToleranceByAge['middle']!;
    return AppConstants.handwritingToleranceByAge['older']!;
  }

  bool _isMatch(String recognized, String target, int age) {
    final r = recognized.toLowerCase().trim();
    final t = target.toLowerCase().trim();
    if (r == t) return true;
    final tol = _tolerance(age);
    return tol > 0 && _levenshtein(r, t) <= tol;
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

  // ── Drawing gestures ────────────────────────────────────────────────────────

  void _onPanStart(DragStartDetails d) {
    if (_showResult || _recognizing) return;
    setState(() => _activeStroke = [d.localPosition]);
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_showResult || _recognizing) return;
    setState(() => _activeStroke.add(d.localPosition));
  }

  void _onPanEnd(DragEndDetails _) {
    if (_showResult || _recognizing || _activeStroke.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final inkPoints = _activeStroke.asMap().entries.map((e) {
      return InkPoint(point: e.value, t: now + e.key);
    }).toList();
    setState(() {
      _inkStrokes.add(InkStroke(points: inkPoints));
      _paintStrokes.add(List.from(_activeStroke));
      _activeStroke = [];
    });
  }

  void _clearCanvas() {
    setState(() {
      _inkStrokes.clear();
      _paintStrokes.clear();
      _activeStroke = [];
      _recognizedText = null;
    });
  }

  // ── Recognition ─────────────────────────────────────────────────────────────

  Future<void> _verify() async {
    if (_inkStrokes.isEmpty || _recognizing || !_modelReady) return;
    setState(() => _recognizing = true);
    try {
      final candidates = await _recognizer.recognize(Ink(strokes: _inkStrokes));
      final recognized = candidates.isNotEmpty ? candidates.first.text : '';
      final child = ref.read(selectedChildProvider);
      final age = child?.age ?? 9;
      final correct = _isMatch(recognized, _current.german, age);

      setState(() {
        _recognizedText = recognized;
        _isCorrect = correct;
        _showResult = true;
        _recognizing = false;
      });

      await _persistResult(correct);
    } catch (_) {
      setState(() => _recognizing = false);
    }
  }

  Future<void> _persistResult(bool correct) async {
    final child = ref.read(selectedChildProvider);
    final lesson = ref.read(selectedLessonProvider);
    if (child == null || lesson == null) return;
    final fs = ref.read(firestoreServiceProvider);
    final item = _current;

    if (_phase == _StudyPhase.mainRound) {
      item.handwrittenAttempts++;
      if (correct) {
        item.handwrittenCorrect++;
        item.dominated = true;
        setState(() {
          _pointsEarned += AppConstants.pointsHandwritten;
          _wordsCorrect++;
        });
        await fs.addPoints(child.id, AppConstants.pointsHandwritten);
        // dominateWord updates wordsDominated counter + lesson status
        await fs.dominateWord(child.id, lesson.id, item);
      } else {
        item.addedToReviewRound = true;
        await fs.updateVocabItem(child.id, lesson.id, item);
      }
    } else {
      if (correct) {
        item.reviewRoundPassed = true;
        item.dominated = true;
        setState(() {
          _pointsEarned += AppConstants.pointsHandwritten;
          _wordsCorrect++;
        });
        await fs.addPoints(child.id, AppConstants.pointsHandwritten);
        await fs.dominateWord(child.id, lesson.id, item);
      } else {
        await fs.updateVocabItem(child.id, lesson.id, item);
      }
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _next() {
    final list = _activeList;
    if (_currentIndex < list.length - 1) {
      setState(() {
        _currentIndex++;
        _showResult = false;
        _isCorrect = null;
        _clearCanvas();
      });
      return;
    }

    if (_phase == _StudyPhase.mainRound) {
      final failed = _mainVocab.where((v) => v.addedToReviewRound).toList();
      if (failed.isEmpty) {
        _finish(perfectRound: false);
      } else {
        setState(() {
          _reviewList = failed;
          _currentIndex = 0;
          _phase = _StudyPhase.reviewRound;
          _showResult = false;
          _isCorrect = null;
          _clearCanvas();
        });
      }
    } else {
      final allPassed = _reviewList.every((v) => v.reviewRoundPassed);
      _finish(perfectRound: allPassed);
    }
  }

  Future<void> _finish({required bool perfectRound}) async {
    if (perfectRound) {
      final child = ref.read(selectedChildProvider);
      final lesson = ref.read(selectedLessonProvider);
      if (child != null && lesson != null) {
        final fs = ref.read(firestoreServiceProvider);
        setState(() => _pointsEarned += AppConstants.pointsPerfectRound);
        await fs.addPoints(child.id, AppConstants.pointsPerfectRound);
        await fs.setPerfectRound(child.id, lesson.id);
      }
    }
    if (!mounted) return;
    final lesson = ref.read(selectedLessonProvider);
    final totalAttempted = _mainVocab.length + (_reviewList.isNotEmpty ? _reviewList.length : 0);
    context.pushReplacement(
      AppRoutes.studyComplete,
      extra: SessionResult(
        pointsEarned: _pointsEarned,
        wordsAttempted: totalAttempted,
        wordsCorrect: _wordsCorrect,
        mode: 'handwriting',
        lessonTitle: lesson?.title ?? '',
      ),
    );
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(selectedLessonProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: Text(lesson?.title ?? 'Escritura'),
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
          ? const Center(child: CircularProgressIndicator(color: AppColors.violet))
          : _mainVocab.isEmpty
              ? _buildEmpty()
              : _buildStudy(),
    );
  }

  Widget _buildStudy() {
    final list = _activeList;
    final progress = (_currentIndex + 1) / list.length;
    final item = _current;

    return Column(
      children: [
        // Progress + phase indicator
        Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.paleGray,
              valueColor: AlwaysStoppedAnimation(
                _phase == _StudyPhase.reviewRound ? AppColors.berry : AppColors.violet,
              ),
            ),
            if (_phase == _StudyPhase.reviewRound)
              Container(
                width: double.infinity,
                color: AppColors.berry.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '🔄 Ronda de repaso — ${_currentIndex + 1}/${list.length}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(color: AppColors.berry),
                ),
              ),
          ],
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                // Counter row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_currentIndex + 1} de ${list.length}',
                      style: AppTextStyles.caption,
                    ),
                    Text(
                      '✅ $_wordsCorrect dominadas',
                      style: AppTextStyles.caption.copyWith(color: AppColors.grass),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Prompt card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cloud,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '¿Cómo se escribe en alemán?',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.spanish,
                        style: AppTextStyles.headline,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms).scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1, 1)),

                const SizedBox(height: 20),

                // Drawing canvas
                _buildCanvas(),

                const SizedBox(height: 12),

                // Model download notice
                if (_modelDownloading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Descargando modelo de escritura...',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),

                // Result banner
                if (_showResult && _recognizedText != null)
                  _buildResultBanner(item).animate().fadeIn().slideY(begin: 0.2, end: 0),

                const SizedBox(height: 16),

                // Action buttons
                if (!_showResult)
                  _buildActionButtons()
                else
                  _buildNextButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanvas() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _showResult
              ? (_isCorrect == true ? AppColors.grass : AppColors.berry)
              : AppColors.violet.withValues(alpha: 0.3),
          width: _showResult ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: _InkPainter(
            strokes: _paintStrokes,
            activeStroke: _activeStroke,
          ),
          child: _inkStrokes.isEmpty && _activeStroke.isEmpty
              ? Center(
                  child: Text(
                    '✏️ Escribe aquí',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.25),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildResultBanner(VocabItem item) {
    final correct = _isCorrect == true;
    final color = correct ? AppColors.grass : AppColors.berry;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            correct ? '🎉 ¡Excelente! Palabra dominada' : '❌ Casi...',
            style: AppTextStyles.bodyBold.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_recognizedText!.isNotEmpty)
            Text(
              'Reconocí: "$_recognizedText"',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.ink.withValues(alpha: 0.5),
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
              '+${AppConstants.pointsHandwritten} puntos ⭐',
              style: AppTextStyles.label.copyWith(color: AppColors.sun),
            ),
          ],
          if (!correct && _phase == _StudyPhase.mainRound)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Se agregará a la ronda de repaso al final',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.45),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () =>
                ref.read(ttsServiceProvider).speakGerman(item.german),
            icon: const Icon(Icons.volume_up_rounded),
            label: const Text('Escuchar pronunciación'),
            style: TextButton.styleFrom(foregroundColor: color),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final canVerify = _inkStrokes.isNotEmpty && _modelReady && !_recognizing;

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: OutlinedButton.icon(
            onPressed: _inkStrokes.isEmpty ? null : _clearCanvas,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Borrar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: BorderSide(color: AppColors.ink.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: canVerify ? _verify : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.violet,
              foregroundColor: AppColors.cloud,
              disabledBackgroundColor: AppColors.paleGray,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _recognizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    '✅ Verificar',
                    style: AppTextStyles.bodyBold.copyWith(color: AppColors.cloud),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    final list = _activeList;
    final isLast = _currentIndex >= list.length - 1;
    final label = isLast
        ? (_phase == _StudyPhase.mainRound && _mainVocab.any((v) => v.addedToReviewRound)
            ? '🔄 Ronda de repaso'
            : '🏁 Terminar')
        : '➡️ Siguiente';

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mint,
          foregroundColor: AppColors.cloud,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyBold.copyWith(color: AppColors.cloud),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text('Esta lección no tiene palabras todavía 📭'),
    );
  }
}

// ── Ink painter ──────────────────────────────────────────────────────────────

class _InkPainter extends CustomPainter {
  const _InkPainter({required this.strokes, required this.activeStroke});

  final List<List<Offset>> strokes;
  final List<Offset> activeStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2D2B55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    void drawStroke(List<Offset> pts) {
      if (pts.length < 2) {
        if (pts.length == 1) canvas.drawCircle(pts.first, 2, paint);
        return;
      }
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    for (final s in strokes) drawStroke(s);
    drawStroke(activeStroke);
  }

  @override
  bool shouldRepaint(_InkPainter old) =>
      old.strokes != strokes || old.activeStroke != activeStroke;
}
