import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/common/widgets/app_toast.dart';

import '../../data/services/home_banner_api_service.dart';
import '../../data/repositories/home_banner_repository_impl.dart';

import '../../domain/entities/home_banner.dart';
import '../../domain/usecases/list_home_banners_admin.dart';
import '../../domain/usecases/create_home_banner.dart';
import '../../domain/usecases/update_home_banner.dart';
import '../../domain/usecases/delete_home_banner.dart';

import '../bloc/home_banners_bloc.dart';
import '../bloc/home_banners_event.dart';
import '../bloc/home_banners_state.dart';

import '../widgets/admin_home_banner_card.dart';
import '../widgets/admin_home_banner_empty_state.dart';
import '../widgets/admin_home_banner_form_sheet.dart';

class AdminHomeBannersScreen extends StatelessWidget {
  final int ownerProjectId;

  const AdminHomeBannersScreen({
    super.key,
    required this.ownerProjectId,
  });

  @override
  Widget build(BuildContext context) {
    final repo = HomeBannerRepositoryImpl(HomeBannerApiService());

    return BlocProvider(
      create: (_) => HomeBannersBloc(
        listAdmin: ListHomeBannersAdmin(repo),
        create: CreateHomeBanner(repo),
        update: UpdateHomeBanner(repo),
        delete: DeleteHomeBanner(repo),
      ),
      child: _AdminHomeBannersView(ownerProjectId: ownerProjectId),
    );
  }
}

class _AdminHomeBannersView extends StatefulWidget {
  final int ownerProjectId;

  const _AdminHomeBannersView({
    required this.ownerProjectId,
  });

  @override
  State<_AdminHomeBannersView> createState() => _AdminHomeBannersViewState();
}

class _AdminHomeBannersViewState extends State<_AdminHomeBannersView> {
  final _store = AdminTokenStore();

  String? _token;
  bool _loadingToken = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final t = await _store.getToken();
    if (!mounted) return;

    setState(() {
      _token = t;
      _loadingToken = false;
    });

