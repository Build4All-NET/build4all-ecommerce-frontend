// lib/core/network/connecting(wifiORserver)/connection_cubit.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connection_status.dart';

class ConnectionStateModel {
  final ConnectionStatus status;
  final String? message;

  const ConnectionStateModel({
    required this.status,
    this.message,
  });

  ConnectionStateModel copyWith({
    ConnectionStatus? status,
    String? message,
  }) {
    return ConnectionStateModel(
      status: status ?? this.status,
      message: message,
    );
  }
}

/// Drives the connection banner from two signals, neither of which polls:
///
///  * the device's connectivity stream, for "no internet";
///  * the app's own traffic, for "server unreachable" — every request already
///    reports back through [setOnline] and [setServerDown].
///
/// This used to run a heartbeat as well: an unauthenticated GET on the API root
/// every 10 seconds. In a browser that request is a liability rather than a
/// signal — the API root is not an endpoint the app otherwise calls, so it
/// answers without CORS headers, and on an https page an http API is blocked
/// outright. Either way it failed, and the banner sat on "reconnecting" while
/// the app's real requests were succeeding beside it.
class ConnectionCubit extends Cubit<ConnectionStateModel> {
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _serverDownDebounce;

  bool _hasInternet = true;

  /// Brief grace period so a single failed request does not flash the banner.
  static const Duration _serverDownDelay = Duration(seconds: 2);

  ConnectionCubit({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(const ConnectionStateModel(status: ConnectionStatus.online)) {
    _init();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    _updateFromResults(results);

    _subscription = _connectivity.onConnectivityChanged.listen(
      _updateFromResults,
    );
  }

  void _updateFromResults(List<ConnectivityResult> results) {
    final hasInternet = results.any((r) => r != ConnectivityResult.none);
    _hasInternet = hasInternet;

    if (!hasInternet) {
      _emitOffline();
      return;
    }

    _clearServerDownDebounce();

    // Assume the server is reachable again once the device is back online. The
    // next request the app makes settles it either way.
    if (state.status != ConnectionStatus.online) {
      emit(const ConnectionStateModel(
        status: ConnectionStatus.online,
        message: null,
      ));
    }
  }

  void _emitOffline() {
    _clearServerDownDebounce();

    if (state.status != ConnectionStatus.offline) {
      emit(const ConnectionStateModel(
        status: ConnectionStatus.offline,
        message: null,
      ));
    }
  }

  void _clearServerDownDebounce() {
    _serverDownDebounce?.cancel();
    _serverDownDebounce = null;
  }

  void _markServerDown(String message) {
    if (!_hasInternet) {
      _emitOffline();
      return;
    }

    _serverDownDebounce ??= Timer(_serverDownDelay, () {
      _serverDownDebounce = null;

      if (!_hasInternet) {
        _emitOffline();
        return;
      }

      emit(ConnectionStateModel(
        status: ConnectionStatus.serverDown,
        message: message,
      ));
    });
  }

  /// Reported by the networking layer when a request cannot reach the server.
  void setServerDown([String? message]) {
    _markServerDown(message ?? 'Server is not responding');
  }

  /// Reported by the networking layer when a request succeeds.
  void setOnline() {
    _hasInternet = true;
    _clearServerDownDebounce();

    if (state.status != ConnectionStatus.online || state.message != null) {
      emit(const ConnectionStateModel(
        status: ConnectionStatus.online,
        message: null,
      ));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _clearServerDownDebounce();
    return super.close();
  }
}
