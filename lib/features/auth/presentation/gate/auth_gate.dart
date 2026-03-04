// lib/features/auth/presentation/gate/auth_gate.dart

import 'package:build4front/core/config/env.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/utils/jwt_utils.dart';
import 'package:build4front/core/network/globals.dart' as g;

import 'package:build4front/core/realtime/realtime_cubit.dart';

import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/features/auth/data/services/auth_token_store.dart';
import 'package:build4front/features/auth/data/services/session_role_store.dart';

import 'package:build4front/features/auth/presentation/login/bloc/auth_bloc.dart';
import 'package:build4front/features/auth/presentation/login/bloc/auth_event.dart';

import 'package:build4front/features/auth/presentation/login/screens/user_login_screen.dart';
import 'package:build4front/features/shell/presentation/screens/main_shell.dart';

import 'package:build4front/l10n/app_localizations.dart';

class AuthGate extends StatefulWidget {
  final AppConfig appConfig;
  const AuthGate({super.key, required this.appConfig});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _roleStore = SessionRoleStore();
  final _adminStore = const AdminTokenStore();
  final _userStore = AuthTokenStore();

  bool _loading = true;

  bool _appBlocked = false;
  String _blockReason = '';
  String _serverBlockMessage = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  // ------------------- helpers -------------------

  String _stripBearer(String? t) {
    final v = (t ?? '').trim();
    if (v.toLowerCase().startsWith('bearer ')) return v.substring(7).trim();
    return v;
  }

  String _currentTenantIdString() {
    // prefer runtime config, fallback env
    final fromConfig = widget.appConfig.ownerProjectId?.toString().trim();
    if (fromConfig != null && fromConfig.isNotEmpty) return fromConfig;
    return (Env.ownerProjectLinkId ?? '').toString().trim();
  }

  int _currentTenantIdInt() {
    return int.tryParse(_currentTenantIdString()) ?? 0;
  }

  void _startRealtimeForAdmin(String rawJwt) {
    if (!mounted) return;

    final token = rawJwt.trim();
    final tenant = _currentTenantIdInt();

    debugPrint('[RT] AuthGate startRealtime(admin) tokenEmpty=${token.isEmpty} tenant=$tenant');

    // Admin is logged in => token exists, but still guard
    if (token.isEmpty || tenant <= 0) return;

    // ✅ MATCH MainShell signature
    context.read<RealtimeCubit>().bind(
          tokenMaybeBearerOrRaw: token,
          tenantId: tenant,
        );
  }

  void _stopRealtime() {
    if (!mounted) return;
    try {
      // ✅ disconnect
      context.read<RealtimeCubit>().bind(
            tokenMaybeBearerOrRaw: '',
            tenantId: 0,
          );
    } catch (_) {}
  }

  Future<void> _logoutAll() async {
    await _userStore.clear();
    await _adminStore.clear();
    await _roleStore.clear();
    g.setAuthToken('');
    _stopRealtime();
  }

  Future<void> _enforceTenantMatchOrLogout() async {
    final current = _currentTenantIdString();
    if (current.isEmpty) return; // fail-open

    final savedUser = (await _userStore.getTenantId())?.trim() ?? '';
    final savedAdmin = (await _adminStore.getTenantId())?.trim() ?? '';

    // ✅ only treat as mismatch if saved value exists
    final mismatchUser = savedUser.isNotEmpty && savedUser != current;
    final mismatchAdmin = savedAdmin.isNotEmpty && savedAdmin != current;

    if (mismatchUser || mismatchAdmin) {
      await _logoutAll();
    }
  }

  // ------------------- public access -------------------

