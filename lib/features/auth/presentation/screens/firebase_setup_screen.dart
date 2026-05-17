import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Shown when Firebase fails to initialize — usually because the developer
/// forgot to run `flutterfire configure` and `lib/firebase_options.dart`
/// still contains placeholder API keys.
class FirebaseSetupScreen extends StatelessWidget {
  const FirebaseSetupScreen({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WörterAbenteuer — Setup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.pale,
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('🔧',
                        style: TextStyle(fontSize: 72),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Text(
                      'Configuración de Firebase requerida',
                      style: AppTextStyles.headline,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'La app necesita un proyecto de Firebase real para funcionar. '
                      'Ejecuta el siguiente comando en la carpeta del proyecto:',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _CodeBlock(
                      code:
                          'dart pub global activate flutterfire_cli\nflutterfire configure',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Esto sobrescribe lib/firebase_options.dart con tus claves '
                      'reales y agrega google-services.json en android/app/. '
                      'Reinicia la app después.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Detalle:',
                                style: AppTextStyles.label
                                    .copyWith(color: AppColors.error)),
                            const SizedBox(height: 4),
                            SelectableText(
                              errorMessage!,
                              style: AppTextStyles.caption.copyWith(
                                fontFamily: 'monospace',
                                color: AppColors.ink.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SelectableText(
              code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copiar',
            icon: const Icon(Icons.copy_rounded, color: Colors.white70),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiado al portapapeles')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
