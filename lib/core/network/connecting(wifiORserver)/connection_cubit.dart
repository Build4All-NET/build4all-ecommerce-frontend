// lib/core/network/connecting(wifiORserver)/connection_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'package:build4front/core/config/env.dart';

import 'connection_status.dart';

class ConnectionStateModel {
  final ConnectionStatus status;
  final String? message;

  const ConnectionStateModel({required this.status, this.message});

  ConnectionStateModel copyWith({
    ConnectionStatus? status,
    String? message,
  }) {
    return ConnectionStateModel(
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class ConnectionCubit extends Cubit<ConnectionStateModel> {
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _heartbeatTimer;

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
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _updateFromConnectivity(result);
  }

  void _updateFromConnectivity(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      emit(
        const ConnectionStateModel(
          status: ConnectionStatus.offline,
          message: null,
        ),
      );
      _stopHeartbeat();
      return;
    }

    if (state.status == ConnectionStatus.offline) {
      emit(
        const ConnectionStateModel(
          status: ConnectionStatus.online,
          message: null,
        ),
      );
    }

    _startHeartbeat();
    _pingServer();
  }

  void _startHeartbeat() {
    _heartbeatTimer ??= Timer.periodic(
      const Duration(seconds: 10),
      (_) => _pingServer(),
    );
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _pingServer() async {
    if (state.status == ConnectionStatus.offline) return;

    try {
      final uri = Uri.parse(Env.apiBaseUrl);
      await http.get(uri).timeout(const Duration(seconds: 5));

      if (state.status != ConnectionStatus.online) {
        emit(
          const ConnectionStateModel(
            status: ConnectionStatus.online,
            message: null,
          ),
        );
      }
    } catch (_) {
      if (state.status != ConnectionStatus.offline) {
        emit(
          const ConnectionStateModel(
            status: ConnectionStatus.serverDown,
            message: 'Server is not responding',
          ),
        );
      }
    }
  }

  void setServerDown([String? message]) {
    emit(
      ConnectionStateModel(
        status: ConnectionStatus.serverDown,
        message: message ?? 'Server is not responding',
      ),
    );
  }

  void setOnline() {
    emit(
      const ConnectionStateModel(
        status: ConnectionStatus.online,
        message: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _stopHeartbeat();
    return super.close();
  }
}