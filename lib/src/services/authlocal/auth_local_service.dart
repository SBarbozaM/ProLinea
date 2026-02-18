import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class AuthLocalService {
  static final _auth = LocalAuthentication();

  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Confirma tu identidad para acceder',
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Autenticación requerida',
            cancelButton: 'Cancelar',
          ),
          IOSAuthMessages(
            cancelButton: 'Cancelar',
          ),
        ],
      );
    } on LocalAuthException catch (e) {
      return false;
    }
  }
}