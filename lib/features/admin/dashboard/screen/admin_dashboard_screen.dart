import 'dart:convert';

import 'package:build4front/app/app_router.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/notifications/front_firebase_push_service.dart';
import 'package:build4front/features/admin/announcements/data/repositories/owner_announcement_repository_impl.dart';
import 'package:build4front/features/admin/announcements/domain/usecases/create_owner_announcement.dart';
import 'package:build4front/features/admin/announcements/domain/usecases/delete_owner_announcement.dart';
import 'package:build4front/features/admin/announcements/domain/usecases/get_owner_announcements.dart';
import 'package:build4front/features/admin/announcements/presentation/bloc/owner_announcement_bloc.dart';
import 'package:build4front/features/admin/licensing/domain/entities/owner_app_access.dart';
import 'package:build4front/features/admin/licensing/domain/entities/plan_code.dart';
import 'package:build4front/features/admin/licensing/data/repositories/licensing_repository_impl.dart';
import 'package:build4front/features/admin/licensing/data/services/licensing_api_service.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/confirm_upgrade_payment.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/get_available_payment_methods.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/get_available_upgrade_plans.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/initiate_upgrade_payment.dart';
import 'package:build4front/features/admin/licensing/domain/usecases/refresh_owner_subscription.dart';
import 'package:build4front/features/admin/licensing/presentation/bloc/upgrade_flow_bloc.dart';
import 'package:build4front/features/admin/licensing/presentation/widgets/upgrade_request_sheet.dart';

import 'package:build4front/features/admin/profile/data/repository/admin_profile_repository_impl.dart';
import 'package:build4front/features/admin/profile/data/servcies/admin_user_api_service.dart';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';

import 'package:build4front/features/admin/product/presentation/screens/admin_products_list_screen.dart';
import 'package:build4front/features/admin/home_banner/presentation/screens/admin_home_banners_screen.dart';
import 'package:build4front/features/admin/payment_config/presentation/screens/owner_payment_config_screen.dart';
import 'package:build4front/features/admin/shipping/prensentation/screens/admin_shipping_methods_screen.dart';
import 'package:build4front/features/admin/tax/presentation/screens/admin_tax_rules_screen.dart';

// ✅ Announcements
import 'package:build4front/features/admin/announcements/data/services/owner_announcement_api_service.dart';
import 'package:build4front/features/admin/announcements/presentation/screens/owner_announcements_screen.dart';

// 🔹 Coupons
import 'package:build4front/features/admin/coupons/presentations/screens/admin_coupons_screen.dart';
import 'package:build4front/features/admin/coupons/presentations/bloc/coupon_bloc.dart';
import 'package:build4front/features/admin/coupons/data/services/coupon_api_service.dart';
import 'package:build4front/features/admin/coupons/data/repositories/coupon_repository_impl.dart';
import 'package:build4front/features/admin/coupons/domain/usecases/get_coupons.dart';
import 'package:build4front/features/admin/coupons/domain/usecases/save_coupon.dart';
import 'package:build4front/features/admin/coupons/domain/usecases/delete_coupon.dart';

// ✅ Toast + exception mapper
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/exceptions/exception_mapper.dart';

// ✅ Profile (clean arch)
import 'package:build4front/features/admin/profile/domain/usecases/get_my_admin_profile.dart';
import 'package:build4front/features/admin/profile/presentation/cubit/admin_profile_cubit.dart';

import 'package:http/http.dart' as http;

String _planCodeToString(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString().split('.').last;
}

double _d(dynamic v, {double fallback = 0}) {
  if (v is num) return v.toDouble();
  return fallback;
}

String _nicePlanNameL10n(AppLocalizations l10n, String code) {
  switch (code) {
    case 'FREE':
      return l10n.planFree;
    case 'PRO_HOSTEDB':
      return l10n.planProHostedDb;
    case 'DEDICATED':
      return l10n.planDedicated;
    default:
      return code.isEmpty ? l10n.planGeneric : code;
  }
}

// ===== helpers =====

DateTime? _tryParseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

