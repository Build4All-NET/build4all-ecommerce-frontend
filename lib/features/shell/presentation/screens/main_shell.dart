// lib/features/shell/presentation/screens/main_shell.dart

import 'dart:convert';
import 'dart:typed_data';

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/l10n/locale_cubit.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/home_config.dart';

// ✅ globals (token helpers)
import 'package:build4front/core/network/globals.dart' as g;

// Home + Explore
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/screens/placeholder_screen.dart';
import '../../../explore/presentation/screens/explore_screen.dart';

// Auth
import 'package:build4front/features/auth/presentation/login/bloc/auth_bloc.dart';
import 'package:build4front/features/auth/presentation/login/bloc/auth_state.dart';
import 'package:build4front/features/auth/data/repository/auth_repository_impl.dart';
import 'package:build4front/features/auth/presentation/login/screens/user_login_screen.dart';

// Profile screen
import 'package:build4front/features/profile/presentation/screens/user_profile_screen.dart';

// Profile feature wiring (service → repo → usecases → bloc)
import 'package:build4front/features/profile/presentation/bloc/user_profile_bloc.dart';
import 'package:build4front/features/profile/presentation/bloc/user_profile_event.dart';
import 'package:build4front/features/profile/domain/usecases/get_user_profile.dart';
import 'package:build4front/features/profile/domain/usecases/toggle_user_visibility.dart';
import 'package:build4front/features/profile/domain/usecases/update_user_status.dart';
import 'package:build4front/features/profile/data/services/user_profile_service.dart';
import 'package:build4front/features/profile/data/repositories/user_profile_repository_impl.dart';

// ✅ Cart screen
import 'package:build4front/features/cart/presentation/screens/cart_screen.dart';

class MainShell extends StatefulWidget {
  final AppConfig appConfig;

  const MainShell({super.key, required this.appConfig});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<NavItemView> _tabs;
  late final List<Widget> _pages;

  // ✅ guard so we don’t spam LoadUserProfile every rebuild
  String _lastProfileToken = '';
  int _lastProfileUserId = 0;
  int _lastProfileOwnerId = 0;

  // ----------------------------
  // ✅ Profile tab detection (robust)
  // ----------------------------
  bool _isProfileTabId(String id) {
    final v = id.trim().toLowerCase();
    return v == 'profile' || v == 'user' || v == 'account' || v == 'me';
  }

  int _profileTabIndex() {
    return _tabs.indexWhere((t) => _isProfileTabId(t.id));
  }

  void _openProfileTab() {
    final idx = _profileTabIndex();

    if (idx >= 0) {
      setState(() => _currentIndex = idx);
      return;
    }

    // ✅ fallback: if profile tab doesn't exist in bottom nav, open it as a route
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ProfileTabShell(appConfig: widget.appConfig),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    final navItems = widget.appConfig.navigation;

    if (navItems.isEmpty) {
      _tabs = [
        NavItemView(id: 'home', label: 'Home', icon: Icons.home_rounded),
      ];
    } else {
      _tabs = navItems
          .map(
            (n) => NavItemView(
              id: n.id,
              label: n.label,
              icon: _mapIconName(n.icon),
            ),
          )
          .toList();
    }

    final homeSections = HomeConfigLoader.loadSections(widget.appConfig);

    _pages = _tabs.map((tab) {
      switch (tab.id.toLowerCase()) {
        case 'home':
          return HomeScreen(
            appConfig: widget.appConfig,
            sections: homeSections,
            // ✅ important link: lets HomeScreen open profile tab
            onOpenProfileTab: _openProfileTab,
          );

        case 'explore':
          return ExploreScreen(appConfig: widget.appConfig);

        case 'cart':
          return const CartScreen();

        case 'profile':
        case 'user':
        case 'account':
        case 'me':
          return _ProfileTabShell(appConfig: widget.appConfig);

        default:
          return PlaceholderScreen(title: tab.label);
      }
    }).toList();

  
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final body = IndexedStack(index: _currentIndex, children: _pages);

    // ✅ Use ThemeCubit menuType if available, otherwise AppConfig menuType
    final themeMenuType =
        context.watch<ThemeCubit>().state.menuType.trim().toLowerCase();
    final appMenuType = widget.appConfig.menuType.trim().toLowerCase();
    final effectiveMenuType =
        themeMenuType.isNotEmpty ? themeMenuType : appMenuType;
    final isBottom = effectiveMenuType == 'bottom';

    // ✅ Hide AppBar on HOME only (but keep it in drawer mode so hamburger stays)
    final currentTabId = _tabs[_currentIndex].id.trim().toLowerCase();
    final hideAppBar = isBottom && currentTabId == 'home';

    return RepositoryProvider<UserProfileService>(
      create: (_) => UserProfileService(),
      child: BlocProvider<UserProfileBloc>(
        create: (ctx) {
          final service = ctx.read<UserProfileService>();
          final repo = UserProfileRepositoryImpl(service);

          return UserProfileBloc(
            getUser: GetUserProfile(repo),
            toggleVisibility: ToggleUserVisibility(repo),
            updateStatus: UpdateUserStatus(repo),
          );
        },
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (prev, next) {
            final prevToken = (prev.token ?? '').trim();
            final nextToken = (next.token ?? '').trim();
            final prevId = prev.user?.id ?? 0;
            final nextId = next.user?.id ?? 0;

            // ownerId comes from env (same value used by service layer)
            final prevOwner = _envOwnerId();
            final nextOwner = _envOwnerId();

            return prevToken != nextToken ||
                prevId != nextId ||
                prevOwner != nextOwner;
          },
          listener: (ctx, st) => _maybeLoadProfileFromAuthWithBloc(
  bloc: ctx.read<UserProfileBloc>(),
  authState: st,
),
          child: Scaffold(
            appBar: hideAppBar
                ? null
                : AppBar(
                    backgroundColor: c.surface,
                    title: Text(
                      _tabs[_currentIndex].label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: c.onSurface),
                    ),

                    // ✅ Show hamburger ONLY in drawer mode
                    leading: isBottom
                        ? null
                        : Builder(
                            builder: (ctx) => IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                            ),
                          ),
                  ),

            // ✅ Drawer ONLY in drawer mode
            drawer: isBottom
                ? null
                : Drawer(
                    child: SafeArea(
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: _tabs.length,
                        itemBuilder: (ctx, index) {
                          final t = _tabs[index];
                          final selected = index == _currentIndex;

                          return ListTile(
                            leading: Icon(
                              t.icon,
                              color: selected
                                  ? c.primary
                                  : c.onSurface.withOpacity(0.7),
                            ),
                            title: Text(
                              t.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: selected
                                        ? c.primary
                                        : c.onSurface.withOpacity(0.9),
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                            ),
                            selected: selected,
                            onTap: () {
                              setState(() => _currentIndex = index);
                              Navigator.of(context).pop(); // close drawer
                            },
                          );
                        },
                      ),
                    ),
                  ),

            body: body,

            // ✅ Bottom nav ONLY in bottom mode
            bottomNavigationBar: isBottom
                ? BottomNavigationBar(
                    currentIndex: _currentIndex,
                    onTap: (i) => setState(() => _currentIndex = i),

                    // ✅ force colors from current theme
                    backgroundColor: c.surface,
                    selectedItemColor: c.primary,
                    unselectedItemColor: c.onSurface.withOpacity(0.65),

                    // ✅ stable style
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,

                    items: _tabs
                        .map(
                          (t) => BottomNavigationBarItem(
                            icon: Icon(t.icon),
                            label: t.label,
                          ),
                        )
                        .toList(),
                  )
                : null,
          ),
        ),
      ),
    );
  }

  int _envOwnerId() => int.tryParse(Env.ownerProjectLinkId) ?? 0;

