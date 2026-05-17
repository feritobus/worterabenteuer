import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../constants/app_constants.dart';

/// Provides a single TTS instance for the whole app.
/// Disposed automatically when the ProviderContainer is torn down.
final ttsServiceProvider = Provider<TtsService>((ref) {
  final service = TtsService();
  ref.onDispose(service.dispose);
  return service;
});

class TtsService {
  TtsService() {
    _configure();
  }

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> _configure() async {
    try {
      await _tts.setLanguage(AppConstants.targetLocale); // de-DE
      await _tts.setSpeechRate(0.45); // slower, kid-friendly
      await _tts.setPitch(1.05);
      await _tts.awaitSpeakCompletion(true);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Speaks a German word/sentence. Strips German articles for cleaner audio
  /// when the caller wants ("der Hund" reads better as "der Hund"; keep them
  /// in for now — articles teach gender).
  Future<void> speakGerman(String text) async {
    if (!_ready) await _configure();
    final clean = text.trim();
    if (clean.isEmpty) return;
    await _tts.stop();
    await _tts.speak(clean);
  }

  Future<void> stop() => _tts.stop();

  Future<void> dispose() async {
    await _tts.stop();
  }
}
