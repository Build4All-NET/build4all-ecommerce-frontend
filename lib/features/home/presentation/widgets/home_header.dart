// lib/features/home/presentation/widgets/home_header.dart
import 'dart:async';
import 'dart:convert';

import 'package:build4front/app/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/core/theme/theme_cubit.dart';

import 'package:build4front/features/notifications/data/services/notifications_api_service.dart';

import 'package:build4front/features/profile/presentation/bloc/user_profile_bloc.dart';
import 'package:build4front/features/profile/presentation/bloc/user_profile_state.dart';
import 'package:build4front/features/auth/domain/entities/user_entity.dart';

class HomeHeader extends StatefulWidget {
  final String appName;
  final String? fullName;
  final String? avatarUrl;
  final String welcomeText;
  final VoidCallback? onProfileTap;

  const HomeHeader({
    super.key,
    required this.appName,
    this.fullName,
    this.avatarUrl,
    required this.welcomeText,
    this.onProfileTap,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final NotificationsApiService _notificationsApi = NotificationsApiService();

  int _unreadCount = 0;
  bool _loadingUnread = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnreadCount();
    });

    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadUnreadCount(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  bool _isUserToken() {
    final raw = net.readAuthToken();

    if (raw.trim().isEmpty) {
      return false;
    }

    try {
      final token = raw
          .replaceFirst(RegExp('^Bearer\\s+', caseSensitive: false), '')
          .trim();

      final parts = token.split('.');
      if (parts.length != 3) {
        return false;
      }

      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );

      final map = jsonDecode(payloadJson) as Map<String, dynamic>;
      final role = (map['role'] ?? '').toString().trim().toUpperCase();

      return role == 'USER';
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadUnreadCount({
    bool silent = false,
  }) async {
    if (!_isUserToken()) {
      if (!mounted) return;

      setState(() {
        _unreadCount = 0;
        _loadingUnread = false;
      });

      return;
    }

    if (!silent) {
      setState(() {
        _loadingUnread = true;
      });
    }

    try {
      final count = await _notificationsApi.getUnreadCount();

      if (!mounted) return;

      setState(() {
        _unreadCount = count < 0 ? 0 : count;
        _loadingUnread = false;
      });
    } catch (e) {
      debugPrint('Failed to load unread notification count => $e');

      if (!mounted) return;

      setState(() {
        _unreadCount = 0;
        _loadingUnread = false;
      });
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).pushNamed(AppRouter.notifications);

    if (!mounted) return;

    await _loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final themeState = context.read<ThemeCubit>().state;
    final spacing = themeState.tokens.spacing;

    UserEntity? profileUser;

    try {
      final st = context.watch<UserProfileBloc>().state;
      if (st is UserProfileLoaded) {
        profileUser = st.user;
      }
    } catch (_) {
      profileUser = null;
    }

    final nameFromProfile = _nameFromUserEntity(profileUser);

    final nameFromWidget =
        (widget.fullName != null && widget.fullName!.trim().isNotEmpty)
            ? widget.fullName!.trim()
            : null;

    final jwtUserName = _getUserNameFromJwt();
    final ownerName = net.getOwnerNameFromJwt();

    final displayName = nameFromProfile ??
        nameFromWidget ??
        jwtUserName ??
        ownerName ??
        (widget.appName.trim().isNotEmpty ? widget.appName.trim() : 'Owner');

    final profileAvatar = (profileUser?.profilePictureUrl ?? '').trim();
    final widgetAvatar = (widget.avatarUrl ?? '').trim();

    final chosenAvatar = profileAvatar.isNotEmpty
        ? profileAvatar
        : widgetAvatar;

    String? resolvedAvatar;

    if (chosenAvatar.isNotEmpty) {
      resolvedAvatar = net.resolveUrl(chosenAvatar);
    }

    final avatar = (resolvedAvatar != null && resolvedAvatar.trim().isNotEmpty)
        ? CircleAvatar(
            radius: 22,
            backgroundColor: c.primary.withOpacity(0.15),
            backgroundImage: NetworkImage(resolvedAvatar),
            onBackgroundImageError: (_, __) {},
          )
        : CircleAvatar(
            radius: 22,
            backgroundColor: c.primary.withOpacity(0.15),
            child: Icon(
              Icons.person_rounded,
              color: c.primary,
            ),
          );

    final leftClickable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onProfileTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: spacing.xs,
            horizontal: spacing.xs,
          ),
          child: Row(
            children: [
              avatar,
              SizedBox(width: spacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.welcomeText,
                    style: t.labelLarge,
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: Text(
                      displayName,
                      style: t.titleMedium,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Container(
      margin: EdgeInsets.only(bottom: spacing.md),
      child: Row(
        children: [
          Expanded(child: leftClickable),
          _NotificationBellButton(
            unreadCount: _unreadCount,
            loading: _loadingUnread,
            onTap: _openNotifications,
          ),
        ],
      ),
    );
  }

  String? _nameFromUserEntity(UserEntity? user) {
    if (user == null) {
      return null;
    }

    final first = (user.firstName ?? '').trim();
    final last = (user.lastName ?? '').trim();
    final username = (user.username ?? '').trim();
    final email = (user.email ?? '').trim();
    final phone = (user.phoneNumber ?? '').trim();

    if (first.isNotEmpty || last.isNotEmpty) {
      return ('$first $last').trim();
    }

    if (username.isNotEmpty) {
      return username;
    }

    if (email.isNotEmpty) {
      return email;
    }

    if (phone.isNotEmpty) {
      return phone;
    }

    return null;
  }
}

class _NotificationBellButton extends StatelessWidget {
  final int unreadCount;
  final bool loading;
  final VoidCallback onTap;

  const _NotificationBellButton({
    required this.unreadCount,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final showBadge = unreadCount > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          icon: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.primary,
                  ),
                )
              : const Icon(Icons.notifications_none_rounded),
        ),

        if (showBadge)
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 2,
              ),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.error,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: c.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : '$unreadCount',
                style: t.labelSmall?.copyWith(
                  color: c.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String? _getUserNameFromJwt() {
  final raw = net.readAuthToken();

  if (raw.isEmpty) {
    return null;
  }

  try {
    final token = raw
        .replaceFirst(RegExp('^Bearer\\s+', caseSensitive: false), '')
        .trim();

    final parts = token.split('.');

    if (parts.length != 3) {
      return null;
    }

    final payloadJson = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );

    final map = jsonDecode(payloadJson) as Map<String, dynamic>;

    final role = (map['role'] as String?)?.toUpperCase();

    if (role != 'USER') {
      return null;
    }

    final first = (map['firstName'] as String?)?.trim() ?? '';
    final last = (map['lastName'] as String?)?.trim() ?? '';
    final username = (map['username'] as String?)?.trim() ?? '';
    final subject = (map['sub'] as String?)?.trim() ?? '';

    if (first.isNotEmpty || last.isNotEmpty) {
      return ('$first $last').trim();
    }

    if (username.isNotEmpty) {
      return username;
    }

    if (subject.isNotEmpty) {
      return subject;
    }

    return null;
  } catch (_) {
    return null;
  }
}