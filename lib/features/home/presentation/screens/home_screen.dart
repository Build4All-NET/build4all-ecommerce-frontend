import 'dart:async';
import 'dart:math' as math;

import 'package:build4front/features/ai_feature/ai_feature_bootstrap.dart';
import 'package:build4front/features/support/data/services/support_api_service.dart';
import 'package:build4front/features/support/domain/support_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/network/globals.dart' as authState;
import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/config/home_config.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/features/auth/presentation/login/bloc/auth_bloc.dart';
import 'package:build4front/features/auth/presentation/login/bloc/auth_state.dart';
import 'package:build4front/features/auth/domain/entities/user_entity.dart';

import 'package:build4front/features/home/presentation/bloc/home_bloc.dart';
import 'package:build4front/features/home/presentation/bloc/home_event.dart';
import 'package:build4front/features/home/presentation/bloc/home_state.dart';

import 'package:build4front/common/widgets/app_search_field.dart';
import 'package:build4front/features/home/presentation/widgets/home_header.dart';
import 'package:build4front/features/home/presentation/widgets/home_category_chips.dart';
import 'package:build4front/features/home/homebanner/presentations/widgets/home_banner_slider.dart';

import 'package:build4front/features/home/presentation/widgets/home_bottom_section.dart';

import 'package:build4front/features/items/domain/entities/item_summary.dart';
import 'package:build4front/common/widgets/ItemCard.dart';

import 'package:build4front/features/itemsDetails/presentation/screens/item_details_page.dart';

import 'package:build4front/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_event.dart';
import 'package:build4front/common/widgets/app_toast.dart';

import 'package:build4front/features/catalog/cubit/money.dart';
import 'package:build4front/features/catalog/domain/entities/category.dart';
import 'package:build4front/core/config/env.dart';

class HomeScreen extends StatefulWidget {
  final AppConfig appConfig;
  final List<HomeSectionConfig> sections;
  final VoidCallback? onOpenProfileTab;

