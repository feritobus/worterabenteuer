import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';

const _kOnboardingKey = 'onboarding_done_v1';

Future<bool> hasSeenOnboarding() async {
  const storage = FlutterSecureStorage();
  final val = await storage.read(key: _kOnboardingKey);
  return val == 'true';
}

Future<void> markOnboardingSeen() async {
  const storage = FlutterSecureStorage();
  await storage.write(key: _kOnboardingKey, value: 'true');
}

// ── Page data ────────────────────────────────────────────────────────────────

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final List<Color> gradientColors;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.gradientColors,
  });
}

const _pages = [
  _OnboardingPage(
    emoji: '🇩🇪',
    title: 'Bienvenido a\nWörterAbenteuer',
    subtitle: 'La aventura de aprender alemán',
    bullets: [
      '📚 Estudia el vocabulario de tu escuela',
      '🎮 Gana tiempo libre en pantalla',
      '🏆 Colecciona puntos y rachas',
    ],
    gradientColors: [AppColors.violet, AppColors.sky],
  ),
  _OnboardingPage(
    emoji: '✍️',
    title: 'Cuatro modos\nde estudio',
    subtitle: 'Cada uno vale puntos diferentes',
    bullets: [
      '🃏 Flash Cards → +1 pt (ver la palabra)',
      '⌨️ Teclado → +2 pts (escribir con teclado)',
      '✍️ Escritura → +7 pts (domina la palabra)',
      '🎙️ Voz → +7 pts (bono después de dominar)',
    ],
    gradientColors: [AppColors.mint, AppColors.sky],
  ),
  _OnboardingPage(
    emoji: '🎮',
    title: '¡Estudia y gana\ntiempo libre!',
    subtitle: 'Así funciona el sistema de premios',
    bullets: [
      '📖 1 minuto estudiando = 2.5 min de pantalla',
      '🌟 Ronda perfecta = +20 pts extra y paquetes bonus',
      '✅ Un papá o mamá aprueba desde su zona',
      '🔥 Mantén tu racha diaria para más puntos',
    ],
    gradientColors: [AppColors.grass, AppColors.mint],
  ),
];

// ── Screen ───────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await markOnboardingSeen();
    if (mounted) context.go(AppRoutes.children);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _OnboardingPageView(page: _pages[i]),
          ),

          // Bottom controls
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                                alpha: _currentPage == i ? 0.95 : 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),

                    // Next / Start button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _pages[_currentPage].gradientColors[0],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Siguiente →'
                              : '¡Vamos a empezar! 🚀',
                          style: AppTextStyles.bodyBold.copyWith(
                            color: _pages[_currentPage].gradientColors[0],
                          ),
                        ),
                      ),
                    ),

                    // Skip (only on non-last pages)
                    if (_currentPage < _pages.length - 1)
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Saltar',
                          style: AppTextStyles.label.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: page.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 60, 32, 180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji hero
              Text(page.emoji, style: const TextStyle(fontSize: 72))
                  .animate()
                  .scale(
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                  ),

              const SizedBox(height: 28),

              // Title
              Text(
                page.title,
                style: AppTextStyles.display2.copyWith(color: Colors.white),
              )
                  .animate()
                  .fadeIn(delay: 150.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0, delay: 150.ms),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                page.subtitle,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 36),

              // Bullets
              ...page.bullets.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.value.substring(0, 2),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value.substring(2),
                          style: AppTextStyles.body
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 350 + 100 * e.key),
                      duration: 350.ms,
                    )
                    .slideX(
                      begin: 0.1,
                      end: 0,
                      delay: Duration(milliseconds: 350 + 100 * e.key),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
