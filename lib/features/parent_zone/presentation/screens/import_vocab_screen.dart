import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/ocr_service.dart';
import '../../../../shared/widgets/kid_button.dart';

enum ImportSource { anton, printedSheet }

final _processingProvider = StateProvider<bool>((ref) => false);
final _errorProvider = StateProvider<String?>((ref) => null);

class ImportVocabScreen extends ConsumerWidget {
  const ImportVocabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(_processingProvider);
    final error = ref.watch(_errorProvider);

    return Scaffold(
      backgroundColor: AppColors.pale,
      appBar: AppBar(
        title: const Text('Importar vocabulario'),
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
            Text(
              '¿Cómo quieres importar?',
              style: AppTextStyles.headline,
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 8),

            Text(
              'Saca una foto a la lista de tu hijo o '
              'sube una captura de pantalla de la app.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

            const SizedBox(height: 32),

            if (isProcessing)
              _ProcessingIndicator()
            else ...[
              // Opción A — Antón (screenshot)
              _SourceCard(
                emoji: '📱',
                title: 'Captura de Antón',
                subtitle: 'Screenshot de la app Antón',
                color: AppColors.sky,
                onCamera: () =>
                    _pickAndProcess(context, ref, ImportSource.anton, ImageSource.camera),
                onGallery: () =>
                    _pickAndProcess(context, ref, ImportSource.anton, ImageSource.gallery),
              ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 16),

              // Opción B — Hoja impresa
              _SourceCard(
                emoji: '📄',
                title: 'Hoja impresa',
                subtitle: 'Paul, Lisa & Co u otra lista',
                color: AppColors.violet,
                onCamera: () =>
                    _pickAndProcess(context, ref, ImportSource.printedSheet, ImageSource.camera),
                onGallery: () =>
                    _pickAndProcess(context, ref, ImportSource.printedSheet, ImageSource.gallery),
              ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.1, end: 0),

              const SizedBox(height: 28),

              // Manual
              OutlinedButton.icon(
                onPressed: () => _goToReviewEmpty(context),
                icon: const Icon(Icons.edit_note_rounded),
                label: const Text('Ingresar manualmente'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: AppColors.violet),
                  foregroundColor: AppColors.violet,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ],

            if (error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: AppTextStyles.label
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Tips
            _TipsCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndProcess(
    BuildContext context,
    WidgetRef ref,
    ImportSource source,
    ImageSource imageSource,
  ) async {
    ref.read(_errorProvider.notifier).state = null;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: imageSource,
      imageQuality: 85,
      maxWidth: 2048,
    );

    if (picked == null) return;

    ref.read(_processingProvider.notifier).state = true;

    try {
      final ocrService = OcrService();
      final result = await ocrService.recognizeVocabSheet(picked.path);
      ocrService.dispose();

      if (!context.mounted) return;

      if (result.isEmpty) {
        ref.read(_errorProvider.notifier).state =
            'No se detectó vocabulario en la imagen. '
            'Intenta con otra foto más clara.';
        return;
      }

      context.push(AppRoutes.ocrReview, extra: result);
    } catch (e) {
      ref.read(_errorProvider.notifier).state =
          'Error al procesar la imagen: $e';
    } finally {
      ref.read(_processingProvider.notifier).state = false;
    }
  }

  void _goToReviewEmpty(BuildContext context) {
    final emptyResult = OcrResult(words: [], sentences: [], confidence: 1.0);
    context.push(AppRoutes.ocrReview, extra: emptyResult);
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onCamera,
    required this.onGallery,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.title.copyWith(color: color)),
                  Text(subtitle,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.ink.withValues(alpha: 0.5))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: KidButton(
                  label: '📷 Cámara',
                  onPressed: onCamera,
                  color: color,
                  height: 52,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KidButton(
                  label: '🖼️ Galería',
                  onPressed: onGallery,
                  color: color.withValues(alpha: 0.15),
                  textColor: color,
                  height: 52,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProcessingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.cloud,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.violet),
          const SizedBox(height: 20),
          Text(
            'Analizando imagen...',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 8),
          Text(
            'Detectando vocabulario automáticamente',
            style: AppTextStyles.body
                .copyWith(color: AppColors.ink.withValues(alpha: 0.5)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(duration: 1500.ms, color: AppColors.violet.withValues(alpha: 0.1));
  }
}

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('💡 Tips para mejores resultados',
              style:
                  AppTextStyles.label.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final tip in [
            'Fotografía con buena luz y sin sombras',
            'Mantén la hoja plana y centrada',
            'Para capturas de pantalla, asegúrate que el texto sea legible',
            'Puedes editar los pares después de importar',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('• $tip',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.ink.withValues(alpha: 0.7))),
            ),
        ],
      ),
    );
  }
}
