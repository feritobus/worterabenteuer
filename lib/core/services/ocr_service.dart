import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<OcrResult> recognizeVocabSheet(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    return _parseColumnStructure(recognized);
  }

  void dispose() => _recognizer.close();

  // ── Column detection ───────────────────────────────────────

  OcrResult _parseColumnStructure(RecognizedText text) {
    if (text.blocks.isEmpty) {
      return OcrResult(words: [], sentences: [], confidence: 0);
    }

    // Flatten all lines with bounding box info
    final lines = <_OcrLine>[];
    for (final block in text.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isEmpty || t.length < 2) continue;
        if (_isNoise(t)) continue;
        final box = line.boundingBox;
        lines.add(_OcrLine(
          text: t,
          left: box.left,
          right: box.right,
          top: box.top,
          bottom: box.bottom,
          centerX: (box.left + box.right) / 2,
          centerY: (box.top + box.bottom) / 2,
        ));
      }
    }

    if (lines.isEmpty) {
      return OcrResult(words: [], sentences: [], confidence: 0);
    }

    // Sort by Y first
    lines.sort((a, b) => a.top.compareTo(b.top));

    // Find image width estimate
    final maxRight = lines.map((l) => l.right).reduce(max);
    final midX = maxRight / 2;

    // Split lines into left column (German) and right column (Spanish)
    // Allow 40% overlap zone for edge cases
    final leftCol =
        lines.where((l) => l.centerX < midX * 1.1).toList();
    final rightCol =
        lines.where((l) => l.centerX >= midX * 0.9).toList();

    // Match pairs by Y proximity (within 60px vertically)
    final pairs = <VocabPair>[];
    final usedRight = <int>{};

    for (final left in leftCol) {
      int? bestIdx;
      double bestDist = 60.0;

      for (int i = 0; i < rightCol.length; i++) {
        if (usedRight.contains(i)) continue;
        final dist = (rightCol[i].centerY - left.centerY).abs();
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }

      if (bestIdx == null) continue;
      usedRight.add(bestIdx);

      final rightLine = rightCol[bestIdx];

      // Determine which column is German vs Spanish
      final String german;
      final String spanish;

      if (_looksGerman(left.text) || !_looksSpanish(left.text)) {
        german = _cleanText(left.text);
        spanish = _cleanText(rightLine.text);
      } else {
        german = _cleanText(rightLine.text);
        spanish = _cleanText(left.text);
      }

      if (german.isEmpty || spanish.isEmpty) continue;

      final grammarNote = _extractGrammarNote(left.text);
      final type = _isSentence(german) ? 'sentence' : 'word';

      pairs.add(VocabPair(
        german: german,
        spanish: spanish,
        type: type,
        grammarNote: grammarNote,
      ));
    }

    final confidence =
        pairs.isEmpty ? 0.0 : min(1.0, pairs.length / 10.0);

    return OcrResult(
      words: pairs.where((p) => p.type == 'word').toList(),
      sentences: pairs.where((p) => p.type == 'sentence').toList(),
      confidence: confidence,
    );
  }

  // ── Noise filter ────────────────────────────────────────────

  bool _isNoise(String text) {
    final t = text.trim();
    // Pure numbers or fractions (page numbers, progress "3/10")
    if (RegExp(r'^\d+[\s\/\.\-]?\d*[\%]?$').hasMatch(t)) return true;
    // All-caps short strings — UI labels, buttons, tab names
    if (t == t.toUpperCase() && t.length <= 12 && !t.contains(' ')) return true;
    // Common textbook / app chrome patterns
    if (RegExp(
      r'^(Lektion|Kapitel|Seite|Einheit|Unit|Chapter|Page|'
      r'Übung|Exercise|Vocabulary|Vokabeln|Wörter|Anton|Antón|'
      r'Richtig|Falsch|Weiter|Zurück|Start|Ende|Pause|Stop|'
      r'Correct|Wrong|Next|Back|Score|Punkte)[\s\d\.\:\!]*$',
      caseSensitive: false,
    ).hasMatch(t)) return true;
    // Mostly non-letter characters (icons, bullet lines, separators)
    final letters = t.replaceAll(RegExp(r'[^a-zA-ZäöüÄÖÜßáéíóúñ]'), '');
    if (letters.length < t.length * 0.55) return true;
    // Single emoji or symbol lines
    if (RegExp(r'^[\p{So}\p{Sk}\p{Sm}\s]+$', unicode: true).hasMatch(t)) return true;
    return false;
  }

  // ── Heuristics ─────────────────────────────────────────────

  bool _looksGerman(String text) {
    final t = text.toLowerCase();
    // German articles and common patterns
    return t.startsWith('der ') ||
        t.startsWith('die ') ||
        t.startsWith('das ') ||
        t.startsWith('ein ') ||
        t.startsWith('eine ') ||
        t.contains('ü') ||
        t.contains('ö') ||
        t.contains('ä') ||
        t.contains('ß');
  }

  bool _looksSpanish(String text) {
    final t = text.toLowerCase();
    return t.startsWith('el ') ||
        t.startsWith('la ') ||
        t.startsWith('los ') ||
        t.startsWith('las ') ||
        t.startsWith('un ') ||
        t.startsWith('una ');
  }

  bool _isSentence(String text) {
    if (text.length > 20) return true;
    if (text.endsWith('.') || text.endsWith('!') || text.endsWith('?')) {
      return true;
    }
    return text.split(' ').length > 3;
  }

  String? _extractGrammarNote(String text) {
    // Match patterns like (Pl.), (+Stadt), (sing.)
    final match = RegExp(r'\(([^)]+)\)').firstMatch(text);
    return match?.group(1);
  }

  String _cleanText(String text) {
    return text
        .replaceAll(RegExp(r'^\d+[\.\)]\s*'), '')   // "1. " or "1)"
        .replaceAll(RegExp(r'^[a-z][\.\)]\s*'), '')  // "a) "
        .replaceAll(RegExp(r'[✓✗✔✘☑☒✅❌⭐🔊🎧]+'), '') // Antón UI icons
        .replaceAll(RegExp(r'\s{2,}'), ' ')           // collapse spaces
        .trim();
  }
}

// ── Data classes ────────────────────────────────────────────

class OcrResult {
  final List<VocabPair> words;
  final List<VocabPair> sentences;
  final double confidence;

  const OcrResult({
    required this.words,
    required this.sentences,
    required this.confidence,
  });

  List<VocabPair> get all => [...words, ...sentences];
  bool get isEmpty => words.isEmpty && sentences.isEmpty;
  int get totalCount => words.length + sentences.length;
}

class VocabPair {
  String german;
  String spanish;
  final String type; // 'word' | 'sentence'
  final String? grammarNote;

  VocabPair({
    required this.german,
    required this.spanish,
    required this.type,
    this.grammarNote,
  });

  VocabPair copyWith({String? german, String? spanish}) => VocabPair(
        german: german ?? this.german,
        spanish: spanish ?? this.spanish,
        type: type,
        grammarNote: grammarNote,
      );
}

class _OcrLine {
  final String text;
  final double left;
  final double right;
  final double top;
  final double bottom;
  final double centerX;
  final double centerY;

  const _OcrLine({
    required this.text,
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
    required this.centerX,
    required this.centerY,
  });
}