  const HomeScreen({
    super.key,
    required this.appConfig,
    required this.sections,
    this.onOpenProfileTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  String _searchQuery = '';
  int? _selectedCategoryId;
  Timer? _searchDebounce;

  int _filterVersion = 0;

  @override
  bool get wantKeepAlive => true;

  final OwnerSupportService _supportService = OwnerSupportService();
  SupportInfo? _supportInfo;
  bool _supportLoading = false;
  String? _supportError;
  DateTime? _supportLoadedAt;

  int _lastBottomLogHash = 0;

  void _log(String msg) => debugPrint('[HomeScreen] $msg');

  void _logErr(String msg, Object e, StackTrace st) {
    debugPrint('[HomeScreen][ERR] $msg -> $e');
    debugPrintStack(stackTrace: st);
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse('$v') ?? 0;
  }

  void _ensureHomeDataLoaded() {
    final homeBloc = context.read<HomeBloc>();
    final s = homeBloc.state;

    if (s.hasLoaded || s.isLoading) return;

    final raw = (authState.token ?? '').trim();
    final token = raw.isEmpty ? null : raw;

    _log(
      'Dispatch HomeStarted (initial load) | token=${token == null ? "null" : "yes"}',
    );
    homeBloc.add(HomeStarted(token: token));
  }

  int get _resolvedOwnerProjectLinkId {
    final envLink = _asInt(Env.ownerProjectLinkId);
    if (envLink > 0) return envLink;

    final cfgOwnerProjectId = _asInt(widget.appConfig.ownerProjectId);
    if (cfgOwnerProjectId > 0) return cfgOwnerProjectId;

    final envOwner = _asInt(Env.ownerProjectLinkId);
    if (envOwner > 0) return envOwner;

    return 0;
  }

  int get _resolvedOwnerProjectId {
    final cfgOwnerProjectId = _asInt(widget.appConfig.ownerProjectId);
    if (cfgOwnerProjectId > 0) return cfgOwnerProjectId;

    final link = _resolvedOwnerProjectLinkId;
    if (link > 0) return link;

    final envOwner = _asInt(Env.ownerProjectLinkId);
    if (envOwner > 0) return envOwner;

    return 0;
  }

  Future<void> _loadSupportInfo({
    bool silent = true,
    String reason = '',
  }) async {
    if (!silent) {
      setState(() {
        _supportLoading = true;
        _supportError = null;
      });
    }

    try {
      final raw = (authState.token ?? '').trim();
      final token = raw.isEmpty ? '' : raw;

      final info = await _supportService.fetchSupportInfo(token: token);

      if (!mounted) return;
      setState(() {
        _supportInfo = info;
        _supportError = null;
        _supportLoading = false;
        _supportLoadedAt = DateTime.now();
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _supportInfo = null;
        _supportError = '$e';
        _supportLoading = false;
        _supportLoadedAt = null;
      });
      _logErr('SupportInfo FAIL', e, st);
    }
  }

  void _resetPaging() => _filterVersion++;

  String? _fallbackOwnerPhoneFromConfig(AppConfig cfg) {
    String? clean(dynamic v) {
      final s = (v ?? '').toString().trim();
      if (s.isEmpty) return null;
      final low = s.toLowerCase();
      if (low == 'null' || low == 'n/a' || low == 'none') return null;
      return s;
    }

    try {
      final d = cfg as dynamic;
      final direct =
          clean(d.ownerPhoneNumber) ??
          clean(d.ownerPhone) ??
          clean(d.contactPhoneNumber) ??
          clean(d.contactPhone) ??
          clean(d.supportPhoneNumber) ??
          clean(d.supportPhone) ??
          clean(d.phoneNumber) ??
          clean(d.whatsappNumber) ??
          clean(d.whatsAppNumber) ??
          clean(d.ownerWhatsappNumber) ??
          clean(d.supportWhatsappNumber);
      if (direct != null) return direct;
    } catch (_) {}

    Map<String, dynamic>? m;
    try {
      final x = (cfg as dynamic).toJson();
      if (x is Map<String, dynamic>) m = x;
    } catch (_) {}

    if (m == null) return null;

    String? fromKey(String key) => clean(m![key]);

    return fromKey('ownerPhoneNumber') ??
        fromKey('ownerPhone') ??
        fromKey('contactPhoneNumber') ??
        fromKey('contactPhone') ??
        fromKey('supportPhoneNumber') ??
        fromKey('supportPhone') ??
        fromKey('phoneNumber') ??
        fromKey('whatsappNumber') ??
        fromKey('whatsAppNumber') ??
        fromKey('ownerWhatsappNumber') ??
        fromKey('supportWhatsappNumber');
  }

  bool _isVisibleForUser(ItemSummary item) {
    if (item.kind != ItemKind.product) return true;
    return item.isVisibleForUser;
  }

  bool _canUserPurchase(ItemSummary item) {
    if (item.kind != ItemKind.product) return true;
    return item.isAvailableForPurchase;
  }

  bool _isComingSoon(ItemSummary item) {
    if (item.kind != ItemKind.product) return false;
    return item.isUpcoming;
  }

  List<ItemSummary> _visibleItemsOnly(List<ItemSummary> items) {
    return items.where(_isVisibleForUser).toList();
  }

  bool _hasAnyItems(HomeState s) {
    return _visibleItemsOnly(s.recommendedItems).isNotEmpty ||
        _visibleItemsOnly(s.popularItems).isNotEmpty ||
        _visibleItemsOnly(s.flashSaleItems).isNotEmpty ||
        _visibleItemsOnly(s.newArrivalsItems).isNotEmpty ||
        _visibleItemsOnly(s.bestSellersItems).isNotEmpty ||
        _visibleItemsOnly(s.topRatedItems).isNotEmpty;
  }

  Set<int> _availableCategoryIds(HomeState s) {
    final set = <int>{};

    void add(List<ItemSummary> list) {
      for (final it in _visibleItemsOnly(list)) {
        final id = it.categoryId;
        if (id != null) set.add(id);
      }
    }

    add(s.recommendedItems);
    add(s.popularItems);
    add(s.flashSaleItems);
    add(s.newArrivalsItems);
    add(s.bestSellersItems);
    add(s.topRatedItems);

    return set;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _ensureHomeDataLoaded();
      _loadSupportInfo(silent: true, reason: 'init');
      await AiFeatureBootstrap().refresh(minInterval: Duration.zero);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChangedDebounced(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 280), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim();
        _resetPaging();
      });
    });
  }

  void _openSectionSeeAll(
    BuildContext context, {
    required String title,
    required String sectionId,
    required List<ItemSummary> sectionItems,
    required List<Category> categories,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HomeSectionSeeAllScreen(
          title: title,
          sectionId: sectionId,
          items: sectionItems,
          categories: categories,
          initialQuery: _searchQuery,
          initialCategoryId: _selectedCategoryId,
          pricingFor: _pricingFor,
          subtitleFor: _subtitleFor,
          metaFor: _metaLabelFor,
          ctaLabelFor: _ctaLabelFor,
          onTapItem: (id) => _openDetails(context, id),
          onCtaPressed: (item) => _handleCtaPressed(context, item),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    final enabled = widget.appConfig.enabledFeatures.toSet();
    final themeState = context.watch<ThemeCubit>().state;
    final spacing = themeState.tokens.spacing;

    final visibleSections = widget.sections.where((s) {
      if (s.feature == null) return true;
      return enabled.contains(s.feature);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authBlocState) {
            String? fullName;
            String? avatarUrl;

            final UserEntity? user = authBlocState.user as UserEntity?;

            if (authBlocState.isLoggedIn && user != null) {
              final hasFirst = (user.firstName ?? '').trim().isNotEmpty;
              final hasLast = (user.lastName ?? '').trim().isNotEmpty;

              if (hasFirst || hasLast) {
                fullName = '${user.firstName ?? ''} ${user.lastName ?? ''}'
                    .trim();
              } else if ((user.username ?? '').trim().isNotEmpty) {
                fullName = user.username!.trim();
              } else if ((user.email ?? '').trim().isNotEmpty) {
                fullName = user.email!.trim();
              } else if ((user.phoneNumber ?? '').trim().isNotEmpty) {
                fullName = user.phoneNumber!.trim();
              }

              avatarUrl = user.profilePictureUrl;
            }

            return BlocBuilder<HomeBloc, HomeState>(
              builder: (context, homeState) {
                if (!homeState.hasLoaded && !homeState.isLoading) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    _ensureHomeDataLoaded();
                  });
                }

                if (homeState.isLoading && !homeState.hasLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _searchQuery = '';
                      _selectedCategoryId = null;
                      _resetPaging();
                    });

                    final raw = (authState.token ?? '').trim();
                    final token = raw.isEmpty ? null : raw;

                    context.read<HomeBloc>().add(
                      HomeRefreshRequested(token: token),
                    );

                    await AiFeatureBootstrap().refresh(
                      minInterval: Duration.zero,
                    );
                    await _loadSupportInfo(
                      silent: false,
                      reason: 'pull-to-refresh',
                    );
                  },
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth;
                      final contentMaxWidth = maxW > 900 ? 900.0 : maxW;

                      final hp = maxW < 390 ? spacing.md : spacing.lg;
                      final top = maxW < 390 ? spacing.md : spacing.lg;
                      final bottom = spacing.lg;

                      return Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentMaxWidth),
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(hp, top, hp, bottom),
                            itemCount: visibleSections.length,
                            itemBuilder: (context, index) {
                              final section = visibleSections[index];
                              return _buildSection(
                                context,
                                theme,
                                l10n,
                                section,
                                homeState: homeState,
                                fullName: fullName,
                                avatarUrl: avatarUrl,
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    HomeSectionConfig section, {
    required HomeState homeState,
    String? fullName,
    String? avatarUrl,
  }) {
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    switch (section.type) {
      case HomeSectionType.header:
        return Padding(
          padding: EdgeInsets.only(bottom: spacing.xs),
          child: HomeHeader(
            appName: widget.appConfig.appName,
            fullName: fullName,
            avatarUrl: avatarUrl,
            welcomeText: l10n.home_welcome,
            onProfileTap: widget.onOpenProfileTab,
          ),
        );

      case HomeSectionType.search:
        return Padding(
          padding: EdgeInsets.only(bottom: spacing.xs),
          child: AppSearchField(
            hintText: l10n.home_search_hint,
            onChanged: _onSearchChangedDebounced,
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value.trim();
                _resetPaging();
              });
            },
          ),
        );

      case HomeSectionType.categoryChips:
        if (!_hasAnyItems(homeState)) return const SizedBox.shrink();

        final availableIds = _availableCategoryIds(homeState);
        final cats = homeState.categoryEntities
            .where((c) => availableIds.contains(c.id))
            .toList();

        if (cats.isEmpty) return const SizedBox.shrink();

        final selectedLabel = _selectedCategoryId == null
            ? l10n.explore_category_all
            : () {
                for (final cat in cats) {
                  if (cat.id == _selectedCategoryId) return cat.name;
                }
                return l10n.explore_category_all;
              }();

        final chipNames = <String>[
          l10n.explore_category_all,
          ...cats.map((c) => c.name),
        ];

        return Padding(
          padding: EdgeInsets.only(bottom: spacing.xs),
          child: HomeCategoryChips(
            categories: chipNames,
            selectedCategory: selectedLabel,
            onCategoryTap: (categoryName) {
              final selected = categoryName.trim();

              if (selected.isEmpty || selected == l10n.explore_category_all) {
                setState(() {
                  _selectedCategoryId = null;
                  _resetPaging();
                });
                return;
              }

              int? foundId;
              for (final cat in cats) {
                if (cat.name == selected) {
                  foundId = cat.id;
                  break;
                }
              }

              if (foundId == null) return;

              setState(() {
                _selectedCategoryId = foundId;
                _resetPaging();
              });
            },
          ),
        );

      case HomeSectionType.banner:
        return Padding(
          padding: EdgeInsets.only(bottom: spacing.xs),
          child: HomeBannerSlider(
            token: authState.token ?? '',
            onBannerTap: (banner) {
              if (banner.targetType == 'CATEGORY' && banner.targetId != null) {
                Navigator.of(
                  context,
                ).pushNamed('/explore', arguments: {'categoryId': banner.targetId});
              } else if (banner.targetType == 'URL' &&
                  (banner.targetUrl ?? '').isNotEmpty) {
                // TODO url_launcher
              }
            },
          ),
        );

      case HomeSectionType.itemList:
        final rawItems = _visibleItemsOnly(
          _mapItemsForSection(section, homeState),
        );

        final itemsForHome = _applyFilters(rawItems);
        if (itemsForHome.isEmpty) return const SizedBox.shrink();

        final sectionTitle =
            section.title ??
            (section.id == 'recommended'
                ? l10n.home_recommended_title
                : section.id == 'popular'
                    ? l10n.home_popular_title
                    : section.id == 'flash_sale'
                        ? l10n.home_flash_sale_title
                        : section.id == 'new_arrivals'
                            ? l10n.home_new_arrivals_title
                            : section.id == 'best_sellers'
                                ? l10n.home_best_sellers_title
                                : section.id == 'top_rated'
                                    ? l10n.home_top_rated_title
                                    : l10n.home_items_default_title);

        final icon = _iconForSection(section);
        final trailing = _trailingForSection(section, l10n);
        final layout = _HomePagerLayout.rowPages2;

        return Padding(
          padding: EdgeInsets.only(bottom: spacing.xs),
          child: _HomeItemsPagerSection(
            key: ValueKey('${section.id}::$_filterVersion'),
            storageId: section.id,
            layout: layout,
            title: sectionTitle,
            icon: icon,
            trailingText: trailing.text,
            trailingIcon: trailing.icon,
            onTrailingTap: () {
              _openSectionSeeAll(
                context,
                title: sectionTitle,
                sectionId: section.id,
                sectionItems: rawItems,
                categories: homeState.categoryEntities,
              );
            },
            items: itemsForHome,
            pricingFor: _pricingFor,
            subtitleFor: _subtitleFor,
            metaFor: _metaLabelFor,
            ctaLabelFor: _ctaLabelFor,
            onTapItem: (id) => _openDetails(context, id),
            onCtaPressed: (item) => _handleCtaPressed(context, item),
          ),
        );

      case HomeSectionType.bookingList:
        return _BookingSection(
          title: section.title ?? l10n.home_bookings_title,
          placeholderText: l10n.home_bookings_placeholder,
        );

      case HomeSectionType.reviewList:
        final linkId = _resolvedOwnerProjectLinkId;

        final phoneFromApi = (_supportInfo?.phoneNumber ?? '').trim();
        final phoneFallback =
            (_fallbackOwnerPhoneFromConfig(widget.appConfig) ?? '').trim();

        final ownerPhone = phoneFromApi.isNotEmpty
            ? phoneFromApi
            : (phoneFallback.isNotEmpty ? phoneFallback : null);

        final logLine =
            '[HomeScreen] BottomSection: loading=$_supportLoading linkId=$linkId '
            'apiPhone="$phoneFromApi" fallback="$phoneFallback" chosen="$ownerPhone" '
            'err="${_supportError ?? ''}" loadedAt="${_supportLoadedAt?.toIso8601String() ?? ''}" '
            'envLink=${_asInt(Env.ownerProjectLinkId)} cfgOwner=${_asInt(widget.appConfig.ownerProjectId)} envOwner=${_asInt(Env.ownerProjectLinkId)}';

        final h = logLine.hashCode;
        if (h != _lastBottomLogHash) {
          _lastBottomLogHash = h;
          debugPrint(logLine);
        }

        return HomeBottomSection(
          appName: widget.appConfig.appName,
          ownerProjectId: _resolvedOwnerProjectId,
          ownerProjectLinkId: linkId,
          ownerPhoneNumber: ownerPhone,
          supportEmail: _supportInfo?.email,
          supportName: _supportInfo?.ownerName,
          fallbackRegionIso2: 'LB',
          debugLogs: true,
        );
    }
  }

  List<ItemSummary> _applyFilters(List<ItemSummary> items) {
    var result = _visibleItemsOnly(items);

    if (_selectedCategoryId != null) {
      result = result
          .where((item) => item.categoryId == _selectedCategoryId)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((item) {
        final title = item.title.toLowerCase();
        final subtitle = (item.subtitle ?? '').toLowerCase();
        final location = (item.location ?? '').toLowerCase();
        return title.contains(q) || subtitle.contains(q) || location.contains(q);
      }).toList();
    }

    return result;
  }

  List<ItemSummary> _mapItemsForSection(
    HomeSectionConfig section,
    HomeState homeState,
  ) {
    switch (section.id) {
      case 'recommended':
        return homeState.recommendedItems.isNotEmpty
            ? homeState.recommendedItems
            : homeState.popularItems.isNotEmpty
                ? homeState.popularItems
                : homeState.newArrivalsItems;

      case 'popular':
        return homeState.popularItems.isNotEmpty
            ? homeState.popularItems
            : homeState.recommendedItems.isNotEmpty
                ? homeState.recommendedItems
                : homeState.newArrivalsItems;

      case 'flash_sale':
        return homeState.flashSaleItems;

      case 'new_arrivals':
        return homeState.newArrivalsItems.isNotEmpty
            ? homeState.newArrivalsItems
            : homeState.popularItems.isNotEmpty
                ? homeState.popularItems
                : homeState.recommendedItems;

      case 'best_sellers':
        return homeState.bestSellersItems.isNotEmpty
            ? homeState.bestSellersItems
            : homeState.popularItems.isNotEmpty
                ? homeState.popularItems
                : homeState.recommendedItems;

      case 'top_rated':
        return homeState.topRatedItems.isNotEmpty
            ? homeState.topRatedItems
            : homeState.bestSellersItems.isNotEmpty
                ? homeState.bestSellersItems
                : homeState.popularItems.isNotEmpty
                    ? homeState.popularItems
                    : homeState.recommendedItems;

      default:
        return const <ItemSummary>[];
    }
  }

  IconData _iconForSection(HomeSectionConfig section) {
    switch (section.id) {
      case 'flash_sale':
        return Icons.flash_on_rounded;
      case 'new_arrivals':
        return Icons.local_offer_outlined;
      case 'best_sellers':
        return Icons.workspace_premium_outlined;
      case 'top_rated':
        return Icons.star_rate_rounded;
      default:
        return Icons.local_activity_outlined;
    }
  }

  void _openDetails(BuildContext context, int itemId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemDetailsPage(itemId: itemId)));
  }

  bool _isOutOfStock(ItemSummary item) {
    if (item.kind != ItemKind.product) return false;
    final s = item.stock;
    if (s == null) return false;
    return s <= 0;
  }

  String _ctaLabelFor(BuildContext context, ItemSummary item) {
    final l10n = AppLocalizations.of(context)!;

    switch (item.kind) {
      case ItemKind.product:
        if (_isComingSoon(item)) return l10n.home_coming_soon_button;
        if (_isOutOfStock(item)) return l10n.outOfStock;
        return l10n.cart_add_button;

      case ItemKind.activity:
        return l10n.home_book_now_button;

      default:
        return l10n.home_view_details_button;
    }
  }

  String? _subtitleFor(ItemSummary item) {
    switch (item.kind) {
      case ItemKind.activity:
        return item.location;
      case ItemKind.product:
        return item.subtitle;
      default:
        return item.subtitle ?? item.location;
    }
  }

  String? _metaLabelFor(BuildContext context, ItemSummary item) {
    final l10n = AppLocalizations.of(context)!;

    switch (item.kind) {
      case ItemKind.activity:
        if (item.start == null) return null;
        final dt = item.start!.toLocal();
        final y = dt.year.toString().padLeft(4, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final d = dt.day.toString().padLeft(2, '0');
        final hh = dt.hour.toString().padLeft(2, '0');
        final mm = dt.minute.toString().padLeft(2, '0');
        return '$d/$m/$y  $hh:$mm';

      case ItemKind.product:
        final stock = item.stock;

        if (stock == null) return null;
        if (stock <= 0) return l10n.outOfStock;
        if (stock <= 10) return l10n.home_stock_left_label(stock);

        return null;

      default:
        return null;
    }
  }

  void _handleCtaPressed(BuildContext context, ItemSummary item) {
    final l10n = AppLocalizations.of(context)!;
    final auth = context.read<AuthBloc>().state;

    if (!auth.isLoggedIn) {
      AppToast.error(context, l10n.cart_login_required_message);
      return;
    }

    if (item.kind == ItemKind.product) {
      if (_isComingSoon(item)) {
        AppToast.error(context, l10n.home_coming_soon_button);
        return;
      }

      if (!_canUserPurchase(item)) {
        AppToast.error(context, l10n.outOfStock);
        return;
      }

      context.read<CartBloc>().add(
        CartAddItemRequested(itemId: item.id, quantity: 1),
      );
      AppToast.show(context, l10n.cart_item_added_snackbar);
      return;
    }

    _openDetails(context, item.id);
  }

  bool _isSaleActiveNow(ItemSummary item) {
    final now = DateTime.now();
    final start = item.saleStart;
    final end = item.saleEnd;

    if (start == null && end == null) return item.onSale;
    if (start != null && end == null) return !now.isBefore(start);
    if (start == null && end != null) return !now.isAfter(end);
    return !now.isBefore(start!) && !now.isAfter(end!);
  }

  num? _currentPrice(ItemSummary item) {
    final saleActive = item.onSale && _isSaleActiveNow(item);
    return saleActive
        ? (item.effectivePrice ?? item.salePrice ?? item.price)
        : item.price;
  }

  _PricingView _pricingFor(BuildContext context, ItemSummary item) {
    final l10n = AppLocalizations.of(context)!;
    final saleActive = item.onSale && _isSaleActiveNow(item);
    final current = _currentPrice(item);

    final currentLabel =
        current != null ? money(context, current.toDouble()) : null;

    String? oldLabel;
    if (saleActive && item.price != null && current != null) {
      final base = item.price!.toDouble();
      final cur = current.toDouble();
      if (base > cur) oldLabel = money(context, base);
    }

    String? tagLabel;
    if (saleActive && item.price != null && current != null) {
      final base = item.price!.toDouble();
      final cur = current.toDouble();
      if (base > 0) {
        final percent = ((1 - (cur / base)) * 100).round();
        tagLabel = percent > 0 ? '-$percent%' : l10n.home_sale_tag;
      }
    }

    return _PricingView(
      currentLabel: currentLabel,
      oldLabel: oldLabel,
      tagLabel: tagLabel,
    );
  }

  _TrailingData _trailingForSection(
    HomeSectionConfig section,
    AppLocalizations l10n,
  ) {
    switch (section.id) {
      case 'flash_sale':
        return _TrailingData(text: l10n.home_trailing_limited_time);
      case 'new_arrivals':
      case 'best_sellers':
      case 'top_rated':
        return _TrailingData(
          text: l10n.home_trailing_see_all,
          icon: Icons.chevron_right_rounded,
        );
      default:
        return const _TrailingData();
    }
  }
}

