import 'dart:async';

import 'package:embarques_tdp/main.dart';
import 'package:embarques_tdp/src/components/conexionInternet.dart';
import 'package:flutter/widgets.dart';

class ConnectionStatusProvider extends ChangeNotifier {
  late StreamSubscription _connectionSubscription;

  ConnectionStatus _status = ConnectionStatus.online;

  ConnectionStatus get status => _status;

  ConnectionStatusProvider() {
    _connectionSubscription = internetChecker.internetStatus().listen((newStatus) {
      _status = newStatus;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }
}
