import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/common/widgets/app_toast.dart';

import '../../data/services/home_banner_api_service.dart';
import '../../data/repositories/home_banner_repository_impl.dart';

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
  // ✅ keep for targets loading in form sheet
  final int ownerProjectId;

  const AdminHomeBannersScreen({super.key, required this.ownerProjectId});

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
  const _AdminHomeBannersView({required this.ownerProjectId});

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
    _load();
  }

  Future<void> _load() async {
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

  void _noToken() {
    final l = AppLocalizations.of(context)!;
    AppToast.error(context, l.adminSessionExpired);
  }

  Future<void> _refresh() async {
    if (_token == null || _token!.isEmpty) return _noToken();
    context.read<HomeBannersBloc>().add(LoadAdminBanners(token: _token!));
  }

  Future<void> _openCreate() async {
    if (_loadingToken) return;
    if (_token == null || _token!.isEmpty) return _noToken();

    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AdminHomeBannerFormSheet(ownerProjectId: widget.ownerProjectId),
    );

    if (res == null) return;

    final body = Map<String, dynamic>.from(res['body'] ?? {});
    final imagePath = (res['imagePath'] ?? '').toString();

    if (imagePath.isEmpty) return;

    context.read<HomeBannersBloc>().add(
      CreateBannerEvent(
        body: body,
        imagePath: imagePath,
        token: _token!,
      ),
    );
  }

  Future<void> _openEdit(dynamic banner) async {
    if (_loadingToken) return;
    if (_token == null || _token!.isEmpty) return _noToken();

    final res = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AdminHomeBannerFormSheet(
        ownerProjectId: widget.ownerProjectId,
        initial: banner,
      ),
    );

    if (res == null) return;

    final body = Map<String, dynamic>.from(res['body'] ?? {});
    final imagePath = res['imagePath']?.toString();

    context.read<HomeBannersBloc>().add(
      UpdateBannerEvent(
        id: banner.id,
        body: body,
        imagePath: imagePath,
        token: _token!,
      ),
    );
  }

  Future<void> _confirmDelete(dynamic banner) async {
    if (_loadingToken) return;
    if (_token == null || _token!.isEmpty) return _noToken();

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

    if (ok != true) return;

    context.read<HomeBannersBloc>().add(
      DeleteBannerEvent(
        id: banner.id,
        token: _token!,
      ),
    );
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
          ? Center(child: CircularProgressIndicator(color: c.primary))
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
              : BlocBuilder<HomeBannersBloc, HomeBannersState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return Center(
                        child: CircularProgressIndicator(color: c.primary),
                      );
                    }

                    if (state.error != null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        AppToast.error(context, state.error!);
                      });

                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(spacing.lg),
                          child: Text(
                            state.error!,
                            style: text.bodyMedium.copyWith(color: c.danger),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (state.banners.isEmpty) {
                      return ListView(
                        padding: EdgeInsets.all(spacing.lg),
                        children: [AdminHomeBannerEmptyState(onAdd: _openCreate)],
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: EdgeInsets.all(spacing.lg),
                        itemCount: state.banners.length,
                        separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                        itemBuilder: (_, i) {
                          final b = state.banners[i];
                          return AdminHomeBannerCard(
                            banner: b,
                            onEdit: () => _openEdit(b),
                            onDelete: () => _confirmDelete(b),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}