String _fmtDate(DateTime? d) {
  if (d == null) return '—';
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Display name for a queued upcoming plan: prefer the server-provided name,
/// fall back to a nicely-localized name derived from the plan code.
String _upcomingPlanLabel(AppLocalizations l10n, UpcomingPlan up) {
  final name = (up.planName ?? '').trim();
  if (name.isNotEmpty) return name;
  final code = _planCodeToString(up.planCode);
  return code.isEmpty ? l10n.planGeneric : _nicePlanNameL10n(l10n, code);
}

/// "2026-07-30 → 2026-08-30" for a queued plan's period, with graceful
/// fallbacks when only one bound is known.
String _upcomingPeriodText(AppLocalizations l10n, UpcomingPlan up) {
  final start = _fmtDate(_tryParseDate(up.periodStart));
  final end = _fmtDate(_tryParseDate(up.periodEnd));
  if (start == '—' && end == '—') return '—';
  return '$start → $end';
}

String _statusToString(dynamic v) {
  if (v == null) return '—';
  if (v is String) return v;
  return v.toString().split('.').last;
}

String _reasonToString(String? v) {
  final r = (v ?? '').trim();
  return r.isEmpty ? '—' : r;
}

String _upgradeStatusNice(AppLocalizations l10n, String? s) {
  final v = (s ?? '').toUpperCase().trim();
  if (v.isEmpty) return '—';
  switch (v) {
    case 'PENDING':
      return l10n.upgradeStatusPending;
    case 'APPROVED':
      return l10n.upgradeStatusApproved;
    case 'REJECTED':
      return l10n.upgradeStatusRejected;
    default:
      return v;
  }
}

double _bottomInset(BuildContext context) {
  final media = MediaQuery.of(context);
  final safe = media.viewPadding.bottom;
  final keyboard = media.viewInsets.bottom;
  return keyboard > 0 ? keyboard : safe;
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _store = AdminTokenStore();
  String? _role;

  OwnerAppAccess? _license;
  bool _licenseLoading = true;
  String? _licenseError;

  int _ownerUnreadNotifications = 0;
  bool _ownerUnreadLoading = false;

  late final LicensingApiService _licensingApi =
      LicensingApiService(getToken: () => _store.getToken());

  late final AdminProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();

    final api = AdminUserApiService(getToken: () => _store.getToken());
    final repo = AdminProfileRepositoryImpl(api: api);
    final getMe = GetMyAdminProfile(repo);
    _profileCubit = AdminProfileCubit(getMe: getMe);

    _init();
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      _loadRole(),
      _loadLicense(),
      _profileCubit.load(),
      _loadOwnerNotificationCount(),
      // _syncOwnerFrontPushIfNeeded(),
    ]);
  }

  /* Future<void> _syncOwnerFrontPushIfNeeded() async {
    try {
      final role = (await _store.getRole())?.toUpperCase() ?? '';
      final ownerProjectLinkId = int.tryParse(Env.ownerProjectLinkId) ?? 0;

      if (role != 'OWNER' || ownerProjectLinkId <= 0) return;

      await FrontFirebasePushService().initAndSyncToken(
        ownerProjectLinkId: ownerProjectLinkId,
      );
    } catch (e) {
      debugPrint('Admin dashboard front push sync failed => $e');
    }
  } */

  Future<void> _loadRole() async {
    final role = await _store.getRole();
    if (!mounted) return;
    setState(() => _role = role?.toUpperCase());
  }

  Future<void> _loadOwnerNotificationCount() async {
    try {
      if (_ownerUnreadLoading) return;

      if (mounted) {
        setState(() => _ownerUnreadLoading = true);
      }

      final token = (await _store.getToken())?.trim() ?? '';
      final dio = g.appDio!;

      final response = await dio.get(
        '/api/front/notifications/unread-count',
        options: Options(
          headers: {
            if (token.isNotEmpty)
              'Authorization': token.toLowerCase().startsWith('bearer ')
                  ? token
                  : 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      int count = 0;

      if (data is int) {
        count = data;
      } else if (data is num) {
        count = data.toInt();
      } else if (data is Map<String, dynamic>) {
        final value = data['unreadCount'] ?? data['count'] ?? data['data'];
        if (value is int) {
          count = value;
        } else if (value is num) {
          count = value.toInt();
        } else {
          count = int.tryParse((value ?? '0').toString()) ?? 0;
        }
      } else if (data != null) {
        count = int.tryParse(data.toString()) ?? 0;
      }

      if (!mounted) return;

      setState(() {
        _ownerUnreadNotifications = count;
        _ownerUnreadLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _ownerUnreadLoading = false);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).pushNamed(AppRouter.notifications);
    if (!mounted) return;
    await _loadOwnerNotificationCount();
  }

  Future<void> _loadLicense() async {
    try {
      setState(() {
        _licenseLoading = true;
        _licenseError = null;
      });

      final role = (await _store.getRole())?.toUpperCase() ?? '';

      OwnerAppAccess access;

      if (role == 'OWNER') {
        access = await _licensingApi.getCurrentLicensePlan();
      } else if (role == 'SUPER_ADMIN') {
        final aupId = int.tryParse(Env.ownerProjectLinkId) ?? 0;
        access = await _licensingApi.getAccessAsSuperAdmin(aupId);
      } else {
        throw Exception('Unsupported role for licensing: $role');
      }

      if (!mounted) return;
      setState(() {
        _license = access;
        _licenseLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _licenseLoading = false;
        _licenseError = ExceptionMapper.toMessage(e);
      });
    }
  }

  Future<void> _logout() async {
    final token = (await _store.getToken())?.trim() ?? '';
    final refresh = (await _store.getRefreshToken())?.trim() ?? '';

    try {
      final dio = g.appDio!;

      await dio.post(
        '/api/auth/logout',
        data: {'refreshToken': refresh},
        options: Options(
          headers: {
            if (token.isNotEmpty)
              'Authorization': token.toLowerCase().startsWith('bearer ')
                  ? token
                  : 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );
    } catch (_) {
      // ignore backend logout failure; local logout still happens
    }

    await _store.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _openProfilePopup() async {
    if (_profileCubit.state is! AdminProfileLoaded) {
      await _profileCubit.load();
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BlocProvider.value(
          value: _profileCubit,
          child: _ProfileBottomSheet(
            aupId: Env.ownerProjectLinkId,
            fallbackRole: (_role ?? 'ADMIN'),
            onReload: () => _profileCubit.load(),
          ),
        );
      },
    );
  }

  Future<void> _openLicenseDetails(OwnerAppAccess access) async {
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LicenseDetailsSheet(
        access: access,
        l10n: l10n,
        onRequestUpgrade: () {
          Navigator.pop(context);
          _showUpgradeSheet(access);
        },
      ),
    );
  }

  UpgradeFlowBloc _buildUpgradeFlowBloc() {
    final repo = LicensingRepositoryImpl(
      api: _licensingApi,
      tokenStore: _store,
    );
    return UpgradeFlowBloc(
      getPlansUc: GetAvailableUpgradePlans(repo),
      getPaymentMethodsUc: GetAvailablePaymentMethods(repo),
      initiatePaymentUc: InitiateUpgradePayment(repo),
      confirmPaymentUc: ConfirmUpgradePayment(repo),
      refreshSubscriptionUc: RefreshOwnerSubscription(repo),
    );
  }

  Future<void> _showUpgradeSheet(OwnerAppAccess access) async {
    final l10n = AppLocalizations.of(context)!;

    if (access.hasPendingUpgradeRequest) {
      AppToast.error(context, l10n.upgradeRequestPending);
      return;
    }

    final current = access.planCode;
    final canRequest = current == PlanCode.FREE || current == PlanCode.PRO_HOSTEDB;

    if (!canRequest) {
      AppToast.error(context, l10n.noUpgradeAvailable);
      return;
    }

    final bloc = _buildUpgradeFlowBloc();
    OwnerAppAccess? updated;
    try {
      updated = await showUpgradeRequestSheet(context: context, bloc: bloc);
    } finally {
      await bloc.close();
    }

    if (!mounted) return;
    if (updated != null) {
      setState(() => _license = updated);
    } else {
      await _loadLicense();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final card = tokens.card;
final blockingReason = (_license?.blockingReason ?? '').trim().toUpperCase();

final DateTime? licenseEndDate = _tryParseDate(_license?.periodEnd);
final DateTime today = DateTime.now();

final bool isExpiredByDate = licenseEndDate != null &&
    DateTime(
      licenseEndDate.year,
      licenseEndDate.month,
      licenseEndDate.day,
    ).isBefore(
      DateTime(today.year, today.month, today.day),
    );

final bool isExpiredReason =
    blockingReason == 'APP_EXPIRED' ||
    blockingReason == 'SUBSCRIPTION_EXPIRED' ||
    blockingReason == 'LICENSE_EXPIRED';

final bool isLimit = blockingReason == 'USER_LIMIT_REACHED';

final bool isBlockedByLicense = _license != null &&
    (
      _license!.canAccessDashboard == false ||
      blockingReason.isNotEmpty ||
      isExpiredByDate ||
      isExpiredReason
    );

final bool lockActions =
    _licenseLoading || _licenseError != null || isBlockedByLicense;

   final String lockMsg = _licenseLoading
    ? l10n.adminDashboardStatusChecking
    : (_licenseError != null
        ? l10n.adminDashboardStatusLicenseFailed
        : (isLimit
            ? l10n.adminDashboardStatusLimitReached
            : ((isExpiredByDate || isExpiredReason)
                ? l10n.subscriptionExpiredRenewRequired
                : l10n.adminDashboardStatusAccessBlocked)));

    VoidCallback guarded(VoidCallback realAction) {
      return () {
        if (lockActions) {
          AppToast.error(context, lockMsg);
          return;
        }
        realAction();
      };
    }

    final ownerId = int.tryParse(Env.ownerProjectLinkId) ?? 0;

    final actions = <_DashAction>[
      _DashAction(
        icon: Icons.shopping_bag_outlined,
        title: l10n.adminProductsTitle,
        subtitle: l10n.adminActionProductsSubtitle,
        onTap: guarded(() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminProductsListScreen(ownerProjectId: ownerId),
            ),
          );
        }),
      ),
      _DashAction(
        icon: Icons.local_shipping_outlined,
        title: l10n.adminShippingTitle,
        subtitle: l10n.adminActionShippingSubtitle,
        onTap: guarded(() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminShippingMethodsScreen(ownerProjectId: ownerId),
            ),
          );
        }),
      ),
      _DashAction(
        icon: Icons.credit_card_outlined,
        title: l10n.adminPaymentConfigTitle,
        subtitle: l10n.adminActionPaymentSubtitle,
        onTap: guarded(() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OwnerPaymentConfigScreen(
                getToken: () => _store.getToken(),
              ),
            ),
          );
        }),
      ),
      _DashAction(
        icon: Icons.receipt_long_outlined,
        title: l10n.adminTaxesTitle,
        subtitle: l10n.adminActionTaxesSubtitle,
        onTap: guarded(() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminTaxRulesScreen(ownerProjectId: ownerId),
            ),
          );
        }),
      ),
      _DashAction(
        icon: Icons.view_carousel_outlined,
        title: l10n.adminHomeBannersTitle,
        subtitle: l10n.adminActionBannersSubtitle,
        onTap: guarded(() {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AdminHomeBannersScreen(ownerProjectId: ownerId),
            ),
          );
        }),
      ),
     _DashAction(
  icon: Icons.campaign_outlined,
  title: l10n.adminAnnouncementsTitle,
  subtitle: l10n.adminAnnouncementsSubtitle,
  onTap: guarded(() {
    final api = OwnerAnnouncementApiService(
      getToken: () => _store.getToken(),
    );

    final repo = OwnerAnnouncementRepositoryImpl(api: api);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<OwnerAnnouncementBloc>(
          create: (_) => OwnerAnnouncementBloc(
            getAnnouncementsUc: GetOwnerAnnouncements(repo),
            createAnnouncementUc: CreateOwnerAnnouncement(repo),
            deleteAnnouncementUc: DeleteOwnerAnnouncement(repo),
          ),
          child: const OwnerAnnouncementsScreen(),
        ),
      ),
    );
  }),
),
      _DashAction(
        icon: Icons.card_giftcard_outlined,
        title: l10n.adminCouponsTitle,
        subtitle: l10n.adminActionCouponsSubtitle,
        onTap: guarded(() {
          final api = CouponApiService();
          final repo = CouponRepositoryImpl(
            api: api,
            getToken: () => _store.getToken(),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider<CouponBloc>(
                create: (_) => CouponBloc(
                  getCouponsUc: GetCoupons(repo),
                  saveCouponUc: SaveCoupon(repo),
                  deleteCouponUc: DeleteCoupon(repo),
                ),
                child: const AdminCouponsScreen(),
              ),
            ),
          );
        }),
      ),
      _DashAction(
        icon: Icons.receipt_long_outlined,
        title: l10n.adminOrdersTitle,
        subtitle: l10n.adminActionOrdersSubtitle,
        onTap: guarded(() => Navigator.of(context).pushNamed('/admin/orders')),
      ),
      _DashAction(
        icon: Icons.upload_file_outlined,
        title: l10n.adminExcelImportTitle,
        subtitle: l10n.adminActionExcelSubtitle,
        onTap: guarded(() => Navigator.of(context).pushNamed('/admin/excel-import')),
      ),
    ];

    return BlocProvider.value(
      value: _profileCubit,
      child: Scaffold(
        backgroundColor: colors.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              elevation: 0,
              backgroundColor: colors.surface,
              title: Text(
                l10n.adminDashboardTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.label,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              actions: [
                IconButton(
                  onPressed: _openProfilePopup,
                  icon: Icon(Icons.person_outline, color: colors.body),
                  tooltip: l10n.profileLabel,
                ),
                IconButton(
                  onPressed: _openNotifications,
                  tooltip: l10n.adminDashboardNotificationsTooltip,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(Icons.notifications_none_rounded, color: colors.body),
                      if (_ownerUnreadNotifications > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: colors.surface,
                                width: 1.4,
                              ),
                            ),
                            child: Text(
                              _ownerUnreadNotifications > 99
                                  ? '99+'
                                  : '$_ownerUnreadNotifications',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onError,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10,
                                    height: 1.0,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Future.wait([
                      _loadLicense(),
                      _profileCubit.load(),
                      _loadOwnerNotificationCount(),
                    ]);
                  },
                  icon: Icon(Icons.refresh, color: colors.body),
                  tooltip: l10n.refreshLabel,
                ),
                IconButton(
                  onPressed: _logout,
                  icon: Icon(Icons.logout, color: colors.body),
                  tooltip: l10n.logoutLabel,
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LicenseBanner(
                      loading: _licenseLoading,
                      error: _licenseError,
                      access: _license,
                      onRetry: _loadLicense,
                      onRequestUpgrade: () {
                        if (_license == null) return;

                        if (_license!.hasPendingUpgradeRequest) {
                          AppToast.error(context, l10n.upgradeRequestPending);
                          return;
                        }

                        _showUpgradeSheet(_license!);
                      },
                      onOpenDetails: () {
                        if (_license != null) _openLicenseDetails(_license!);
                      },
                      l10n: l10n,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      l10n.adminDashboardQuickActions,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colors.label,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverToBoxAdapter(
                child: Opacity(
                  opacity: lockActions ? 0.55 : 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: actions.length,
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 230,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: isNarrow ? 0.98 : 1.05,
                        ),
                        itemBuilder: (_, i) {
                          final a = actions[i];
                          return _AdminActionCard(
                            icon: a.icon,
                            title: a.title,
                            subtitle: a.subtitle,
                            onTap: a.onTap,
                            colors: colors,
                            card: card,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
        ),
      ),
    );
  }
}

// =========================== PROFILE SHEET ===========================

class _ProfileBottomSheet extends StatelessWidget {
  final String aupId;
  final String fallbackRole;
  final VoidCallback onReload;

  const _ProfileBottomSheet({
    required this.aupId,
    required this.fallbackRole,
    required this.onReload,
  });

  String _initials(String first, String last, String username) {
    final f = first.trim();
    final l = last.trim();
    final u = username.trim();
    final i1 = f.isNotEmpty ? f[0] : (u.isNotEmpty ? u[0] : '?');
    final i2 = l.isNotEmpty ? l[0] : '';
    return (i1 + i2).toUpperCase();
  }

  Future<void> _copy(BuildContext context, String text, String toast) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    AppToast.success(context, toast);
  }

  Widget _buildHandle(dynamic colors) {
    return Center(
      child: Container(
        height: 5,
        width: 52,
        decoration: BoxDecoration(
          color: colors.border.withOpacity(0.55),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required dynamic colors,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colors.border.withOpacity(.14),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onReload,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoList(
    BuildContext context, {
    required dynamic colors,
    required dynamic profile,
    required String role,
    required String adminId,
    required String businessId,
    required String email,
    required String phone,
    required String name,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              height: 56,
              width: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withOpacity(.18),
                ),
              ),
              child: Text(
                _initials(profile.firstName, profile.lastName, profile.username),
                style: t.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleLarge?.copyWith(
                      color: colors.label,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.background,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: colors.border.withOpacity(.18),
                      ),
                    ),
                    child: Text(
                      l10n.adminMyProfileSubtitle(role),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(
                        color: colors.body,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, color: colors.body),
              tooltip: l10n.closeLabel,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ProfileRow(
          label: l10n.adminIdLabel,
          value: adminId,
          icon: Icons.badge_outlined,
          colors: colors,
          onCopy: () => _copy(context, adminId, l10n.copiedLabel),
        ),
        _ProfileRow(
          label: l10n.aupIdLabel,
          value: aupId,
          icon: Icons.link_outlined,
          colors: colors,
          onCopy: () => _copy(context, aupId, l10n.copiedLabel),
        ),
        _ProfileRow(
          label: l10n.usernameLabel,
          value: profile.username,
          icon: Icons.person_outline,
          colors: colors,
          onCopy: profile.username.trim().isEmpty
              ? null
              : () => _copy(context, profile.username, l10n.copiedLabel),
        ),
        if (businessId.isNotEmpty)
          _ProfileRow(
            label: l10n.businessIdLabel,
            value: businessId,
            icon: Icons.store_outlined,
            colors: colors,
            onCopy: () => _copy(context, businessId, l10n.copiedLabel),
          ),
        if (email.isNotEmpty)
          _ProfileRow(
            label: l10n.emailLabel,
            value: email,
            icon: Icons.email_outlined,
            colors: colors,
            onCopy: () => _copy(context, email, l10n.copiedLabel),
          ),
        if (phone.isNotEmpty)
          _ProfileRow(
            label: l10n.phoneLabel,
            value: phone,
            icon: Icons.phone_outlined,
            colors: colors,
            onCopy: () => _copy(context, phone, l10n.copiedLabel),
          ),
        if ((profile.createdAt ?? '').trim().isNotEmpty)
          _ProfileRow(
            label: l10n.createdAtLabel,
            value: (profile.createdAt ?? '').toString(),
            icon: Icons.schedule_outlined,
            colors: colors,
            onCopy: () => _copy(
              context,
              (profile.createdAt ?? '').toString(),
              l10n.copiedLabel,
            ),
          ),
        if ((profile.updatedAt ?? '').trim().isNotEmpty)
          _ProfileRow(
            label: l10n.updatedAtLabel,
            value: (profile.updatedAt ?? '').toString(),
            icon: Icons.update_outlined,
            colors: colors,
            onCopy: () => _copy(
              context,
              (profile.updatedAt ?? '').toString(),
              l10n.copiedLabel,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final t = Theme.of(context).textTheme;

    final screenHeight = MediaQuery.of(context).size.height;
    final maxSheetHeight = screenHeight * 0.88;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: _bottomInset(context)),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxSheetHeight,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: BlocBuilder<AdminProfileCubit, AdminProfileState>(
                    builder: (context, state) {
                      Widget body;

                      if (state is AdminProfileLoading ||
                          state is AdminProfileInitial) {
                        body = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHandle(colors),
                            const SizedBox(height: 20),
                            const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.adminProfileLoading,
                              style: t.bodyMedium?.copyWith(
                                color: colors.body,
                              ),
                            ),
                          ],
                        );
                      } else if (state is AdminProfileError) {
                        body = Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHandle(colors),
                            const SizedBox(height: 18),
                            Icon(
                              Icons.error_outline_rounded,
                              color: colors.error,
                              size: 28,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: t.bodyMedium?.copyWith(
                                color: colors.label,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildFooter(
                              context,
                              colors: colors,
                              label: l10n.retryLabel,
                            ),
                          ],
                        );
                      } else {
                        final p = (state as AdminProfileLoaded).profile;

                        final name = p.fullName.isNotEmpty
                            ? p.fullName
                            : (p.username.trim().isNotEmpty
                                ? p.username
                                : l10n.adminMyProfileTitle);

                        final role =
                            (p.role.trim().isNotEmpty ? p.role : fallbackRole)
                                .toUpperCase();

                        final email = p.email.trim();
                        final phone = p.phoneNumber.trim();
                        final businessId =
                            p.businessId == null ? '' : p.businessId.toString();
                        final adminId = p.adminId.toString();

                        body = Column(
                          children: [
                            _buildHandle(colors),
                            const SizedBox(height: 16),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: _buildInfoList(
                                  context,
                                  colors: colors,
                                  profile: p,
                                  role: role,
                                  adminId: adminId,
                                  businessId: businessId,
                                  email: email,
                                  phone: phone,
                                  name: name,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildFooter(
                              context,
                              colors: colors,
                              label: l10n.refreshLabel,
                            ),
                          ],
                        );
                      }

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: body,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final dynamic colors;
  final VoidCallback? onCopy;

  const _ProfileRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(.10),
              shape: BoxShape.circle,
              border: Border.all(color: colors.primary.withOpacity(.16)),
            ),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: colors.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.trim().isEmpty ? '—' : value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyMedium?.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              onPressed: onCopy,
              icon: Icon(
                Icons.copy_rounded,
                color: colors.body.withOpacity(.8),
              ),
              tooltip: AppLocalizations.of(context)!.copyLabel,
            ),
        ],
      ),
    );
  }
}

// =========================== ACTIONS GRID ===========================

class _DashAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _AdminActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final dynamic colors;
  final dynamic card;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.colors,
    required this.card,
  });

  @override
  State<_AdminActionCard> createState() => _AdminActionCardState();
}