  Future<bool> _checkPublicAppAccess() async {
    final linkId = widget.appConfig.ownerProjectId;
    if (linkId == null) return true;

    try {
      final res = await g.dio().get('/api/public/app-access/$linkId');
      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      if (data['allowed'] == true) return true;

      if (!mounted) return false;
      setState(() {
        _appBlocked = true;
        _blockReason = (data['reason'] ?? '').toString();
        _serverBlockMessage = (data['message'] ?? '').toString();
        _loading = false;
      });
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 410) {
        final raw = e.response?.data;
        final data = (raw is Map)
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};

        if (!mounted) return false;
        setState(() {
          _appBlocked = true;
          _blockReason = (data['reason'] ?? 'APP_NOT_AVAILABLE').toString();
          _serverBlockMessage = (data['message'] ?? '').toString();
          _loading = false;
        });
        return false;
      }
      return true;
    } catch (_) {
      return true;
    }
  }

  // ------------------- refresh -------------------

  Future<String?> _tryRefreshUserIfNeeded({
    required String? tokenStored,
    required bool userWasInactive,
  }) async {
    if (userWasInactive) return null;

    final refresh = (await _userStore.getRefreshToken())?.trim() ?? '';
    if (refresh.isEmpty) return null;

    final raw = _stripBearer(tokenStored);
    if (raw.isNotEmpty && !JwtUtils.isExpired(raw)) return raw;

    try {
      final res = await g.dio().post(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      final newAccess = _stripBearer((data['token'] ?? '').toString());
      final newRefresh = (data['refreshToken'] ?? '').toString().trim();
      if (newAccess.isEmpty || newRefresh.isEmpty) return null;

      await _userStore.saveToken(
        token: newAccess,
        wasInactive: false,
        refreshToken: newRefresh,
        tenantId: _currentTenantIdString(),
      );

      return newAccess;
    } catch (_) {
      await _userStore.clear();
      return null;
    }
  }

  Future<String?> _tryRefreshAdminIfNeeded({required String? tokenStored}) async {
    final refresh = (await _adminStore.getRefreshToken())?.trim() ?? '';
    if (refresh.isEmpty) return null;

    final raw = _stripBearer(tokenStored);
    if (raw.isNotEmpty && !JwtUtils.isExpired(raw)) return raw;

    try {
      final res = await g.dio().post(
        '/api/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      final newAccess = _stripBearer((data['token'] ?? '').toString());
      final newRefresh = (data['refreshToken'] ?? '').toString().trim();
      if (newAccess.isEmpty || newRefresh.isEmpty) return null;

      final role = (await _adminStore.getRole()) ?? '';

      await _adminStore.save(
        token: newAccess, // ✅ RAW
        role: role,
        refreshToken: newRefresh,
        tenantId: _currentTenantIdString(),
      );

      return newAccess;
    } catch (_) {
      await _adminStore.clear();
      return null;
    }
  }

  // ------------------- boot -------------------

  Future<void> _boot() async {
    await const AdminTokenStore().debugDump();

    try {
      final canOpen = await _checkPublicAppAccess();
      if (!canOpen) return;

      await _enforceTenantMatchOrLogout();

      final lastRole = await _roleStore.getRole();

      final adminStored = (await _adminStore.getToken())?.trim();
      final userStored = (await _userStore.getToken())?.trim();
      final userWasInactive = await _userStore.getWasInactive();

      final adminToken = await _tryRefreshAdminIfNeeded(tokenStored: adminStored);
      final userToken = await _tryRefreshUserIfNeeded(
        tokenStored: userStored,
        userWasInactive: userWasInactive,
      );

      final adminValid =
          adminToken != null && adminToken.isNotEmpty && !JwtUtils.isExpired(adminToken);
      final userValid =
          userToken != null && userToken.isNotEmpty && !JwtUtils.isExpired(userToken);
      final userAutoValid = userValid && !userWasInactive;

      if (!adminValid) await _adminStore.clear();
      if (!userValid) await _userStore.clear();

      if (!mounted) return;

      // ✅ IMPORTANT: apply token before navigating
      if (lastRole == 'admin' && adminValid) {
        _goAdminWithToken(adminToken!);
        return;
      }
      if (lastRole == 'user' && userAutoValid) {
        _hydrateUserAndGo(userToken!);
        return;
      }

      // if both valid but no lastRole -> ask
      if (adminValid &&
          userAutoValid &&
          (lastRole == null || lastRole.trim().isEmpty)) {
        setState(() => _loading = false);
        await _askRoleAndGo(adminToken!, userToken!);
        return;
      }

      // fallback priority
      if (adminValid) {
        _goAdminWithToken(adminToken!);
        return;
      }
      if (userAutoValid) {
        _hydrateUserAndGo(userToken!);
        return;
      }

      _goLogin();
    } catch (_) {
      if (!mounted) return;
      _goLogin();
    }
  }

  // ------------------- routing -------------------

  Future<void> _askRoleAndGo(String adminToken, String userToken) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final bl10n = AppLocalizations.of(ctx)!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text(
                bl10n.authGateContinueAs,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(bl10n.authGateRoleAdminOwner),
                onTap: () => Navigator.pop(ctx, 'admin'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(bl10n.authGateRoleUser),
                onTap: () => Navigator.pop(ctx, 'user'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted) return;

    if (choice == 'admin') {
      await _roleStore.saveRole('admin');
      _goAdminWithToken(adminToken);
      return;
    }
    if (choice == 'user') {
      await _roleStore.saveRole('user');
      _hydrateUserAndGo(userToken);
      return;
    }

    _goLogin();
  }

  void _hydrateUserAndGo(String rawJwt) {
    g.setAuthToken(rawJwt);

    // ❌ don't start realtime here (MainShell will do it once, with guards)
    context.read<AuthBloc>().add(
          AuthLoginHydrated(user: null, token: rawJwt, wasInactive: false),
        );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(appConfig: widget.appConfig)),
    );
  }

  void _goAdminWithToken(String rawJwt) {
    g.setAuthToken(rawJwt);

    // ✅ admin route might not have MainShell, so start realtime here
    _startRealtimeForAdmin(rawJwt);

    Navigator.of(context).pushNamedAndRemoveUntil('/admin', (_) => false);
  }

  void _goLogin() {
    g.setAuthToken('');
    _stopRealtime();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => UserLoginScreen(appConfig: widget.appConfig)),
    );
  }

  // ------------------- blocked UI -------------------

  String _titleForReason(AppLocalizations l10n, String reason) {
    switch (reason) {
      case 'APP_DELETED':
        return l10n.appAccessTitleDeleted;
      case 'APP_EXPIRED':
        return l10n.appAccessTitleExpired;
      default:
        return l10n.appAccessTitleUnavailable;
    }
  }

  String _messageForReason(AppLocalizations l10n, String reason) {
    switch (reason) {
      case 'APP_DELETED':
        return l10n.appAccessMessageDeleted;
      case 'APP_EXPIRED':
        return l10n.appAccessMessageExpired;
      default:
        return l10n.appAccessMessageUnavailable;
    }
  }

  IconData _iconForReason(String reason) {
    switch (reason) {
      case 'APP_DELETED':
        return Icons.block_rounded;
      case 'APP_EXPIRED':
        return Icons.timer_off_rounded;
      default:
        return Icons.no_accounts_rounded;
    }
  }

  Widget _buildBlockedFullScreen() {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleForReason(l10n, _blockReason);
    final message = _messageForReason(l10n, _blockReason);
    final icon = _iconForReason(_blockReason);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 34, child: Icon(icon, size: 34)),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(message, textAlign: TextAlign.center),
                    if (_serverBlockMessage.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_serverBlockMessage, textAlign: TextAlign.center),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!mounted) return;
                          setState(() {
                            _loading = true;
                            _appBlocked = false;
                            _blockReason = '';
                            _serverBlockMessage = '';
                          });
                          await _boot();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.appAccessRetry),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_appBlocked) return _buildBlockedFullScreen();
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return const Scaffold(body: SizedBox.shrink());
  }
}