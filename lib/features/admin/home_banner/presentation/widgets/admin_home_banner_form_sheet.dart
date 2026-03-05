import 'dart:io';

import 'package:build4front/core/network/globals.dart' as Env;
import 'package:build4front/features/admin/product/data/services/product_api_service.dart';
import 'package:build4front/features/catalog/data/repositories/category_repository_impl.dart';
import 'package:build4front/features/catalog/data/services/category_api_service.dart';
import 'package:build4front/features/catalog/domain/usecases/get_categories_by_project.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';

import 'package:build4front/common/widgets/app_text_field.dart';
import 'package:build4front/common/widgets/app_search_field.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/primary_button.dart';

import '../../domain/entities/home_banner.dart';

// ✅ Your domain entities
import 'package:build4front/features/catalog/domain/entities/category.dart';
import 'package:build4front/features/items/domain/entities/item_summary.dart';

import '../utils/home_banner_target_type_ui.dart';

class AdminHomeBannerFormSheet extends StatefulWidget {
  final int ownerProjectId;
  final HomeBanner? initial;

  const AdminHomeBannerFormSheet({
    super.key,
    required this.ownerProjectId,
    this.initial,
  });

  @override
  State<AdminHomeBannerFormSheet> createState() =>
      _AdminHomeBannerFormSheetState();
}

