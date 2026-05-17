import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/constants/app_constants.dart';

final parentAuthServiceProvider =
    Provider<ParentAuthService>((ref) => ParentAuthService());

// true mientras dure la sesión de padres (se resetea al salir)
final parentSessionProvider = StateProvider<bool>((ref) => false);

class ParentAuthService {
  final _localAuth = LocalAuthentication();
  static const _storage = FlutterSecureStorage();

  Future<bool> get isPinSet async {
    final val = await _storage.read(key: AppConstants.keyParentPinSet);
    return val == 'true';
  }

  Future<bool> authenticate() async {
    // 1. Intentar biometría
    final canUseBiometrics = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();

    if (canUseBiometrics && isDeviceSupported) {
      try {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Accede a la Zona de Padres',
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
          ),
        );
        return authenticated;
      } catch (_) {
        // Fallback a PIN si biometría falla
      }
    }
    return false;
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: AppConstants.keyParentPin);
    return stored == pin;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: AppConstants.keyParentPin, value: pin);
    await _storage.write(key: AppConstants.keyParentPinSet, value: 'true');
  }
}
