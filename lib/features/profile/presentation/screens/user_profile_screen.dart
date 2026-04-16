import 'package:build4front/app/app_router.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_event.dart';
import 'package:build4front/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:build4front/features/profile_edit/presentation/screens/edit_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/utils/jwt_utils.dart';
import 'package:build4front/features/auth/data/services/auth_token_store.dart';

import 'package:build4front/features/auth/presentation/login/bloc/auth_bloc.dart';
import 'package:build4front/features/auth/presentation/login/bloc/auth_event.dart';

import 'package:build4front/features/profile/presentation/bloc/user_profile_bloc.dart';
import 'package:build4front/features/profile/presentation/bloc/user_profile_event.dart';
import 'package:build4front/features/profile/presentation/bloc/user_profile_state.dart';

import 'package:build4front/features/profile/presentation/widgets/user_profile_header.dart';
import 'package:build4front/features/profile/presentation/widgets/deactivate_user_dialog.dart';

class UserProfileScreen extends StatefulWidget {
  final String token;
  final int userId;
  final void Function(Locale) onChangeLocale;
  final VoidCallback onLogout;

  const UserProfileScreen({
    super.key,
    required this.token,
    required this.userId,
    required this.onChangeLocale,
    required this.onLogout,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with WidgetsBindingObserver {
  final AuthTokenStore _store = const AuthTokenStore();

  bool _hydrating = true;
  bool _hydratingNow = false;
  bool _loggingOut = false;

  String _effectiveToken = '';
  int _effectiveUserId = 0;
  int _effectiveOwnerProjectLinkId = 0;

  String _lastToken = '';
  int _lastUserId = 0;
  int _lastOwnerId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hydrateSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _resetSessionUi() {
    context.read<CartBloc>().add(const CartReset());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_loggingOut) return;

    if (state == AppLifecycleState.resumed) {
      _hydrateSession();
    }
  }

  String _firstNonEmpty(List<String> values) {
    for (final v in values) {
      final s = v.trim();
      if (s.isNotEmpty) return s;
    }
    return '';
  }

  String _stripBearer(String t) {
    final s = t.trim();
    if (s.toLowerCase().startsWith('bearer ')) {
      return s.substring(7).trim();
    }
    return s;
  }

  int _envOwnerId() => int.tryParse(Env.ownerProjectLinkId) ?? 0;

  Future<void> _hydrateSession() async {
    if (_hydratingNow || _loggingOut) return;
    _hydratingNow = true;

    if (mounted) {
      setState(() => _hydrating = true);
    }

    try {
      final tWidget = widget.token.trim();
      final tGlobal = g.readAuthToken().trim();
      final tStored = (await _store.getToken())?.trim() ?? '';

      final tokenFull = _firstNonEmpty([tStored, tGlobal, tWidget]);
      final tokenRaw = _stripBearer(tokenFull);

      int id = 0;

      if (tokenRaw.isNotEmpty) {
        id = JwtUtils.userIdFromToken(tokenRaw) ?? 0;
      }

      if (id <= 0) id = widget.userId;

      if (id <= 0) {
        final storedId = await _store.getUserId();
        if (storedId > 0) id = storedId;
      }

      if (id <= 0) {
        final uj = await _store.getUserJson();
        final v = uj?['id'];
        if (v is num) id = v.toInt();
        if (v is String) id = int.tryParse(v.trim()) ?? 0;
      }

      if (tokenFull.isNotEmpty) {
        g.setAuthToken(tokenFull);
      }

      if (!mounted || _loggingOut) return;

      setState(() {
        _effectiveToken = tokenRaw;
        _effectiveUserId = id;
        _effectiveOwnerProjectLinkId = _envOwnerId();
        _hydrating = false;
      });

      _kickLoadIfNeeded();
    } finally {
      _hydratingNow = false;
    }
  }

  void _kickLoadIfNeeded() {
    if (_loggingOut) return;

    final token = _effectiveToken.trim();
    final id = _effectiveUserId;
    final ownerId = _effectiveOwnerProjectLinkId;

    if (token.isEmpty || id <= 0 || ownerId <= 0) return;

    if (token == _lastToken && id == _lastUserId && ownerId == _lastOwnerId) {
      return;
    }

    _lastToken = token;
    _lastUserId = id;
    _lastOwnerId = ownerId;

    if (!mounted || _loggingOut) return;

    context.read<UserProfileBloc>().add(
          LoadUserProfile(_effectiveToken, _effectiveUserId),
        );
  }

  Future<void> _retryProfileLoad() async {
    if (_loggingOut) return;

    await _hydrateSession();
    if (!mounted || _loggingOut) return;

    if (_effectiveToken.isEmpty || _effectiveUserId <= 0) return;

    context.read<UserProfileBloc>().add(
          LoadUserProfile(_effectiveToken, _effectiveUserId),
        );
  }

  Future<void> _goToLogin() async {
    if (!mounted || _loggingOut) return;

    _loggingOut = true;

    _lastToken = '';
    _lastUserId = 0;
    _lastOwnerId = 0;

    _resetSessionUi();

    widget.onLogout();
  }

  void _patchAuthFromProfile(UserProfileLoaded st) {
    final user = st.user;

    context.read<AuthBloc>().add(
          AuthUserPatched(
            firstName: user.firstName,
            lastName: user.lastName,
            username: user.username,
            profilePictureUrl: user.profilePictureUrl,
            isPublicProfile: user.isPublicProfile,
            status: user.status,
          ),
        );
  }

  Future<void> _goToEditProfile(int ownerProjectLinkId) async {
    if (_loggingOut) return;

    final navigator = Navigator.of(context);

    await navigator.push(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          userId: _effectiveUserId,
          token: _effectiveToken,
          ownerProjectLinkId: ownerProjectLinkId,
          onLogoutAfterDelete: () {
            _goToLogin();
          },
        ),
      ),
    );

    if (!mounted || _loggingOut) return;

    await _hydrateSession();
    if (!mounted || _loggingOut) return;

    context.read<UserProfileBloc>().add(
          LoadUserProfile(_effectiveToken, _effectiveUserId),
        );
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    if (_hydrating) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_effectiveToken.isEmpty || _effectiveUserId <= 0) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 48),
                const SizedBox(height: 12),
                Text(
                  tr.profileLoginRequired,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _goToLogin,
                  icon: const Icon(Icons.login),
                  label: Text(tr.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return BlocConsumer<UserProfileBloc, UserProfileState>(
      listener: (context, state) {
        if (_loggingOut) return;

        if (state is UserProfileLoaded) {
          _patchAuthFromProfile(state);

          final realOwnerId = state.user.ownerProjectLinkId;
          if (realOwnerId > 0 && realOwnerId != _effectiveOwnerProjectLinkId) {
            setState(() => _effectiveOwnerProjectLinkId = realOwnerId);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _kickLoadIfNeeded();
            });
          }
        }
      },
      builder: (context, state) {
        if (state is UserProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is UserProfileError) {
          final theme = Theme.of(context);
          final msg = state.message.toLowerCase();

          final loginRequired = msg.contains('unauthorized') ||
              msg.contains('401') ||
              msg.contains('please log in') ||
              msg.contains('please login');

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      loginRequired
                          ? Icons.lock_outline
                          : Icons.person_off_outlined,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loginRequired ? tr.sessionExpired : tr.profile_load_error,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: loginRequired ? _goToLogin : _retryProfileLoad,
                      icon: Icon(loginRequired ? Icons.login : Icons.refresh),
                      label: Text(loginRequired ? tr.login : tr.retry),
                    ),
                    const SizedBox(height: 8),
                    if (state.message.isNotEmpty)
                      Text(
                        state.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        if (state is UserProfileLoaded) {
          final user = state.user;
          final theme = Theme.of(context);

          final ownerId = _effectiveOwnerProjectLinkId > 0
              ? _effectiveOwnerProjectLinkId
              : _envOwnerId();

          return Scaffold(
            backgroundColor: theme.colorScheme.background,
            appBar: AppBar(),
            body: SafeArea(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  UserProfileHeader(user: user),
                  const SizedBox(height: 16),
                  _tile(
                    context,
                    icon: Icons.edit,
                    title: tr.editProfileTitle,
                    onTap: () => _goToEditProfile(ownerId),
                  ),
                  _tile(
                    context,
                    icon: Icons.language,
                    title: tr.language,
                    onTap: () => _showLanguageSelector(context),
                  ),
                  _tile(
                    context,
                    icon: Icons.receipt_long_outlined,
                    title: tr.ordersTitle,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRouter.myOrders),
                  ),
                  _tile(
                    context,
                    icon: Icons.privacy_tip,
                    title: tr.privacy_policy_title,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),
                  _tile(
                    context,
                    icon: Icons.logout,
                    title: tr.logout,
                    onTap: _confirmLogout,
                  ),
                  const SizedBox(height: 8),
                  ExpansionTile(
                    leading: const Icon(Icons.settings),
                    title: Text(tr.manageAccount),
                    children: [
                      _tile(
                        context,
                        icon: Icons.power_settings_new,
                        title: tr.setInactive,
                        onTap: () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            useRootNavigator: false,
                            builder: (_) => BlocProvider.value(
                              value: context.read<UserProfileBloc>(),
                              child: DeactivateUserDialog(
                                token: _effectiveToken,
                                userId: _effectiveUserId,
                                ownerProjectLinkId: ownerId,
                              ),
                            ),
                          );

                          if (ok == true) {
                            await _goToLogin();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(body: SizedBox.shrink());
      },
    );
  }

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }

  void _showLanguageSelector(BuildContext context) {
    final tr = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(tr.commonEnglish),
              onTap: () {
                Navigator.pop(ctx);
                widget.onChangeLocale(const Locale('en'));
              },
            ),
            ListTile(
              title: Text(tr.commonFrench),
              onTap: () {
                Navigator.pop(ctx);
                widget.onChangeLocale(const Locale('fr'));
              },
            ),
            ListTile(
              title: Text(tr.commonArabic),
              onTap: () {
                Navigator.pop(ctx);
                widget.onChangeLocale(const Locale('ar'));
              },
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                tr.language_note,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    if (_loggingOut) return;

    final tr = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: this.context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.logout),
        content: Text(tr.profileLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              tr.cancel,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _goToLogin();
    }
  }
}