class _AdminHomeBannerFormSheetState extends State<AdminHomeBannerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _store = AdminTokenStore();
  final _picker = ImagePicker();

  // ---------- text controllers ----------
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _sortCtrl;
  late final TextEditingController _targetUrlCtrl;

  bool _active = true;

  // ---------- image ----------
  String? _imagePath; // local file path
  String? _existingImageUrl; // from backend for edit mode

  // ---------- target ----------
  HomeBannerTargetTypeUi _targetType = HomeBannerTargetTypeUi.none;

  bool _loadingTargets = true;
  String? _targetsError;

  List<Category> _categories = [];
  List<ItemSummary> _products = [];

  Category? _selectedCategory;
  ItemSummary? _selectedProduct;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final b = widget.initial;

    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _subtitleCtrl = TextEditingController(text: b?.subtitle ?? '');
    _sortCtrl = TextEditingController(text: '${b?.sortOrder ?? 0}');
    _targetUrlCtrl = TextEditingController(text: b?.targetUrl ?? '');

    _active = true;
    _targetType = HomeBannerTargetTypeUiX.fromApi(b?.targetType);

    _existingImageUrl = b?.imageUrl;

    // preselect target
    if ((b?.targetType ?? '').toUpperCase() == 'CATEGORY') {
      // will match after loading categories
    }
    if ((b?.targetType ?? '').toUpperCase() == 'PRODUCT') {
      // will match after loading products
    }

    _bootstrapTargets(
      initialCategoryId: ((b?.targetType ?? '').toUpperCase() == 'CATEGORY')
          ? b?.targetId
          : null,
      initialProductId: ((b?.targetType ?? '').toUpperCase() == 'PRODUCT')
          ? b?.targetId
          : null,
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _sortCtrl.dispose();
    _targetUrlCtrl.dispose();
    super.dispose();
  }

  // =========================================================
  // TARGETS LOADING
  // =========================================================
  Future<void> _bootstrapTargets({
    int? initialCategoryId,
    int? initialProductId,
  }) async {
    final token = await _store.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _loadingTargets = false;
        _targetsError = 'Missing admin token';
      });
      return;
    }

    try {
      // ✅ Hook these to your real implementations
      final categories = await _loadCategories(token);
      final products = await _loadProducts(token);

      Category? initCat;
      if (initialCategoryId != null) {
        initCat = categories
            .where((c) => c.id == initialCategoryId)
            .firstOrNull;
      }

      ItemSummary? initProd;
      if (initialProductId != null) {
        initProd = products.where((p) => p.id == initialProductId).firstOrNull;
      }

      setState(() {
        _categories = categories;
        _products = products;
        _selectedCategory = initCat;
        _selectedProduct = initProd;
        _loadingTargets = false;
        _targetsError = null;
      });
    } catch (e) {
      setState(() {
        _loadingTargets = false;
        _targetsError = e.toString();
      });
    }
  }

  // ----------------------------------------------------------------
  // IMPORTANT:
  // Replace these 2 with your actual repo/usecase calls.
  //
  // You already have:
  //   - GetCategoriesByProject
  //   - Admin products list screen/services
  //
  // So wire them here.
  // ----------------------------------------------------------------

  Future<List<Category>> _loadCategories(String token) async {
    final api = CategoryApiService();

    // Same logic you used in AdminCreateProductScreen
    final projectId = int.tryParse(Env.projectId!.trim());

    if (projectId == null || projectId <= 0) {
      // fallback (won't crash)
      return <Category>[];
    }

    final rawList = await api.getCategoriesByProject(
      projectId,
      authToken: token,
    );

    // ✅ If your Category has fromJson, use it:
    // return rawList.map((j) => Category.fromJson(j)).toList();

    // ✅ Otherwise map manually:
    return rawList.map<Category>((j) {
      final idRaw = j['id'];
      final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;
      final name = (j['name'] ?? '').toString();

      return Category(id: id, name: name);
    }).toList();
  }

  Future<List<ItemSummary>> _loadProducts(String token) async {
    final api = ProductApiService();

    final rawList = await api.getProducts(
     
      authToken: token,
    );

    return rawList.map<ItemSummary>((j) {
      final idRaw = j['id'];
      final id = idRaw is int ? idRaw : int.tryParse('$idRaw') ?? 0;

      final title = (j['name'] ?? '').toString();
      final imageUrl = (j['imageUrl'] ?? '').toString();

      final priceRaw = j['effectivePrice'] ?? j['price'];
      final price = priceRaw is num
          ? priceRaw.toDouble()
          : double.tryParse('$priceRaw');

      final subtitle = (j['description'] ?? '').toString();

      return ItemSummary(
        id: id,
        title: title,
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
        price: price,
        subtitle: subtitle.isEmpty ? null : subtitle,
        kind: ItemKind.product,
      );
    }).toList();
  }

  // =========================================================
  // IMAGE PICK
  // =========================================================
  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() {
      _imagePath = x.path;
    });
  }

  Future<void> _pickFromCamera() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (x == null) return;
    setState(() {
      _imagePath = x.path;
    });
  }

  void _clearPickedImage() {
    setState(() {
      _imagePath = null;
    });
  }

  // =========================================================
  // BODY
  // =========================================================
  int _parseInt(String v) => int.tryParse(v.trim()) ?? 0;

  Map<String, dynamic> _buildBody() {
    final type = _targetType;

    final body = <String, dynamic>{
      'ownerProjectId': widget.ownerProjectId,
      'title': _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      'subtitle': _subtitleCtrl.text.trim().isEmpty
          ? null
          : _subtitleCtrl.text.trim(),
      'sortOrder': _parseInt(_sortCtrl.text),
      'active': _active,

      // If you later add scheduling UI:
      // 'startAt': startAtIso,
      // 'endAt': endAtIso,
    };

    body['targetType'] = type.apiName;

    if (type == HomeBannerTargetTypeUi.url) {
      body['targetUrl'] = _targetUrlCtrl.text.trim();
      body['targetId'] = null;
    } else if (type == HomeBannerTargetTypeUi.category) {
      body['targetId'] = _selectedCategory?.id;
      body['targetUrl'] = null;
    } else if (type == HomeBannerTargetTypeUi.product) {
      body['targetId'] = _selectedProduct?.id;
      body['targetUrl'] = null;
    } else {
      body['targetId'] = null;
      body['targetUrl'] = null;
    }

    return body;
  }

  void _submit(AppLocalizations l) {
    if (!_formKey.currentState!.validate()) return;

    // ✅ extra target validation
    if (_targetType == HomeBannerTargetTypeUi.category &&
        _selectedCategory == null) {
      AppToast.error(
        context,
        l.adminHomeBannerCategoryRequired ?? 'Category is required',
        
      );
      return;
    }

    if (_targetType == HomeBannerTargetTypeUi.product &&
        _selectedProduct == null) {
      AppToast.error(
        context,
        l.adminHomeBannerProductRequired ?? 'Product is required',
        
      );
      return;
    }

    if (_targetType == HomeBannerTargetTypeUi.url &&
        _targetUrlCtrl.text.trim().isEmpty) {
      AppToast.error(
        context,
        l.adminHomeBannerUrlRequired ?? 'URL is required',
        
      );
      return;
    }

    // ✅ Create requires an image
    if (!_isEdit && (_imagePath == null || _imagePath!.isEmpty)) {
      AppToast.error(
        context,
        l.adminHomeBannerImageRequired ?? 'Image is required',
        
      );
      return;
    }

    Navigator.pop(context, {
      'body': _buildBody(),
      'imagePath': _imagePath, // optional for edit
    });
  }

  // =========================================================
  // UI
  // =========================================================
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    final title = _isEdit
        ? (l.adminHomeBannerEdit ?? 'Edit banner')
        : (l.adminHomeBannerCreate ?? 'Create banner');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: spacing.lg,
          right: spacing.lg,
          top: spacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + spacing.lg,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium.copyWith(color: c.label)),
                SizedBox(height: spacing.md),

                // ------------------ Image Preview ------------------
                _BannerImagePickerBlock(
                  imagePath: _imagePath,
                  existingUrl: _existingImageUrl,
                  onPickGallery: _pickFromGallery,
                  onPickCamera: _pickFromCamera,
                  onClear: _clearPickedImage,
                ),

                SizedBox(height: spacing.lg),

                // ------------------ Title / Subtitle / Sort ------------------
                AppTextField(
                  label: l.adminHomeBannerTitleLabel ?? 'Title',
                  controller: _titleCtrl,
                ),
                SizedBox(height: spacing.sm),

                AppTextField(
                  label: l.adminHomeBannerSubtitleLabel ?? 'Subtitle',
                  controller: _subtitleCtrl,
                ),
                SizedBox(height: spacing.sm),

                AppTextField(
                  label: l.adminHomeBannerSortLabel ?? 'Sort order',
                  controller: _sortCtrl,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: spacing.md),

                // ------------------ Active ------------------
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.adminActiveLabel ?? 'Active'),
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                ),

                SizedBox(height: spacing.md),

                // ------------------ Target Dynamic Section ------------------
                _TargetSection(
                  loading: _loadingTargets,
                  error: _targetsError,
                  targetType: _targetType,
                  categories: _categories,
                  products: _products,
                  selectedCategory: _selectedCategory,
                  selectedProduct: _selectedProduct,
                  targetUrlCtrl: _targetUrlCtrl,
                  onTargetTypeChanged: (v) {
                    setState(() {
                      _targetType = v;

                      // reset irrelevant selections
                      _selectedCategory = null;
                      _selectedProduct = null;
                      _targetUrlCtrl.clear();
                    });
                  },
                  onCategoryChanged: (v) =>
                      setState(() => _selectedCategory = v),
                  onProductChanged: (v) => setState(() => _selectedProduct = v),
                ),

                SizedBox(height: spacing.lg),

                // ------------------ Footer Buttons ------------------
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l.adminCancel ?? 'Cancel'),
                      ),
                    ),
                    SizedBox(width: spacing.sm),
                    Expanded(
                      child: PrimaryButton(
                        label: _isEdit
                            ? (l.adminUpdate ?? 'Update')
                            : (l.adminCreate ?? 'Create'),
                        onPressed: () => _submit(l),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// IMAGE PICKER BLOCK
// =========================================================

class _BannerImagePickerBlock extends StatelessWidget {
  final String? imagePath;
  final String? existingUrl;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onClear;

  const _BannerImagePickerBlock({
    required this.imagePath,
    required this.existingUrl,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    Widget preview;

    if (imagePath != null && imagePath!.isNotEmpty) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(tokens.card.radius),
        child: Image.file(
          File(imagePath!),
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if ((existingUrl ?? '').isNotEmpty) {
      // We don't resolve base URL here because the card will fix display;
      // form preview can still show relative only if your Image.network
      // can reach it. If you want absolute here too, add resolver same as card.
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(tokens.card.radius),
        child: Image.network(
          existingUrl!,
          height: 160,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallback(c, text),
        ),
      );
    } else {
      preview = _fallback(c, text);
    }

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: c.border.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.adminHomeBannerImageLabel ?? 'Banner image',
            style: text.titleMedium.copyWith(
              color: c.label,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: spacing.sm),
          preview,
          SizedBox(height: spacing.sm),

          Wrap(
            spacing: spacing.sm,
            children: [
              OutlinedButton.icon(
                onPressed: onPickGallery,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(l.adminPickFromGallery ?? 'Gallery'),
              ),
              OutlinedButton.icon(
                onPressed: onPickCamera,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l.adminPickFromCamera ?? 'Camera'),
              ),
              if (imagePath != null && imagePath!.isNotEmpty)
                TextButton.icon(
                  onPressed: onClear,
                  icon: Icon(Icons.close, color: c.danger),
                  label: Text(
                    l.adminRemoveImage ?? 'Remove',
                    style: TextStyle(color: c.danger),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallback(dynamic c, dynamic text) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.border.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: c.muted, size: 42),
    );
  }
}

// =========================================================
// TARGET SECTION (Dynamic)
// =========================================================

class _TargetSection extends StatelessWidget {
  final bool loading;
  final String? error;

  final HomeBannerTargetTypeUi targetType;

  final List<Category> categories;
  final List<ItemSummary> products;

  final Category? selectedCategory;
  final ItemSummary? selectedProduct;

  final TextEditingController targetUrlCtrl;

  final ValueChanged<HomeBannerTargetTypeUi> onTargetTypeChanged;
  final ValueChanged<Category?> onCategoryChanged;
  final ValueChanged<ItemSummary?> onProductChanged;

  const _TargetSection({
    required this.loading,
    required this.error,
    required this.targetType,
    required this.categories,
    required this.products,
    required this.selectedCategory,
    required this.selectedProduct,
    required this.targetUrlCtrl,
    required this.onTargetTypeChanged,
    required this.onCategoryChanged,
    required this.onProductChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    if (loading) {
      return Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.primary),
          ),
          SizedBox(width: spacing.sm),
          Text(
            l.adminHomeBannerLoadingTargets ?? 'Loading targets...',
            style: text.bodySmall.copyWith(color: c.muted),
          ),
        ],
      );
    }

    if (error != null) {
      return Text(error!, style: text.bodySmall.copyWith(color: c.danger));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.adminHomeBannerTargetTypeLabel ?? 'Target type',
          style: text.titleMedium.copyWith(color: c.label),
        ),
        SizedBox(height: spacing.xs),

        DropdownButtonFormField<HomeBannerTargetTypeUi>(
          value: targetType,
          decoration: InputDecoration(
            hintText: l.adminHomeBannerTargetTypeHint ?? 'Select target type',
          ),
          items: HomeBannerTargetTypeUi.values
              .map((e) => DropdownMenuItem(value: e, child: Text(e.label(l))))
              .toList(),
          onChanged: (v) =>
              onTargetTypeChanged(v ?? HomeBannerTargetTypeUi.none),
        ),

        SizedBox(height: spacing.md),

        if (targetType == HomeBannerTargetTypeUi.url) ...[
          AppTextField(
            label: l.adminHomeBannerTargetUrlLabel ?? 'Target URL',
            controller: targetUrlCtrl,
            keyboardType: TextInputType.url,
          ),
        ],

        if (targetType == HomeBannerTargetTypeUi.category) ...[
          Text(
            l.adminHomeBannerTargetCategoryLabel ?? 'Category',
            style: text.titleMedium,
          ),
          SizedBox(height: spacing.xs),
          _SearchablePicker<Category>(
            items: categories,
            value: selectedCategory,
            label: (x) => x.name,
            hintText: l.adminHomeBannerTargetCategoryHint ?? 'Select category',
            onChanged: onCategoryChanged,
          ),
        ],

        if (targetType == HomeBannerTargetTypeUi.product) ...[
          Text(
            l.adminHomeBannerTargetProductLabel ?? 'Product',
            style: text.titleMedium,
          ),
          SizedBox(height: spacing.xs),
          _SearchablePicker<ItemSummary>(
            items: products,
            value: selectedProduct,
            label: (x) => x.title,
            hintText: l.adminHomeBannerTargetProductHint ?? 'Select product',
            onChanged: onProductChanged,
          ),
        ],
      ],
    );
  }
}