    if (t != null && t.isNotEmpty) {
      context.read<HomeBannersBloc>().add(LoadAdminBanners(token: t));
    }
  }

  Future<String?> _readFreshToken() async {
    final t = await _store.getToken();
    if (!mounted) return null;

    if (t != _token || _loadingToken) {
      setState(() {
        _token = t;
        _loadingToken = false;
      });
    }

    return t;
  }

  void _noToken() {
    final l = AppLocalizations.of(context)!;
    AppToast.error(
      context,
      l.adminSessionExpired,
    );
  }

  Future<void> _refresh() async {
    final token = await _readFreshToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) return _noToken();

    context.read<HomeBannersBloc>().add(LoadAdminBanners(token: token));
  }

  Future<void> _openCreate() async {
    if (_loadingToken) return;

    final token = await _readFreshToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) return _noToken();

    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AdminHomeBannerFormSheet(
        ownerProjectId: widget.ownerProjectId,
      ),
    );

    if (!mounted || res == null) return;

    final body = Map<String, dynamic>.from(res['body'] ?? {});
    final imagePath = (res['imagePath'] ?? '').toString().trim();

    if (imagePath.isEmpty) return;

    context.read<HomeBannersBloc>().add(
      CreateBannerEvent(
        body: body,
        imagePath: imagePath,
        token: token,
      ),
    );
  }

  Future<void> _openEdit(HomeBanner banner) async {
    if (_loadingToken) return;

    final token = await _readFreshToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) return _noToken();

    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AdminHomeBannerFormSheet(
        ownerProjectId: widget.ownerProjectId,
        initial: banner,
      ),
    );

    if (!mounted || res == null) return;

    final body = Map<String, dynamic>.from(res['body'] ?? {});
    final imagePathRaw = res['imagePath']?.toString();
    final imagePath = (imagePathRaw == null || imagePathRaw.trim().isEmpty)
        ? null
        : imagePathRaw.trim();

    context.read<HomeBannersBloc>().add(
      UpdateBannerEvent(
        id: banner.id,
        body: body,
        imagePath: imagePath,
        token: token,
      ),
    );
  }

  Future<void> _confirmDelete(HomeBanner banner) async {
    if (_loadingToken) return;

    final token = await _readFreshToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) return _noToken();

    final l = AppLocalizations.of(context)!;
    final tokens = context.read<ThemeCubit>().state.tokens;
    final c = tokens.colors;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.adminDelete ?? 'Delete'),
        content: Text(l.adminConfirmDelete ?? 'Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.adminCancel ?? 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.adminDelete ?? 'Delete'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    context.read<HomeBannersBloc>().add(
      DeleteBannerEvent(
        id: banner.id,
        token: token,
      ),
    );
  }

  bool _isAuthLikeError(String? msg) {
    final m = (msg ?? '').toLowerCase();
    return m.contains('401') ||
        m.contains('unauthorized') ||
        m.contains('forbidden') ||
        m.contains('invalid token') ||
        m.contains('token expired') ||
        m.contains('session expired') ||
        m.contains('login required');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          l.adminHomeBannersTitle ?? 'Home Banners',
          style: text.titleMedium.copyWith(
            color: c.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: Icon(Icons.refresh, color: c.body),
            tooltip: l.refreshLabel ?? 'Refresh',
          ),
          IconButton(
            onPressed: (_loadingToken || _token == null || _token!.isEmpty)
                ? null
                : _openCreate,
            icon: Icon(Icons.add, color: c.primary),
            tooltip: l.adminHomeBannerAdd ?? 'Add banner',
          ),
        ],
      ),
      body: _loadingToken
          ? Center(
              child: CircularProgressIndicator(color: c.primary),
            )
          : (_token == null || _token!.isEmpty)
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Text(
                      l.adminSessionExpired,
                      style: text.bodyMedium.copyWith(color: c.danger),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : BlocConsumer<HomeBannersBloc, HomeBannersState>(
                  listenWhen: (previous, current) =>
                      previous.error != current.error &&
                      current.error != null &&
                      current.error!.trim().isNotEmpty,
                  listener: (context, state) {
                    final msg = state.error!.trim();

                    if (_isAuthLikeError(msg)) {
                      AppToast.error(
                        context,
                        l.adminSessionExpired,
                      );
                    } else {
                      AppToast.error(context, msg);
                    }
                  },
                  builder: (context, state) {
                    final hasBanners = state.banners.isNotEmpty;

                    if (state.loading && !hasBanners) {
                      return Center(
                        child: CircularProgressIndicator(color: c.primary),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(spacing.lg),
                        children: [
                          if (state.error != null &&
                              state.error!.trim().isNotEmpty &&
                              !hasBanners)
                            Container(
                              margin: EdgeInsets.only(bottom: spacing.md),
                              padding: EdgeInsets.all(spacing.md),
                              decoration: BoxDecoration(
                                color: c.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(
                                  tokens.card.radius,
                                ),
                                border: Border.all(
                                  color: c.danger.withOpacity(0.25),
                                ),
                              ),
                              child: Text(
                                _isAuthLikeError(state.error)
                                    ? l.adminSessionExpired
                                    : state.error!,
                                style: text.bodyMedium.copyWith(
                                  color: c.danger,
                                ),
                              ),
                            ),

                          if (!hasBanners)
                            AdminHomeBannerEmptyState(onAdd: _openCreate)
                          else
                            ...List.generate(state.banners.length, (i) {
                              final b = state.banners[i];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == state.banners.length - 1
                                      ? 0
                                      : spacing.sm,
                                ),
                                child: AdminHomeBannerCard(
                                  banner: b,
                                  onEdit: () => _openEdit(b),
                                  onDelete: () => _confirmDelete(b),
                                ),
                              );
                            }),

                          if (state.loading && hasBanners) ...[
                            SizedBox(height: spacing.md),
                            Center(
                              child: CircularProgressIndicator(
                                color: c.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}