enum _HomePagerLayout { rowPages2 }

class _HomeItemsPagerSection extends StatefulWidget {
  final String storageId;
  final String title;
  final IconData icon;
  final _HomePagerLayout layout;
  final String? trailingText;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final List<ItemSummary> items;
  final _PricingView Function(BuildContext, ItemSummary) pricingFor;
  final String? Function(ItemSummary) subtitleFor;
  final String? Function(BuildContext, ItemSummary) metaFor;
  final String Function(BuildContext, ItemSummary) ctaLabelFor;
  final void Function(int itemId) onTapItem;
  final void Function(ItemSummary item) onCtaPressed;

  const _HomeItemsPagerSection({
    super.key,
    required this.storageId,
    required this.title,
    required this.icon,
    required this.layout,
    required this.trailingText,
    required this.trailingIcon,
    required this.onTrailingTap,
    required this.items,
    required this.pricingFor,
    required this.subtitleFor,
    required this.metaFor,
    required this.ctaLabelFor,
    required this.onTapItem,
    required this.onCtaPressed,
  });

  @override
  State<_HomeItemsPagerSection> createState() => _HomeItemsPagerSectionState();
}

class _HomeItemsPagerSectionState extends State<_HomeItemsPagerSection> {
  late PageController _pc;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  double _aspect(double w) {
    if (w < 360) return 0.56;
    if (w < 420) return 0.58;
    if (w < 700) return 0.62;
    return 0.68;
  }