// =========================================================
// GENERIC SEARCHABLE PICKER (same style as your shipping)
// =========================================================

class _SearchablePicker<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final bool enabled;
  final String hintText;
  final String Function(T) label;
  final ValueChanged<T?> onChanged;

  const _SearchablePicker({
    required this.items,
    required this.value,
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final text = tokens.typography;
    final spacing = tokens.spacing;

    final disabled = !enabled || items.isEmpty;

    return InkWell(
      onTap: disabled
          ? null
          : () async {
              final picked = await showModalBottomSheet<T>(
                context: context,
                isScrollControlled: true,
                builder: (_) => _PickerSheet<T>(
                  items: items,
                  label: label,
                  title: hintText,
                ),
              );
              if (picked != null) onChanged(picked);
            },
      borderRadius: BorderRadius.circular(tokens.card.radius),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: spacing.md,
          vertical: spacing.sm,
        ),
        decoration: BoxDecoration(
          color: enabled ? c.surface : c.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(tokens.card.radius),
          border: Border.all(color: c.border.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                items.isEmpty
                    ? (AppLocalizations.of(context)?.adminNoOptions ??
                          'No options')
                    : (value == null ? hintText : label(value as T)),
                style: text.bodyMedium.copyWith(
                  color: items.isEmpty
                      ? c.muted
                      : (value == null ? c.muted : c.label),
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: enabled ? c.muted : c.muted.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerSheet<T> extends StatefulWidget {
  final List<T> items;
  final String Function(T) label;
  final String title;

  const _PickerSheet({
    required this.items,
    required this.label,
    required this.title,
  });

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final _searchCtrl = TextEditingController();
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_apply);
  }

  void _apply() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items
                .where((i) => widget.label(i).toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: spacing.lg,
          right: spacing.lg,
          top: spacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + spacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: text.titleMedium.copyWith(color: c.label),
            ),
            SizedBox(height: spacing.md),

            AppSearchField(
              hintText:
                  AppLocalizations.of(context)?.searchLabel ?? 'Search...',
              controller: _searchCtrl,
            ),

            SizedBox(height: spacing.md),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: _filtered.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(spacing.lg),
                      child: Text(
                        AppLocalizations.of(context)?.noResultsLabel ??
                            'No results',
                        style: text.bodyMedium.copyWith(color: c.muted),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: c.border.withOpacity(0.15)),
                      itemBuilder: (_, i) {
                        final item = _filtered[i];
                        return ListTile(
                          title: Text(
                            widget.label(item),
                            style: text.bodyMedium,
                          ),
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// tiny ext
// =========================================================
extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
