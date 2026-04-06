// lib/core/network/connecting(wifiORserver)/connection_cubit.dart

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:build4front/core/config/env.dart';

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

class ConnectionCubit extends Cubit<ConnectionStateModel> {
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _serverDownDebounce;

  bool _hasInternet = true;
  DateTime? _lastServerFailureAt;

  static const Duration _heartbeatEvery = Duration(seconds: 10);
  static const Duration _pingTimeout = Duration(seconds: 5);
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

    if (state.status == ConnectionStatus.offline) {
      emit(const ConnectionStateModel(
        status: ConnectionStatus.online,
        message: null,
      ));
    }

    _startHeartbeat();
    _pingServer();
  }

  void _emitOffline() {
    _clearServerDownDebounce();
    _stopHeartbeat();
    _lastServerFailureAt = null;

    if (state.status != ConnectionStatus.offline) {
      emit(const ConnectionStateModel(
        status: ConnectionStatus.offline,
        message: null,
      ));
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer ??= Timer.periodic(
      _heartbeatEvery,
      (_) => _pingServer(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _clearServerDownDebounce() {
    _serverDownDebounce?.cancel();
    _serverDownDebounce = null;
  }

  Future<void> _pingServer() async {
    if (!_hasInternet || state.status == ConnectionStatus.offline) return;

    try {
      final uri = Uri.parse(Env.apiBaseUrl);
      await http.get(uri).timeout(_pingTimeout);

      _lastServerFailureAt = null;
      _clearServerDownDebounce();

      if (state.status != ConnectionStatus.online) {
        emit(const ConnectionStateModel(
          status: ConnectionStatus.online,
          message: null,
        ));
      }
    } catch (_) {
      _markServerDown('Server is not responding');
    }
  }

  void _markServerDown(String message) {
    if (!_hasInternet) {
      _emitOffline();
      return;
    }

    _lastServerFailureAt ??= DateTime.now();

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

  void setServerDown([String? message]) {
    _markServerDown(message ?? 'Server is not responding');
  }

  void setOnline() {
    _hasInternet = true;
    _lastServerFailureAt = null;
    _clearServerDownDebounce();
    _startHeartbeat();

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
    _stopHeartbeat();
    return super.close();
  }
}