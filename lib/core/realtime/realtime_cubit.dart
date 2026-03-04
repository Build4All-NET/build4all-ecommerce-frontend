import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/env.dart';
import 'realtime_service.dart';

class RealtimeState extends Equatable {
  final int catalogTick;
  final Map<String, dynamic>? lastEvent;

  const RealtimeState({required this.catalogTick, this.lastEvent});

  RealtimeState copyWith({int? catalogTick, Map<String, dynamic>? lastEvent}) {
    return RealtimeState(
      catalogTick: catalogTick ?? this.catalogTick,
      lastEvent: lastEvent ?? this.lastEvent,
    );
  }

  @override
  List<Object?> get props => [catalogTick, lastEvent];
}

class RealtimeCubit extends Cubit<RealtimeState> {
  RealtimeCubit() : super(const RealtimeState(catalogTick: 0));

  StreamSubscription? _sub;
  Timer? _debounce;

  String _lastToken = '';
  int _lastTenant = 0;

  /// ✅ Connect even if token is empty (guest)
  Future<void> bind({String? tokenMaybeBearerOrRaw, int? tenantId}) async {
    final token = (tokenMaybeBearerOrRaw ?? '').trim();

    final resolvedTenant = tenantId ?? _tenantIdFromToken(token) ?? _tenantIdFromEnv();
    if (resolvedTenant <= 0) {
      // بدون tenant ما منقدر نعرف وين نعمل subscribe
      return;
    }

    // ✅ avoid reconnect spam
    if (_lastTenant == resolvedTenant && _lastToken == token && RealtimeService.I.isActive) {
      return;
    }

    _lastTenant = resolvedTenant;
    _lastToken = token;

    await RealtimeService.I.connect(
      token: token,        // may be empty -> service will NOT send auth header if you applied that fix
      tenantId: resolvedTenant,
    );

    await _sub?.cancel();
    _sub = RealtimeService.I.events.listen((evt) {
      emit(state.copyWith(lastEvent: evt));

      final domain = (evt['domain'] ?? '').toString().toLowerCase();
      final isCatalog = domain == 'product' || domain == 'stock' || domain == 'import';

      if (!isCatalog) return;

      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 400), () {
        emit(state.copyWith(catalogTick: state.catalogTick + 1));
      });
    });
  }

  int _tenantIdFromEnv() {
    return int.tryParse((Env.ownerProjectLinkId ?? '').toString()) ?? 0;
  }

  int? _tenantIdFromToken(String tokenMaybeBearer) {
    try {
      final t = tokenMaybeBearer.toLowerCase().startsWith('bearer ')
          ? tokenMaybeBearer.substring(7).trim()
          : tokenMaybeBearer.trim();

      if (t.isEmpty) return null;

      final parts = t.split('.');
      if (parts.length < 2) return null;

      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded);

      if (map is! Map) return null;

      final v = map['ownerProjectId']; // admin token
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);

      // ✅ if user token uses different claim, add here
      final v2 = map['ownerProjectLinkId'];
      if (v2 is num) return v2.toInt();
      if (v2 is String) return int.tryParse(v2);

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _sub?.cancel();
    await RealtimeService.I.disconnect();
    return super.close();
  }
}