class _AdminActionCardState extends State<_AdminActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final colors = widget.colors;
    final card = widget.card;

    final double radius = _d(card.radius, fallback: 16);
    final double basePadding = _d(card.padding, fallback: 14);
    final double elev = _d(card.elevation, fallback: 0);

    final width = MediaQuery.of(context).size.width;
    final double pad = width < 360 ? 12.0 : basePadding;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Ink(
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(radius),
              border: (card.showBorder == true)
                  ? Border.all(color: colors.border.withOpacity(0.20))
                  : null,
              boxShadow: (card.showShadow == true && elev > 0)
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: elev * 2.0,
                        offset: Offset(0, elev),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(.10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.primary.withOpacity(.18),
                        ),
                      ),
                      child: Icon(widget.icon, color: colors.primary, size: 24),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: colors.body.withOpacity(.65),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodyLarge?.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w800,
                    height: 1.10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(
                    color: colors.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================== LICENSE BANNER ===========================

class _LicenseBanner extends StatelessWidget {
  final bool loading;
  final String? error;
  final OwnerAppAccess? access;
  final VoidCallback onRetry;
  final VoidCallback onRequestUpgrade;
  final VoidCallback onOpenDetails;
  final AppLocalizations l10n;

  const _LicenseBanner({
    required this.loading,
    required this.error,
    required this.access,
    required this.onRetry,
    required this.onRequestUpgrade,
    required this.onOpenDetails,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final t = Theme.of(context).textTheme;

    if (loading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withOpacity(.18)),
        ),
        child: Row(
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.licenseChecking,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodyMedium?.copyWith(color: colors.body),
              ),
            ),
          ],
        ),
      );
    }

    if (error != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.error.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.error.withOpacity(.22)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: t.bodyMedium?.copyWith(color: colors.label),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(l10n.retryLabel),
            ),
          ],
        ),
      );
    }

    if (access == null) return const SizedBox.shrink();

    final reason = (access!.blockingReason ?? '').trim();
    final isLimit = reason == 'USER_LIMIT_REACHED';
    final hasPending = access!.hasPendingUpgradeRequest;

    final isOk =
        !hasPending && reason.isEmpty && (access!.canAccessDashboard != false);

    final planCodeStr = _planCodeToString(access!.planCode);
    final planName = (access!.planName ?? '').trim().isEmpty
        ? _nicePlanNameL10n(l10n, planCodeStr)
        : access!.planName!.trim();

    // At-a-glance validity so the owner can see, without opening details,
    // the date their current plan runs until and how long is left.
    final endStr = _fmtDate(_tryParseDate(access!.periodEnd));
    final hasEnd = endStr != '—';

    final subtitle = hasPending
        ? l10n.upgradeRequestPending
        : (isOk
            ? l10n.licenseAccessGranted
            : (isLimit
                ? l10n.adminDashboardStatusLimitReached
                : l10n.licenseAccessBlocked));

    final canRequestUpgrade =
        access!.planCode != PlanCode.DEDICATED && !hasPending;

    final bg = isOk
        ? colors.surface
        : (hasPending
            ? colors.primary.withOpacity(.06)
            : (isLimit
                ? colors.primary.withOpacity(.08)
                : colors.error.withOpacity(.06)));

    final border = isOk
        ? colors.border.withOpacity(.18)
        : (hasPending
            ? colors.primary.withOpacity(.18)
            : (isLimit
                ? colors.primary.withOpacity(.22)
                : colors.error.withOpacity(.22)));

    final icon = isOk
        ? Icons.verified_outlined
        : (hasPending
            ? Icons.hourglass_top_rounded
            : (isLimit ? Icons.people_outline : Icons.lock_outline));

    final iconColor = isOk
        ? colors.body
        : (hasPending
            ? colors.primary
            : (isLimit ? colors.primary : colors.error));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpenDetails,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      planName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodyLarge?.copyWith(
                        color: colors.label,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.bodySmall?.copyWith(color: colors.body),
                    ),
                    if (hasEnd) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.licensePeriodEndLabel}: $endStr · '
                        '${l10n.licenseDaysLeftLabel}: ${access!.daysLeft}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.bodySmall?.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (access!.planCode != PlanCode.DEDICATED) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: canRequestUpgrade ? onRequestUpgrade : null,
                  child: Text(
                    hasPending
                        ? l10n.requestUpgradePendingLabel
                        : l10n.requestUpgradeLabel,
                  ),
                ),
              ],
              Icon(
                Icons.chevron_right_rounded,
                color: colors.body.withOpacity(.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================== LICENSE DETAILS SHEET ===========================

class _LicenseDetailsSheet extends StatelessWidget {
  final OwnerAppAccess access;
  final AppLocalizations l10n;
  final VoidCallback onRequestUpgrade;

  const _LicenseDetailsSheet({
    required this.access,
    required this.l10n,
    required this.onRequestUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final t = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);

    final planCodeStr = _planCodeToString(access.planCode);
    final planName = (access.planName ?? '').trim().isEmpty
        ? _nicePlanNameL10n(l10n, planCodeStr)
        : access.planName!.trim();

    final statusStr = _statusToString(access.subscriptionStatus);
    final endStr = _fmtDate(_tryParseDate(access.periodEnd));
    final daysLeft = access.daysLeft;

    final canRequestUpgrade =
        access.planCode != PlanCode.DEDICATED && !access.hasPendingUpgradeRequest;

    final upcomingPlans = access.upcomingPlans;

    final maxHeight = media.size.height * 0.85;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: _bottomInset(context)),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  children: [
                    Container(
                      height: 4,
                      width: 44,
                      decoration: BoxDecoration(
                        color: colors.border.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.licenseDetailsTitle,
                            style: t.titleMedium?.copyWith(
                              color: colors.label,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.close, color: colors.body),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _DetailRow(
                              label: l10n.licensePlanLabel,
                              value: planName,
                              colors: colors,
                            ),
                            _DetailRow(
                              label: l10n.licenseStatusLabel,
                              value: statusStr,
                              colors: colors,
                            ),
                            _DetailRow(
                              label: l10n.licensePeriodEndLabel,
                              value: endStr,
                              colors: colors,
                            ),
                            _DetailRow(
                              label: l10n.licenseDaysLeftLabel,
                              value: '$daysLeft',
                              colors: colors,
                            ),
                            // Queue of purchased plans that start after the
                            // current period (e.g. Basic now -> Smart next).
                            if (upcomingPlans.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                l10n.licenseUpcomingPlansTitle,
                                style: t.titleSmall?.copyWith(
                                  color: colors.label,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final up in upcomingPlans)
                                _UpcomingPlanCard(
                                  name: _upcomingPlanLabel(l10n, up),
                                  periodText: _upcomingPeriodText(l10n, up),
                                  colors: colors,
                                ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    if (access.hasPendingUpgradeRequest)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.hourglass_top_rounded),
                          label: Text(l10n.requestUpgradePendingLabel),
                        ),
                      )
                    else if (canRequestUpgrade)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onRequestUpgrade,
                          icon: const Icon(Icons.upgrade),
                          label: Text(l10n.requestUpgradeLabel),
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
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final dynamic colors;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: t.bodySmall?.copyWith(
                color: colors.body,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value.trim().isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: t.bodyMedium?.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A card for one queued (upcoming) paid plan: plan name on top, its active
/// period below. Used to render the list of stacked plans on the License sheet.
class _UpcomingPlanCard extends StatelessWidget {
  final String name;
  final String periodText;
  final dynamic colors;

  const _UpcomingPlanCard({
    required this.name,
    required this.periodText,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border.withOpacity(.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.schedule_rounded, size: 20, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: t.bodyMedium?.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  periodText,
                  style: t.bodySmall?.copyWith(color: colors.body),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}