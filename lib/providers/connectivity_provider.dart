import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provee el estado de conectividad (true = conectado)
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) => ConnectivityNotifier());

class ConnectivityNotifier extends StateNotifier<bool> {
  StreamSubscription<ConnectivityResult>? _sub;

  ConnectivityNotifier() : super(true) {
    _init();
  }

  Future<void> _init() async {
    final connected = await _checkConnection();
    state = connected;
    _sub = Connectivity().onConnectivityChanged.listen((_) async {
      final ok = await _checkConnection();
      if (state != ok) state = ok;
    });
  }

  /// Realiza una comprobación simple intentando resolver un host
  Future<bool> _checkConnection() async {
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn == ConnectivityResult.none) return false;
      final lookup = await InternetAddress.lookup('example.com').timeout(const Duration(seconds: 5));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}