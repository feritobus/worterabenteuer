import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../data/parent_auth_service.dart';

class ParentLoginScreen extends ConsumerStatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  ConsumerState<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends ConsumerState<ParentLoginScreen> {
  final List<String> _pin = [];
  bool _loading = false;
  bool _showPinInput = false;
  bool _isSettingPin = false;
  String? _errorMessage;
  String _firstPin = '';

  @override
  void initState() {
    super.initState();
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    setState(() => _loading = true);
    try {
      final service = ref.read(parentAuthServiceProvider);
      final success = await service.authenticate();
      if (success && mounted) {
        ref.read(parentSessionProvider.notifier).state = true;
        context.pushReplacement(AppRoutes.parentDashboard);
        return;
      }
    } catch (_) {}

    if (mounted) {
      final service = ref.read(parentAuthServiceProvider);
      final pinSet = await service.isPinSet;
      setState(() {
        _loading = false;
        _showPinInput = true;
        _isSettingPin = !pinSet;
      });
    }
  }

  void _onDigit(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin.add(digit);
      _errorMessage = null;
    });
    if (_pin.length == 4) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin.removeLast());
  }

  Future<void> _verifyPin() async {
    final service = ref.read(parentAuthServiceProvider);
    final entered = _pin.join();

    if (_isSettingPin) {
      if (_firstPin.isEmpty) {
        // Primera vez: guardar y pedir confirmación
        setState(() {
          _firstPin = entered;
          _pin.clear();
          _errorMessage = 'Repite el PIN para confirmar';
        });
      } else {
        // Confirmación
        if (entered == _firstPin) {
          await service.setPin(entered);
          if (mounted) {
            ref.read(parentSessionProvider.notifier).state = true;
            context.pushReplacement(AppRoutes.parentDashboard);
          }
        } else {
          setState(() {
            _pin.clear();
            _firstPin = '';
            _errorMessage = 'Los PINs no coinciden. Intenta de nuevo.';
          });
        }
      }
    } else {
      final valid = await service.verifyPin(entered);
      if (valid && mounted) {
        ref.read(parentSessionProvider.notifier).state = true;
        context.pushReplacement(AppRoutes.parentDashboard);
      } else {
        setState(() {
          _pin.clear();
          _errorMessage = 'PIN incorrecto. Intenta de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.cloud),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.cloud))
            : _showPinInput
                ? _PinPad(
                    pin: _pin,
                    isSettingPin: _isSettingPin,
                    isConfirming: _firstPin.isNotEmpty,
                    errorMessage: _errorMessage,
                    onDigit: _onDigit,
                    onDelete: _onDelete,
                    onBiometric: _tryBiometric,
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}

class _PinPad extends StatelessWidget {
  const _PinPad({
    required this.pin,
    required this.isSettingPin,
    required this.isConfirming,
    required this.errorMessage,
    required this.onDigit,
    required this.onDelete,
    required this.onBiometric,
  });

  final List<String> pin;
  final bool isSettingPin;
  final bool isConfirming;
  final String? errorMessage;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    String title;
    if (isSettingPin) {
      title = isConfirming ? 'Repite el PIN' : 'Crea tu PIN';
    } else {
      title = 'PIN de padres 🔐';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.headline.copyWith(color: AppColors.cloud),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 8),

          if (isSettingPin && !isConfirming)
            Text(
              'Elige un PIN de 4 dígitos para proteger\nla zona de padres',
              style: AppTextStyles.body.copyWith(
                color: AppColors.cloud.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),

          const SizedBox(height: 32),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final filled = i < pin.length;
              return AnimatedContainer(
                duration: 150.ms,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled ? AppColors.violet : Colors.transparent,
                  border: Border.all(
                    color: filled
                        ? AppColors.violet
                        : AppColors.cloud.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
              );
            }),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage!,
              style: AppTextStyles.label.copyWith(
                color: AppColors.berry,
              ),
              textAlign: TextAlign.center,
            ).animate().shake(duration: 400.ms),
          ],

          const SizedBox(height: 40),

          // Teclado numérico
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', 'del'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  if (key.isEmpty) {
                    return const SizedBox(width: 80, height: 64);
                  }
                  if (key == 'del') {
                    return _PinKey(
                      onTap: onDelete,
                      child: const Icon(Icons.backspace_outlined,
                          color: AppColors.cloud),
                    );
                  }
                  return _PinKey(
                    onTap: () => onDigit(key),
                    child: Text(
                      key,
                      style: AppTextStyles.headline
                          .copyWith(color: AppColors.cloud),
                    ),
                  );
                }).toList(),
              ),
            ),

          TextButton.icon(
            onPressed: onBiometric,
            icon: const Icon(Icons.fingerprint, color: AppColors.sky, size: 28),
            label: Text(
              'Usar biometría',
              style: AppTextStyles.label.copyWith(color: AppColors.sky),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.cloud.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }
}