  void _jumpTo(int p) {
    if (!_pc.hasClients) return;
    _pc.animateToPage(
      p,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();

    final header = Row(
      children: [
        Icon(widget.icon, size: 20, color: c.onSurface.withOpacity(0.85)),
        SizedBox(width: spacing.sm),
        Expanded(
          child: Text(
            widget.title,
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if ((widget.trailingText ?? '').trim().isNotEmpty)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: widget.onTrailingTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.sm,
                vertical: spacing.xs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.trailingText!,
                    style: t.bodySmall?.copyWith(
                      color: c.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (widget.trailingIcon != null) ...[
                    SizedBox(width: spacing.xs),
                    Icon(widget.trailingIcon, size: 18, color: c.primary),
                  ],
                ],
              ),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(height: spacing.xs),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;

            var aspect = _aspect(w);
            if (widget.storageId == 'flash_sale') {
              aspect = math.max(0.48, aspect - 0.06);
            }

            final cols = 2;
            const perPage = 2;

            final totalPages = (items.length / perPage).ceil().clamp(1, 999999);
            final safePage = _page.clamp(0, totalPages - 1);

            if (safePage != _page) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _page = safePage;
                if (_pc.hasClients) _pc.jumpToPage(safePage);
              });
            }

            final cardW = (w - ((cols - 1) * spacing.md)) / cols;
            final cardH = cardW / aspect;
            final extraH = widget.storageId == 'flash_sale' ? spacing.sm : 0.0;

            Widget card(ItemSummary item) {
              return Builder(
                builder: (ctx) {
                  final pricing = widget.pricingFor(ctx, item);
                  final fit = item.kind == ItemKind.product
                      ? BoxFit.contain
                      : BoxFit.cover;

                  final bool ctaDisabled =
                      item.kind == ItemKind.product &&
                      !item.isAvailableForPurchase;

                  return ItemCard(
                    itemId: item.id,
                    width: cardW,
                    imageFit: fit,
                    title: item.title,
                    subtitle: widget.subtitleFor(item),
                    imageUrl: item.imageUrl,
                    badgeLabel: pricing.currentLabel,
                    oldPriceLabel: pricing.oldLabel,
                    tagLabel: pricing.tagLabel,
                    metaLabel: widget.metaFor(ctx, item),
                    ctaLabel: widget.ctaLabelFor(ctx, item),
                    onTap: () => widget.onTapItem(item.id),
                    onCtaPressed: ctaDisabled
                        ? null
                        : () => widget.onCtaPressed(item),
                  );
                },
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: cardH + extraH,
                  child: PageView.builder(
                    key: PageStorageKey('home_pager_${widget.storageId}'),
                    controller: _pc,
                    physics: const PageScrollPhysics(),
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: totalPages,
                    itemBuilder: (context, pageIndex) {
                      final start = pageIndex * perPage;
                      final end = math.min(start + perPage, items.length);
                      final pageItems = start >= items.length
                          ? <ItemSummary>[]
                          : items.sublist(start, end);

                      return Align(
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int i = 0; i < pageItems.length; i++) ...[
                              SizedBox(width: cardW, child: card(pageItems[i])),
                              if (i != pageItems.length - 1)
                                SizedBox(width: spacing.md),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: spacing.sm),
                if (totalPages > 1)
                  _ProPagerBar(
                    currentPage0: safePage,
                    totalPages: totalPages,
                    onPrev: safePage > 0 ? () => _jumpTo(safePage - 1) : null,
                    onNext: safePage < totalPages - 1
                        ? () => _jumpTo(safePage + 1)
                        : null,
                    onDotTap: (p0) => _jumpTo(p0),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProPagerBar extends StatelessWidget {
  final int currentPage0;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final void Function(int page0)? onDotTap;

  const _ProPagerBar({
    required this.currentPage0,
    required this.totalPages,
    this.onPrev,
    this.onNext,
    this.onDotTap,
  });

  List<int> _windowDots(int total, int current) {
    if (total <= 7) return List.generate(total, (i) => i);
    final set = <int>{0, total - 1, current - 1, current, current + 1};
    final list = set.where((p) => p >= 0 && p < total).toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    final dots = _windowDots(totalPages, currentPage0);
    final label = '${currentPage0 + 1}/$totalPages';

    Widget dot(int p0) {
      final selected = p0 == currentPage0;
      return GestureDetector(
        onTap: () => onDotTap?.call(p0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: selected ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: selected ? c.primary : c.outline.withOpacity(0.35),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          tooltip: 'Prev',
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        SizedBox(width: spacing.xs),
        ..._dotsWithEllipsis(dots, dot, spacing.xs),
        SizedBox(width: spacing.sm),
        Text(
          label,
          style: t.bodySmall?.copyWith(
            color: c.onSurface.withOpacity(0.65),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: spacing.xs),
        IconButton(
          tooltip: 'Next',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  List<Widget> _dotsWithEllipsis(
    List<int> dots,
    Widget Function(int) buildDot,
    double gap,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < dots.length; i++) {
      widgets.add(
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gap),
          child: buildDot(dots[i]),
        ),
      );

      if (i < dots.length - 1) {
        final diff = dots[i + 1] - dots[i];
        if (diff > 1) {
          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gap),
              child: const Text('…'),
            ),
          );
        }
      }
    }
    return widgets;
  }
}

class _PricingView {
  final String? currentLabel;
  final String? oldLabel;
  final String? tagLabel;

  const _PricingView({
    required this.currentLabel,
    required this.oldLabel,
    required this.tagLabel,
  });
}

class _TrailingData {
  final String? text;
  final IconData? icon;

  const _TrailingData({this.text, this.icon});
}

class _BookingSection extends StatelessWidget {
  final String title;
  final String placeholderText;

  const _BookingSection({
    required this.title,
    required this.placeholderText,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    return Container(
      margin: EdgeInsets.only(bottom: spacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          SizedBox(height: spacing.sm),
          Container(
            padding: EdgeInsets.all(spacing.md),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                SizedBox(width: spacing.sm),
                Expanded(child: Text(placeholderText, style: t.bodySmall)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeSectionSeeAllScreen extends StatefulWidget {
  final String title;
  final String sectionId;
  final List<ItemSummary> items;
  final List<Category> categories;
  final String initialQuery;
  final int? initialCategoryId;
  final _PricingView Function(BuildContext, ItemSummary) pricingFor;
  final String? Function(ItemSummary) subtitleFor;
  final String? Function(BuildContext, ItemSummary) metaFor;
  final String Function(BuildContext, ItemSummary) ctaLabelFor;
  final void Function(int itemId) onTapItem;
  final void Function(ItemSummary item) onCtaPressed;

  const HomeSectionSeeAllScreen({
    super.key,
    required this.title,
    required this.sectionId,
    required this.items,
    required this.categories,
    required this.initialQuery,
    required this.initialCategoryId,
    required this.pricingFor,
    required this.subtitleFor,
    required this.metaFor,
    required this.ctaLabelFor,
    required this.onTapItem,
    required this.onCtaPressed,
  });

  @override
  State<HomeSectionSeeAllScreen> createState() =>
      _HomeSectionSeeAllScreenState();
}

class _HomeSectionSeeAllScreenState extends State<HomeSectionSeeAllScreen> {
  late String _q;
  int? _catId;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _q = widget.initialQuery;
    _catId = widget.initialCategoryId;
    _searchController = TextEditingController(text: _q);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isVisibleForUser(ItemSummary item) {
    if (item.kind != ItemKind.product) return true;
    return item.isVisibleForUser;
  }

  Map<int, String> _catNameMap() {
    final map = <int, String>{};
    for (final c in widget.categories) {
      map[c.id] = c.name;
    }
    return map;
  }

  List<int> _categoryIdsInItems() {
    final set = <int>{};

    for (final it in widget.items) {
      if (!_isVisibleForUser(it)) continue;
      final cid = it.categoryId;
      if (cid != null) set.add(cid);
    }

    final list = set.toList()..sort();
    return list;
  }

  List<ItemSummary> _filter(List<ItemSummary> items) {
    var res = items.where(_isVisibleForUser).toList();

    if (_catId != null) {
      res = res.where((e) => e.categoryId == _catId).toList();
    }

    final q = _q.trim().toLowerCase();
    if (q.isNotEmpty) {
      res = res.where((e) {
        final t = e.title.toLowerCase();
        final s = (e.subtitle ?? '').toLowerCase();
        final loc = (e.location ?? '').toLowerCase();
        return t.contains(q) || s.contains(q) || loc.contains(q);
      }).toList();
    }

    return res;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;
    final c = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final nameById = _catNameMap();
    final catIds = _categoryIdsInItems();
    final filtered = _filter(widget.items);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: '${l10n.home_search_hint}...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (v) => setState(() => _q = v),
              ),
              if (catIds.isNotEmpty) ...[
                SizedBox(height: spacing.sm),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: catIds.length + 1,
                    separatorBuilder: (_, __) => SizedBox(width: spacing.sm),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        final selected = _catId == null;
                        return ChoiceChip(
                          label: Text(l10n.explore_category_all),
                          selected: selected,
                          onSelected: (_) => setState(() => _catId = null),
                          selectedColor: c.primary.withOpacity(0.18),
                        );
                      }

                      final id = catIds[i - 1];
                      final label = (nameById[id] ?? '').trim().isEmpty
                          ? 'Category $id'
                          : nameById[id]!;
                      final selected = _catId == id;

                      return ChoiceChip(
                        label: Text(label),
                        selected: selected,
                        onSelected: (_) => setState(() => _catId = id),
                        selectedColor: c.primary.withOpacity(0.18),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: spacing.md),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final w = constraints.maxWidth;
                    final cols = w < 520 ? 2 : (w < 900 ? 3 : 4);

                    return GridView.builder(
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: spacing.md,
                        crossAxisSpacing: spacing.md,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final pricing = widget.pricingFor(ctx, item);
                        final disabled =
                            item.kind == ItemKind.product &&
                            !item.isAvailableForPurchase;

                        return ItemCard(
                          itemId: item.id,
                          width: double.infinity,
                          imageFit: item.kind == ItemKind.product
                              ? BoxFit.contain
                              : BoxFit.cover,
                          title: item.title,
                          subtitle: widget.subtitleFor(item),
                          imageUrl: item.imageUrl,
                          badgeLabel: pricing.currentLabel,
                          oldPriceLabel: pricing.oldLabel,
                          tagLabel: pricing.tagLabel,
                          metaLabel: widget.metaFor(ctx, item),
                          ctaLabel: widget.ctaLabelFor(ctx, item),
                          onTap: () => widget.onTapItem(item.id),
                          onCtaPressed: disabled
                              ? null
                              : () => widget.onCtaPressed(item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}