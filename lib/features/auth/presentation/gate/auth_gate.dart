import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/utils/jwt_utils.dart';
import 'package:build4front/core/network/globals.dart' as g;

import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/features/auth/data/services/auth_token_store.dart';
import 'package:build4front/features/auth/data/services/session_role_store.dart';

import 'package:build4front/features/auth/presentation/login/bloc/auth_bloc.dart';
import 'package:build4front/features/auth/presentation/login/bloc/auth_event.dart';

import 'package:build4front/features/auth/presentation/login/screens/user_login_screen.dart';
import 'package:build4front/features/shell/presentation/screens/main_shell.dart';

// ✅ l10n import
import 'package:build4front/l10n/app_localizations.dart';

class AuthGate extends StatefulWidget {
  final AppConfig appConfig;
  const AuthGate({super.key, required this.appConfig});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _roleStore = SessionRoleStore();
  final _adminStore = AdminTokenStore();
  final _userStore = AuthTokenStore();

  bool _loading = true;

  // ✅ app access block state
  bool _appBlocked = false;
  String _blockReason = '';
  String _serverBlockMessage = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  // ✅ public check (no token)
  Future<bool> _checkPublicAppAccess() async {
    // IMPORTANT:
    // this value should be AUP LINK ID (ownerProjectLinkId), not plain projectId
    final linkId = widget.appConfig.ownerProjectId;

    // If missing config, don't block app (fail-open)
    if (linkId == null) return true;

    try {
      final res = await g.dio().get('/api/public/app-access/$linkId');

      final data = (res.data is Map)
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};

      final allowed = data['allowed'] == true;

      if (!allowed) {
        if (!mounted) return false;
        setState(() {
          _appBlocked = true;
          _blockReason = (data['reason'] ?? '').toString();
          _serverBlockMessage = (data['message'] ?? '').toString();
          _loading = false;
        });
        return false;
      }

      return true;
    } on DioException catch (e) {
      // Backend may return 410 Gone for deleted/expired/not found
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

      // Network issue? Timeout? Offline?
      // Don't lock users out just because check failed to reach server
      return true;
    } catch (_) {
      // Unexpected parsing error -> fail-open
      return true;
    }
  }

  Future<void> _boot() async {
    try {
      // ✅ FIRST: check public app access
      final canOpen = await _checkPublicAppAccess();
      if (!canOpen) return;

      final lastRole = await _roleStore.getRole();

      final adminToken = await _adminStore.getToken();
      final userToken = await _userStore.getToken();
      final userWasInactive = await _userStore.getWasInactive();

      final adminValid =
          adminToken != null &&
          adminToken.isNotEmpty &&
          !JwtUtils.isExpired(adminToken);

      final userValid =
          userToken != null &&
          userToken.isNotEmpty &&
          !JwtUtils.isExpired(userToken);

      // ✅ if wasInactive == true, do NOT auto-login
      final userAutoValid = userValid && !userWasInactive;

      // cleanup expired
      if (adminToken != null && !adminValid) await _adminStore.clear();
      if (userToken != null && !userValid) await _userStore.clear();

      if (!mounted) return;

      // ✅ set global token if entering user flow
      if (userAutoValid) {
        g.setAuthToken(userToken!);
      }

      // both valid & no lastRole -> ask user
      if (adminValid && userAutoValid && lastRole == null) {
        setState(() => _loading = false);
        await _askRoleAndGo(adminToken!, userToken!);
        return;
      }

      // prefer last role
      if (lastRole == 'admin' && adminValid) {
        _goAdmin();
        return;
      }
      if (lastRole == 'user' && userAutoValid) {
        _hydrateUserAndGo(userToken!);
        return;
      }

      // fallback priority
      if (adminValid) {
        _goAdmin();
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

  Future<void> _askRoleAndGo(String adminToken, String userToken) async {
    final l10n = AppLocalizations.of(context)!;

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
      _goAdmin();
    } else if (choice == 'user') {
      await _roleStore.saveRole('user');

      // ✅ set global token before entering user flow
      g.setAuthToken(userToken);

      _hydrateUserAndGo(userToken);
    } else {
      // user dismissed sheet
      // keep same behavior (go login)
      _goLogin();
    }
  }

  void _hydrateUserAndGo(String token) {
    // ✅ ALWAYS set global token so UI can decode immediately
    g.setAuthToken(token);

    context.read<AuthBloc>().add(
      AuthLoginHydrated(user: null, token: token, wasInactive: false),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MainShell(appConfig: widget.appConfig)),
    );
  }

  void _goAdmin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/admin', (_) => false);
  }

  void _goLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => UserLoginScreen(appConfig: widget.appConfig),
      ),
    );
  }

  // ---------------- localized helpers ----------------

  String _titleForReason(AppLocalizations l10n, String reason) {
    switch (reason) {
      case 'APP_DELETED':
        return l10n.appAccessTitleDeleted;
      case 'APP_EXPIRED':
        return l10n.appAccessTitleExpired;
      case 'APP_NOT_AVAILABLE':
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
      case 'APP_NOT_AVAILABLE':
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
      case 'APP_NOT_AVAILABLE':
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
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: Offset(0, 8),
                      color: Color(0x1A000000),
                    ),
                  ],
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.25),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 34,
                      child: Icon(icon, size: 34),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.appAccessOwnerDisabledHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.75),
                      ),
                    ),

                    // optional: show server message if different / for debugging
                    if (_serverBlockMessage.isNotEmpty &&
                        _serverBlockMessage.trim().toLowerCase() !=
                            message.trim().toLowerCase()) ...[
                      const SizedBox(height: 10),
                      Text(
                        _serverBlockMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.65),
                        ),
                      ),
                    ],

                    if (_blockReason.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Theme.of(context)
                              .dividerColor
                              .withOpacity(0.12),
                        ),
                        child: Text(
                          _blockReason,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // keep user on blocked screen intentionally
                        },
                        icon: const Icon(Icons.lock_outline_rounded),
                        label: Text(l10n.appAccessBlockedButton),
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
    if (_appBlocked) {
      return _buildBlockedFullScreen();
    }

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return const Scaffold(body: SizedBox.shrink());
  }
}