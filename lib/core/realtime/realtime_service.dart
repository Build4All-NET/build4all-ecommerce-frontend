import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/globals.dart' as g;

class RealtimeService {
  RealtimeService._();
  static final RealtimeService I = RealtimeService._();

  StompClient? _client;
  StompUnsubscribe? _unsub;

  final _events = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get events => _events.stream;

  bool get isActive => _client != null;

  /// token can be raw jwt or "Bearer ..."
  Future<void> connect({
    required String token,
    required int tenantId,
  }) async {
    await disconnect();

    final bearer = _toBearer(token);
    final wsUrl = _buildWsUrlNative();

    // ✅ don't send Authorization header if empty
    final headers =
        bearer.isEmpty ? <String, String>{} : <String, String>{'Authorization': bearer};

    debugPrint('[RT] connecting to $wsUrl tenant=$tenantId headers=${headers.isEmpty ? "none" : "auth"}');

    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        reconnectDelay: const Duration(seconds: 5),
        heartbeatIncoming: const Duration(seconds: 10),
        heartbeatOutgoing: const Duration(seconds: 10),

        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,

        onConnect: (StompFrame frame) {
          debugPrint('[RT] connected ✅');
          final topic = '/topic/tenant/$tenantId/events';
          debugPrint('[RT] subscribing => $topic');

          _unsub = _client!.subscribe(
            destination: topic,
            callback: (StompFrame f) {
              // ✅ 1) print raw ALWAYS (this is the truth)
              debugPrint('[RT] raw=${f.body}');
              

              final body = (f.body ?? '').trim();
              if (body.isEmpty) return;

              try {
                final decoded = jsonDecode(body);
                if (decoded is Map) {
                  _events.add(Map<String, dynamic>.from(decoded));
                } else {
                  debugPrint('[RT] decoded not a map: $decoded');
                }
              } catch (e) {
                debugPrint('[RT] json parse failed: $e');
              }
            },
          );
        },

        onStompError: (f) => debugPrint('[RT] stomp error: ${f.body}'),
        onWebSocketError: (e) => debugPrint('[RT] ws error: $e'),
        onWebSocketDone: () => debugPrint('[RT] ws done/disconnected'),
        onDisconnect: (f) => debugPrint('[RT] disconnected'),
      ),
    );

    _client!.activate();
  }

  Future<void> disconnect() async {
    try {
      _unsub?.call();
    } catch (_) {}
    _unsub = null;

    try {
      _client?.deactivate();
    } catch (_) {}
    _client = null;
  }

  // ---------------- helpers ----------------

  String _toBearer(String token) {
    final t = token.trim();
    if (t.isEmpty) return '';
    return t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
  }

  /// Build ws://host:port/api/ws-native from Env.apiBaseUrl + Env.wsPath
  String _buildWsUrlNative() {
    final httpBase = g.serverRootNoApi(); // removes trailing /api if exists
    final baseUri = Uri.parse(httpBase);

    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final host = baseUri.host;
    final port = baseUri.hasPort ? baseUri.port : (wsScheme == 'wss' ? 443 : 80);

    // Env.wsPath default /api/ws => native is /api/ws-native
    final p = Env.wsPath.trim().isEmpty ? '/api/ws' : Env.wsPath.trim();
    final clean = p.startsWith('/') ? p : '/$p';
    final nativePath =
        clean.endsWith('-native') ? clean : '${clean.replaceAll(RegExp(r'/+$'), '')}-native';

    return Uri(
      scheme: wsScheme,
      host: host,
      port: port,
      path: nativePath,
    ).toString();
  }
}