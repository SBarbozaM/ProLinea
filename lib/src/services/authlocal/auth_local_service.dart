import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

class AuthLocalService {
  static final _auth = LocalAuthentication();

  /// Verifica si hay biometría disponible
  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Autenticación biométrica
  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para acceder',
        // ❌ Ya NO uses 'options: AuthenticationOptions(...)'
        // ✅ Ahora va directamente:
        authMessages:  <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticación requerida',
            cancelButton: 'Cancelar',
          ),
        ],
      );
    } catch (e) {
      return false;
    }
  }
}
