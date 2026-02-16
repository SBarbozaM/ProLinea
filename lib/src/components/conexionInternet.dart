import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/subjects.dart';

enum ConnectionStatus {
  online,
  offline,
}

class VerificarConexionInternet {
  final Connectivity _connectivity = Connectivity();

  final _controller = BehaviorSubject.seeded(ConnectionStatus.online);

  StreamSubscription? _connectionSubscription;

  VerificarConexionInternet() {
    _verificarConexionInternet();
  }

  String get internet => _controller.value.name;

  Stream<ConnectionStatus> internetStatus() {
    _connectionSubscription ??= _connectivity.onConnectivityChanged
        .listen((_) => _verificarConexionInternet());

    return _controller.stream;
  }

  Future<void> _verificarConexionInternet() async {
    try {
      await Future.delayed(const Duration(
          seconds:
              3)); //RETRASO DE 3 SEGUNDOS PARA DARLE TIEMPO A QUE SE CONECTE BIEN A INTERNET

      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _controller.sink.add(ConnectionStatus.online);
      } else {
        _controller.sink.add(ConnectionStatus.offline);
      }
    } on SocketException catch (_) {
      _controller.sink.add(ConnectionStatus.offline);
    }
  }

  Future<void> close() async {
    await _connectionSubscription?.cancel();
    await _controller.close();
  }
}
