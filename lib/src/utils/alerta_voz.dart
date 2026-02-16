import 'package:flutter_tts/flutter_tts.dart';

class VelocidadAlerta {
  final FlutterTts flutterTts = FlutterTts();

  Future<void> alertarExcesoVelocidad(double velocidad, double velocidadPermitida) async {
    if (velocidad > velocidadPermitida) {
      // Mensaje de alerta
      String mensaje = "Te estás excediendo de velocidad. Reduce la velocidad inmediatamente.";

      // Configurar idioma
      await flutterTts.setLanguage("es-ES"); // Español
      await flutterTts.setPitch(1.0); // Tono normal

      // Reproducir mensaje
      await flutterTts.speak(mensaje);
    }
  }
}