void _maybeLoadProfileFromAuthWithBloc({
  required UserProfileBloc bloc,
  required AuthState authState,
}) {
  // pick token (auth -> globals)
  final token = ((authState.token ?? '').trim().isNotEmpty)
      ? authState.token!.trim()
      : g.readAuthToken().trim();

  final userId = authState.user?.id ?? _userIdFromToken(token);
  final ownerId = _envOwnerId();

  if (token.isEmpty || userId <= 0 || ownerId <= 0) return;

  if (token == _lastProfileToken &&
      userId == _lastProfileUserId &&
      ownerId == _lastProfileOwnerId) {
    return;
  }

  _lastProfileToken = token;
  _lastProfileUserId = userId;
  _lastProfileOwnerId = ownerId;

  bloc.add(LoadUserProfile(token, userId, ownerId));
}

  int _userIdFromToken(String token) {
    try {
      var raw = token.trim();
      if (raw.isEmpty) return 0;

      if (raw.toLowerCase().startsWith('bearer ')) {
        raw = raw.substring(7).trim();
      }

      final parts = raw.split('.');
      if (parts.length != 3) return 0;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final map = jsonDecode(payload);
      if (map is! Map<String, dynamic>) return 0;

      final id = map['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;

      final userId = map['userId'];
      if (userId is int) return userId;
      if (userId is String) return int.tryParse(userId) ?? 0;

      return 0;
    } catch (_) {
      return 0;
    }
  }

  IconData _mapIconName(String name) {
    switch (name.toLowerCase()) {
      case 'home':
        return Icons.home_rounded;
      case 'search':
      case 'explore':
        return Icons.search_rounded;
      case 'user':
      case 'person':
      case 'profile':
        return Icons.person_rounded;
      case 'bag':
      case 'cart':
      case 'shopping_cart':
      case 'shopping-bag':
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'ticket':
        return Icons.confirmation_num_rounded;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}

class NavItemView {
  final String id;
  final String label;
  final IconData icon;

  NavItemView({required this.id, required this.label, required this.icon});
}

/// ===============================
///  Profile tab wrapper (NO changes)
/// ===============================
class _ProfileTabShell extends StatelessWidget {
  final AppConfig appConfig;
  const _ProfileTabShell({required this.appConfig});

  Future<void> _handleLogout(BuildContext context) async {
    final authRepo = context.read<AuthRepositoryImpl>();

    await authRepo.api.clearAuth();
    debugPrint('🔓 Auth cleared: token removed from storage and globals');

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => UserLoginScreen(appConfig: appConfig)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    final token = ((authState.token ?? '').trim().isNotEmpty)
        ? authState.token!.trim()
        : g.readAuthToken().trim();

    final userId = authState.user?.id ?? _userIdFromToken(token);

    return UserProfileScreen(
      token: token,
      userId: userId,
      onChangeLocale: (loc) => context.read<LocaleCubit>().setLocale(loc),
      onLogout: () => _handleLogout(context),
    );
  }

  int _userIdFromToken(String token) {
    try {
      var raw = token.trim();
      if (raw.isEmpty) return 0;

      if (raw.toLowerCase().startsWith('bearer ')) {
        raw = raw.substring(7).trim();
      }

      final parts = raw.split('.');
      if (parts.length != 3) return 0;

      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = jsonDecode(payload);
      if (map is! Map<String, dynamic>) return 0;

      final id = map['id'];
      if (id is int) return id;
      if (id is String) return int.tryParse(id) ?? 0;

      final userId = map['userId'];
      if (userId is int) return userId;
      if (userId is String) return int.tryParse(userId) ?? 0;

      return 0;
    } catch (_) {
      return 0;
    }
  }
}
