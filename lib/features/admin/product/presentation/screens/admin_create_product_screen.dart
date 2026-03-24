// lib/features/admin/product/presentation/screens/admin_create_product_screen.dart

import 'dart:convert';
import 'dart:io';

import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/exceptions/app_exception.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/core/utils/upload_safe_image_normalizer.dart';
import 'package:build4front/features/admin/product/presentation/sections/admin_product_status_section.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/features/catalog/data/models/item_type_model.dart';
import 'package:build4front/features/catalog/data/services/category_api_service.dart';
import 'package:build4front/features/catalog/data/services/currency_api_service.dart';
import 'package:build4front/features/catalog/data/services/item_status_api_service.dart';
import 'package:build4front/features/catalog/data/services/item_type_api_service.dart';
import 'package:build4front/features/catalog/domain/entities/item_type.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/models/create_product_request.dart';
import '../../data/services/product_api_service.dart';
import '../../domain/entities/product.dart';

String productTypeDtoToApi(ProductTypeDto t) {
  switch (t) {
    case ProductTypeDto.variable:
      return 'VARIABLE';
    case ProductTypeDto.grouped:
      return 'GROUPED';
    case ProductTypeDto.external:
      return 'EXTERNAL';
    case ProductTypeDto.simple:
    default:
      return 'SIMPLE';
  }
}

class AdminCreateProductScreen extends StatefulWidget {
  final int ownerProjectId;
  final int? itemTypeId;
  final int? categoryId;
  final int? currencyId;
  final Product? initialProduct;

  const AdminCreateProductScreen({
    super.key,
    required this.ownerProjectId,
    this.itemTypeId,
    this.categoryId,
    this.currencyId,
    this.initialProduct,
  });

  @override
  State<AdminCreateProductScreen> createState() =>
      _AdminCreateProductScreenState();
}

class _AdminCreateProductScreenState extends State<AdminCreateProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();

  final _downloadUrlCtrl = TextEditingController();
  final _externalUrlCtrl = TextEditingController();
  final _buttonTextCtrl = TextEditingController();

  final _salePriceCtrl = TextEditingController();
  final _saleStartCtrl = TextEditingController();
  final _saleEndCtrl = TextEditingController();

  ProductTypeDto _selectedProductType = ProductTypeDto.simple;
  bool _virtualProduct = false;
  bool _downloadable = false;

  DateTime? _saleStartDate;
  DateTime? _saleEndDate;

  final List<_AttributeRow> _attributes = [];

  static const List<String> _allowedAttributeCodes = [
    'brand',
    'color',
    'size',
    'capacity',
    'material',
    'model',
  ];

  final _picker = ImagePicker();
  XFile? _pickedImage;

  List<_CategoryOption> _categories = [];
  int? _selectedCategoryId;

  List<ItemType> _itemTypes = [];
  int? _selectedItemTypeId;

  List<ItemStatusOptionUi> _itemStatuses = [];
  String? _selectedStatusCode;
  bool _loadingStatuses = false;

  int? _effectiveCurrencyId;
  bool _loadingCurrency = false;
  String? _currencyLabel;

  bool _loadingCategories = false;
  bool _loadingItemTypes = false;
  bool _isSubmitting = false;

  String? _errorMessage;
  String? _metaError;

  bool get _isEdit => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      if (_buttonTextCtrl.text.trim().isEmpty) {
        _buttonTextCtrl.text = l.adminButtonTextDefaultAddToCart;
      }
    });

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final rawCurrency = Env.currencyId.trim();
    _effectiveCurrencyId = widget.currencyId ??
        (rawCurrency.isNotEmpty ? int.tryParse(rawCurrency) : null);

    if (_isEdit) {
      _applyInitialProduct(widget.initialProduct!);
    }

    if (_effectiveCurrencyId != null) {
      await _loadCurrency(_effectiveCurrencyId!);
    }

    await _loadItemStatuses();
    await _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _skuCtrl.dispose();
    _downloadUrlCtrl.dispose();
    _externalUrlCtrl.dispose();
    _buttonTextCtrl.dispose();
    _salePriceCtrl.dispose();
    _saleStartCtrl.dispose();
    _saleEndCtrl.dispose();

    for (final row in _attributes) {
      row.dispose();
    }

    super.dispose();
  }

  void _applyInitialProduct(Product p) {
    _nameCtrl.text = p.name;
    _descriptionCtrl.text = p.description ?? '';
    _priceCtrl.text = p.price.toStringAsFixed(2);

    if (p.stock != null) {
      _stockCtrl.text = p.stock.toString();
    }

    _skuCtrl.text = p.sku ?? '';
    _selectedStatusCode = p.statusCode;

    _virtualProduct = p.virtualProduct;
    _downloadable = p.downloadable;

    _downloadUrlCtrl.text = p.downloadUrl ?? '';
    _externalUrlCtrl.text = p.externalUrl ?? '';
    _buttonTextCtrl.text = p.buttonText ?? '';

    _selectedProductType = _productTypeFromString(p.productType);

    if (_downloadable) {
      _selectedProductType = ProductTypeDto.simple;
      _virtualProduct = true;
      _externalUrlCtrl.clear();
      _buttonTextCtrl.clear();
    }

    if (p.salePrice != null) {
      _salePriceCtrl.text = p.salePrice!.toStringAsFixed(2);
    }
    if (p.saleStart != null) {
      _saleStartDate = p.saleStart;
      _saleStartCtrl.text = _formatDateForBackend(p.saleStart!);
    }
    if (p.saleEnd != null) {
      _saleEndDate = p.saleEnd;
      _saleEndCtrl.text = _formatDateForBackend(p.saleEnd!);
    }

    _attributes.clear();
    p.attributes.forEach((code, value) {
      if (_allowedAttributeCodes.contains(code)) {
        final row = _AttributeRow(selectedCode: code);
        row.valueCtrl.text = value;
        _attributes.add(row);
      }
    });

    _selectedCategoryId = p.categoryId;
    _selectedItemTypeId = p.itemTypeId;
  }

  ProductTypeDto _productTypeFromString(String s) {
    switch (s.toUpperCase()) {
      case 'VARIABLE':
        return ProductTypeDto.variable;
      case 'GROUPED':
        return ProductTypeDto.grouped;
      case 'EXTERNAL':
        return ProductTypeDto.external;
      case 'SIMPLE':
      default:
        return ProductTypeDto.simple;
    }
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _parseBackendDate(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    try {
      return DateTime.parse(t);
    } catch (_) {
      return null;
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String? _validateSaleFields(
    AppLocalizations l, {
    required double regularPrice,
  }) {
    final salePriceText = _salePriceCtrl.text.trim();
    final hasSalePrice = salePriceText.isNotEmpty;

    final startRaw = _saleStartDate ?? _parseBackendDate(_saleStartCtrl.text);
    final endRaw = _saleEndDate ?? _parseBackendDate(_saleEndCtrl.text);

    final hasStart = startRaw != null;
    final hasEnd = endRaw != null;

    if (!_isEdit && (hasStart != hasEnd)) {
      return l.adminProductSaleDatesBothRequired;
    }

    if (hasStart && hasEnd) {
      final start = _dateOnly(startRaw!);
      final end = _dateOnly(endRaw!);

      if (end.isBefore(start)) {
        return l.adminProductSaleEndBeforeStart;
      }

      if (!_isEdit) {
        final today = _dateOnly(DateTime.now());
        if (start.isBefore(today)) return l.adminProductSaleStartInPast;
        if (end.isBefore(today)) return l.adminProductSaleEndInPast;
      }

      if (!hasSalePrice) {
        return l.adminProductSalePriceRequiredForDates;
      }
    }

    if (hasSalePrice) {
      final v = double.tryParse(salePriceText);
      if (v == null || v <= 0) return l.adminProductSalePriceInvalid;
      if (v >= regularPrice) return l.adminProductSalePriceMustBeLess;
    }

    return null;
  }

  String _formatDateForBackend(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day'
        'T00:00:00';
  }

  Future<void> _pickSaleStartDate() async {
    final l = AppLocalizations.of(context)!;

    final now = DateTime.now();
    final today = _dateOnly(now);

    final first = _isEdit ? DateTime(now.year - 5, 1, 1) : today;
    final last = DateTime(now.year + 5, 12, 31);

    DateTime initial = _saleStartDate ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        _saleStartDate = picked;
        _saleStartCtrl.text = _formatDateForBackend(picked);

        if (_saleEndDate != null &&
            _dateOnly(_saleEndDate!).isBefore(_dateOnly(picked))) {
          _saleEndDate = null;
          _saleEndCtrl.clear();
          _showSnack(l.adminProductSaleEndAutoCleared);
        }
      });
    }
  }

  Future<void> _pickSaleEndDate() async {
    final now = DateTime.now();
    final today = _dateOnly(now);

    final first = _saleStartDate != null
        ? _dateOnly(_saleStartDate!)
        : (_isEdit ? DateTime(now.year - 5, 1, 1) : today);

    final last = DateTime(now.year + 5, 12, 31);

    DateTime initial = _saleEndDate ?? _saleStartDate ?? today;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        _saleEndDate = picked;
        _saleEndCtrl.text = _formatDateForBackend(picked);
      });
    }
  }

  Future<void> _pickImage() async {
  final normalizedPath = await UploadSafeImageNormalizer.pickNormalizedImage(
    picker: _picker,
    source: ImageSource.gallery,
    imageQuality: 85,
    maxWidth: 1800,
    maxHeight: 1800,
    preferredName: 'product',
  );

  if (normalizedPath != null && normalizedPath.isNotEmpty) {
    setState(() => _pickedImage = XFile(normalizedPath));
  }
}
  void _removePickedImage() {
    setState(() => _pickedImage = null);
  }

  Future<String> _requireAdminToken() async {
    final token = await AdminTokenStore().getToken();
    if (token == null || token.isEmpty) {
      throw Exception('ADMIN_TOKEN_MISSING');
    }
    return token;
  }

  String _localizeError(Object e, AppLocalizations l) {
    if (e is AppException) {
      final dynamic ex = e;
      final Object? orig = ex.original;
      if (orig != null) {
        return _localizeError(orig, l);
      }

      final String msg = (ex.message ?? e.toString()).toString();
      if (msg.trim().isNotEmpty) return msg;

      return l.adminGenericError;
    }

    if (e is DioException) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      Map<String, dynamic>? m;

      if (data is Map) {
        m = Map<String, dynamic>.from(data);
      } else if (data is String) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) m = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }

      final code = m?['code']?.toString();
      final rawError = (m?['error'] ?? m?['message'])?.toString();

      final countRaw = m?['count'];
      final int? count = (countRaw is num)
          ? countRaw.toInt()
          : int.tryParse(countRaw?.toString() ?? '');

      if (status == 409) {
        if (code == 'CATEGORY_DELETE_HAS_ITEMS') {
          return l.adminCategoryDeleteBlockedItems(count ?? 0);
        }
        if (code == 'ITEMTYPE_DELETE_HAS_ITEMS') {
          return l.adminItemTypeDeleteBlockedItems(count ?? 0);
        }
        if (code == 'CATEGORY_DELETE_HAS_TYPES') {
          return l.adminCategoryDeleteBlockedTypes(count ?? 0);
        }

        if (rawError != null && rawError.trim().isNotEmpty) return rawError;
        return l.adminConflictGeneric;
      }

      if (status == 401) return l.errSessionExpired;
      if (status == 403) return l.errForbidden;
      if (status == 404) return l.errNotFound;

      if (rawError != null && rawError.trim().isNotEmpty) return rawError;

      return l.adminGenericError;
    }

    final s = e.toString();
    if (s.contains('ADMIN_TOKEN_MISSING')) return l.adminMissingAdminToken;

    return l.adminGenericError;
  }

  String? _resolveImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;

    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '${Env.apiBaseUrl}$trimmed';
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
  }) async {
    final l = AppLocalizations.of(context)!;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.adminRemove),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteSelectedCategory() async {
    final categoryId = _selectedCategoryId;
    if (categoryId == null) return;

    final l = AppLocalizations.of(context)!;

    final catName = _categories
        .firstWhere(
          (c) => c.id == categoryId,
          orElse: () => _CategoryOption(
            id: categoryId,
            name: l.adminCategoryFallbackName,
          ),
        )
        .name;

    final ok = await _confirmDelete(
      title: l.adminDeleteCategoryTitle,
      message: l.adminDeleteCategoryMessage(catName),
    );
    if (!ok) return;

    setState(() {
      _metaError = null;
      _loadingCategories = true;
    });

    try {
      final token = await _requireAdminToken();
      final api = CategoryApiService();

      await api.deleteCategory(
        categoryId,
        authToken: token,
      );

      final nextCats = _categories.where((c) => c.id != categoryId).toList();
      final nextSelected = nextCats.isNotEmpty ? nextCats.first.id : null;

      if (!mounted) return;
      setState(() {
        _categories = nextCats;
        _selectedCategoryId = nextSelected;
        _itemTypes = [];
        _selectedItemTypeId = null;
      });

      if (nextSelected != null) {
        await _loadItemTypesForCategory(nextSelected);
      }
    } catch (e) {
      if (!mounted) return;

      final msg = _localizeError(e, l);
      AppToast.error(context, msg);
      setState(() => _metaError = msg);
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _deleteSelectedItemType() async {
    final itemTypeId = _selectedItemTypeId;
    if (itemTypeId == null) return;

    final l = AppLocalizations.of(context)!;

    final typeName = _itemTypes
        .firstWhere(
          (t) => t.id == itemTypeId,
          orElse: () =>
              ItemType(id: itemTypeId, name: l.adminItemTypeFallbackName),
        )
        .name;

    final ok = await _confirmDelete(
      title: l.adminDeleteItemTypeTitle,
      message: l.adminDeleteItemTypeMessage(typeName),
    );
    if (!ok) return;

    setState(() {
      _metaError = null;
      _loadingItemTypes = true;
    });

    try {
      final token = await _requireAdminToken();
      final api = ItemTypeApiService();

      await api.deleteItemType(itemTypeId, authToken: token);

      final nextTypes = _itemTypes.where((t) => t.id != itemTypeId).toList();
      final nextSelected = nextTypes.isNotEmpty ? nextTypes.first.id : null;

      if (!mounted) return;
      setState(() {
        _itemTypes = nextTypes;
        _selectedItemTypeId = nextSelected;
      });
    } catch (e) {
      if (!mounted) return;

      final msg = _localizeError(e, l);
      AppToast.error(context, msg);
      setState(() => _metaError = msg);
    } finally {
      if (mounted) setState(() => _loadingItemTypes = false);
    }
  }

  Future<void> _loadCurrency(int id) async {
    setState(() => _loadingCurrency = true);

    try {
      final token = await _requireAdminToken();
      final api = CurrencyApiService();

      final data = await api.getCurrencyById(id, authToken: token);

      final code = (data['code'] ?? '').toString();
      final symbol = (data['symbol'] ?? '').toString();
      final type = (data['currencyType'] ?? data['type'] ?? '').toString();

      String label = '';
      if (code.isNotEmpty && symbol.isNotEmpty) {
        label = '$code ($symbol)';
      } else if (code.isNotEmpty) {
        label = code;
      } else if (type.isNotEmpty) {
        label = type;
      }

      if (!mounted) return;
      setState(() => _currencyLabel = label.isEmpty ? null : label);
    } catch (_) {
      // non-blocking
    } finally {
      if (mounted) setState(() => _loadingCurrency = false);
    }
  }

  Future<void> _loadItemStatuses() async {
    setState(() {
      _loadingStatuses = true;
      _metaError = null;
    });

    try {
      final token = await _requireAdminToken();
      final api = ItemStatusApiService();

      final rawList = await api.getItemStatuses(authToken: token);

      final statuses = rawList
          .whereType<Map>()
          .map(
            (m) => ItemStatusOptionUi(
              id: int.tryParse('${m['id']}') ?? 0,
              code: (m['code'] ?? '').toString(),
              name: (m['name'] ?? '').toString(),
            ),
          )
          .toList();

      String? initialStatusCode;

      final p = widget.initialProduct;
      if (p != null &&
          p.statusCode != null &&
          statuses.any((s) => s.code == p.statusCode)) {
        initialStatusCode = p.statusCode;
      } else if (_selectedStatusCode != null &&
          statuses.any((s) => s.code == _selectedStatusCode)) {
        initialStatusCode = _selectedStatusCode;
      } else if (statuses.isNotEmpty) {
        initialStatusCode = statuses.first.code;
      }

      if (!mounted) return;
      setState(() {
        _itemStatuses = statuses;
        _selectedStatusCode = initialStatusCode;
      });
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() => _metaError = _localizeError(e, l));
    } finally {
      if (mounted) {
        setState(() => _loadingStatuses = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
      _metaError = null;
    });

    try {
      final token = await _requireAdminToken();
      final api = CategoryApiService();

      final rawList = await api.getCategoriesForTenant(
        authToken: token,
      );

      final cats = rawList.map(_CategoryOption.fromJson).toList();

      int? initialCategoryId;

      final p = widget.initialProduct;
      if (p != null &&
          p.categoryId != null &&
          cats.any((c) => c.id == p.categoryId)) {
        initialCategoryId = p.categoryId;
      } else if (widget.categoryId != null &&
          cats.any((c) => c.id == widget.categoryId)) {
        initialCategoryId = widget.categoryId;
      } else if (_selectedCategoryId != null &&
          cats.any((c) => c.id == _selectedCategoryId)) {
        initialCategoryId = _selectedCategoryId;
      } else if (cats.isNotEmpty) {
        initialCategoryId = cats.first.id;
      }

      if (!mounted) return;
      setState(() {
        _categories = cats;
        _selectedCategoryId = initialCategoryId;
      });

      if (initialCategoryId != null) {
        await _loadItemTypesForCategory(initialCategoryId);
      }
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() => _metaError = _localizeError(e, l));
    } finally {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadItemTypesForCategory(int categoryId) async {
    setState(() {
      _loadingItemTypes = true;
      _metaError = null;
      _itemTypes = [];
      _selectedItemTypeId = null;
    });

    try {
      final token = await _requireAdminToken();
      final api = ItemTypeApiService();

      final rawList =
          await api.getItemTypesByCategory(categoryId, authToken: token);

      final types =
          rawList.map((m) => ItemTypeModel.fromJson(m).toEntity()).toList();

      int? initialTypeId;

      final p = widget.initialProduct;
      if (p != null &&
          p.itemTypeId != null &&
          types.any((t) => t.id == p.itemTypeId)) {
        initialTypeId = p.itemTypeId;
      } else if (widget.itemTypeId != null &&
          types.any((t) => t.id == widget.itemTypeId)) {
        initialTypeId = widget.itemTypeId;
      } else if (_selectedItemTypeId != null &&
          types.any((t) => t.id == _selectedItemTypeId)) {
        initialTypeId = _selectedItemTypeId;
      } else if (types.isNotEmpty) {
        initialTypeId = types.first.id;
      }

      if (!mounted) return;
      setState(() {
        _itemTypes = types;
        _selectedItemTypeId = initialTypeId;
      });
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() => _metaError = _localizeError(e, l));
    } finally {
      if (mounted) setState(() => _loadingItemTypes = false);
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final l = AppLocalizations.of(context)!;
    final ctrl = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.adminNewCategoryTitle),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            onChanged: (_) {
              if (errorText != null && ctrl.text.trim().isNotEmpty) {
                setState(() => errorText = null);
              }
            },
            decoration: InputDecoration(
              hintText: l.adminNewCategoryHint,
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () {
                final v = ctrl.text.trim();
                if (v.isEmpty) {
                  setState(() => errorText = l.adminProductNameRequired);
                  return;
                }
                Navigator.of(ctx).pop(v);
              },
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.trim().isEmpty) return;
    await _createCategory(result.trim());
  }

  Future<void> _createCategory(String name) async {
    try {
      final token = await _requireAdminToken();
      final api = CategoryApiService();

      final data = await api.createCategory(
        name: name,
        authToken: token,
      );

      final cat = _CategoryOption.fromJson(data);

      if (!mounted) return;
      setState(() {
        _categories = [..._categories, cat];
        _selectedCategoryId = cat.id;
        _metaError = null;
      });

      await _loadItemTypesForCategory(cat.id);
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() => _metaError = _localizeError(e, l));
    }
  }

  Future<void> _showCreateItemTypeDialog() async {
    final l = AppLocalizations.of(context)!;

    final categoryId = _selectedCategoryId;
    if (categoryId == null) {
      setState(() => _metaError = l.adminSelectCategoryFirst);
      return;
    }

    final ctrl = TextEditingController();
    String? errorText;

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l.adminNewItemTypeTitle),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            onChanged: (_) {
              if (errorText != null && ctrl.text.trim().isNotEmpty) {
                setState(() => errorText = null);
              }
            },
            decoration: InputDecoration(
              hintText: l.adminNewItemTypeHint,
              errorText: errorText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.commonCancel),
            ),
            TextButton(
              onPressed: () {
                final v = ctrl.text.trim();
                if (v.isEmpty) {
                  setState(() => errorText = l.adminProductNameRequired);
                  return;
                }
                Navigator.of(ctx).pop(v);
              },
              child: Text(l.commonSave),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.trim().isEmpty) return;
    await _createItemType(result.trim(), categoryId);
  }

  Future<void> _createItemType(String name, int categoryId) async {
    try {
      final token = await _requireAdminToken();
      final api = ItemTypeApiService();

      final data = await api.createItemType(
        name: name,
        categoryId: categoryId,
        authToken: token,
      );

      final newType = ItemTypeModel.fromJson(data).toEntity();

      if (!mounted) return;
      setState(() {
        _itemTypes = [..._itemTypes, newType];
        _selectedItemTypeId = newType.id;
      });
    } catch (e) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      setState(() => _metaError = _localizeError(e, l));
    }
  }

  Set<String> _usedAttributeCodes({int? exceptIndex}) {
    final used = <String>{};
    for (int i = 0; i < _attributes.length; i++) {
      if (exceptIndex != null && i == exceptIndex) continue;
      final code = _attributes[i].selectedCode;
      if (code != null && code.trim().isNotEmpty) {
        used.add(code);
      }
    }
    return used;
  }

  List<String> _availableCodesForRow(int index) {
    final usedElsewhere = _usedAttributeCodes(exceptIndex: index);
    final current = _attributes[index].selectedCode;

    return _allowedAttributeCodes.where((code) {
      if (code == current) return true;
      return !usedElsewhere.contains(code);
    }).toList();
  }

  void _addAttributeRow() {
    final used = _usedAttributeCodes();
    final available = _allowedAttributeCodes
        .where((code) => !used.contains(code))
        .toList();

    if (available.isEmpty) {
      final l = AppLocalizations.of(context)!;
      AppToast.error(
        context,
        l.adminAllAttributeTypesAlreadyAdded,
      );
      return;
    }

    setState(() {
      _attributes.add(
        _AttributeRow(selectedCode: available.first),
      );
    });
  }

  void _removeAttributeRow(int index) {
    setState(() {
      _attributes[index].dispose();
      _attributes.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) return;

    final categoryId = _selectedCategoryId ?? widget.categoryId;
    if (categoryId == null) {
      setState(() => _errorMessage = l.adminSelectCategoryBeforeSavingProduct);
      return;
    }

    final currencyId = widget.currencyId ?? _effectiveCurrencyId;
    if (currencyId == null) {
      setState(() => _errorMessage = l.adminMissingCurrencyConfig);
      return;
    }

    if (_selectedStatusCode == null || _selectedStatusCode!.trim().isEmpty) {
      setState(() => _errorMessage = l.adminProductStatusRequired);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final price = double.parse(_priceCtrl.text.trim());

      if (_downloadable) {
        if (_selectedProductType != ProductTypeDto.simple) {
          setState(() => _errorMessage = l.adminDownloadableMustBeSimple);
          return;
        }

        if (!_virtualProduct) {
          setState(() => _errorMessage = l.adminDownloadableMustBeVirtual);
          return;
        }

        if (_downloadUrlCtrl.text.trim().isEmpty) {
          setState(() => _errorMessage = l.adminDownloadUrlRequired);
          return;
        }
      }

      if (_selectedProductType == ProductTypeDto.external) {
        if (_externalUrlCtrl.text.trim().isEmpty) {
          setState(() => _errorMessage = l.adminExternalUrlRequired);
          return;
        }

        if (_downloadable) {
          setState(() => _errorMessage = l.adminExternalCannotBeDownloadable);
          return;
        }
      }

      final saleErr = _validateSaleFields(l, regularPrice: price);
      if (saleErr != null) {
        setState(() => _errorMessage = saleErr);
        return;
      }

      final stock = _stockCtrl.text.trim().isEmpty
          ? null
          : int.parse(_stockCtrl.text.trim());

      final salePrice = _salePriceCtrl.text.trim().isEmpty
          ? null
          : double.parse(_salePriceCtrl.text.trim());

      final attrs = _attributes
          .where(
            (row) =>
                row.selectedCode != null &&
                row.valueCtrl.text.trim().isNotEmpty,
          )
          .map(
            (row) => AttributeValueDto(
              code: row.selectedCode!,
              value: row.valueCtrl.text.trim(),
            ),
          )
          .toList();

      final itemTypeId = _selectedItemTypeId ?? widget.itemTypeId;

      String? clean(String? v) {
        final s = (v ?? '').trim();
        return s.isEmpty ? null : s;
      }

      final description = clean(_descriptionCtrl.text);
      final sku = clean(_skuCtrl.text);

      final isExternal = _selectedProductType == ProductTypeDto.external;

      final downloadUrl = _downloadable ? clean(_downloadUrlCtrl.text) : null;
      final externalUrl = isExternal ? clean(_externalUrlCtrl.text) : null;
      final buttonText = isExternal ? clean(_buttonTextCtrl.text) : null;

      final saleStartText = clean(_saleStartCtrl.text);
      final saleEndText = clean(_saleEndCtrl.text);

      if (!_isEdit) {
        final req = CreateProductRequest(
          itemTypeId: itemTypeId,
          categoryId: categoryId,
          currencyId: currencyId,
          name: _nameCtrl.text.trim(),
          description: description,
          price: price,
          stock: stock,
          statusCode: _selectedStatusCode,
          sku: sku,
          productType:
              _downloadable ? ProductTypeDto.simple : _selectedProductType,
          virtualProduct: _downloadable ? true : _virtualProduct,
          downloadable: _downloadable,
          downloadUrl: _downloadable ? downloadUrl : null,
          externalUrl: _downloadable ? null : externalUrl,
          buttonText: _downloadable ? null : buttonText,
          salePrice: salePrice,
          saleStart: saleStartText,
          saleEnd: saleEndText,
          attributes: attrs,
        );

        await _createProduct(req);
      } else {
        await _updateProduct(
          productId: widget.initialProduct!.id,
          reqBody: {
            'categoryId': categoryId,
            if (itemTypeId != null) 'itemTypeId': itemTypeId,
            'currencyId': currencyId,
            'name': _nameCtrl.text.trim(),
            'description': description,
            'price': price,
            'stock': stock,
            'statusCode': _selectedStatusCode,
            'sku': sku,
            'productType': productTypeDtoToApi(
              _downloadable ? ProductTypeDto.simple : _selectedProductType,
            ),
            'virtualProduct': _downloadable ? true : _virtualProduct,
            'downloadable': _downloadable,
            'downloadUrl': _downloadable ? downloadUrl : null,
            'externalUrl': _downloadable ? null : externalUrl,
            'buttonText': _downloadable ? null : buttonText,
            'salePrice': salePrice,
            'saleStart': saleStartText,
            'saleEnd': saleEndText,
            'attributes': attrs.map((e) => e.toJson()).toList(),
          },
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _errorMessage = _localizeError(e, l));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _createProduct(CreateProductRequest req) async {
    final token = await _requireAdminToken();
    final api = ProductApiService();

    // debugPrint('CREATE PRODUCT BODY => ${jsonEncode(req.toJson())}');

    if (_pickedImage != null) {
      await api.createWithImage(
        body: req.toJson(),
        imagePath: _pickedImage!.path,
        authToken: token,
      );
    } else {
      await api.create(body: req.toJson(), authToken: token);
    }
  }

  Future<void> _updateProduct({
    required int productId,
    required Map<String, dynamic> reqBody,
  }) async {
    final token = await _requireAdminToken();
    final api = ProductApiService();

    // debugPrint('UPDATE PRODUCT BODY => ${jsonEncode(reqBody)}');

    if (_pickedImage != null) {
      await api.updateWithImage(
        id: productId,
        body: reqBody,
        imagePath: _pickedImage!.path,
        authToken: token,
      );
    } else {
      await api.update(id: productId, body: reqBody, authToken: token);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        title: Text(
          _isEdit ? l.adminProductEditTitle : l.adminProductCreateTitle,
          style: text.titleMedium.copyWith(color: c.label),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(spacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _AdminFormHeader(tokens: tokens, l: l, isEdit: _isEdit),
                SizedBox(height: spacing.lg),
                AdminProductBasicInfoSection(
                  tokens: tokens,
                  l: l,
                  nameCtrl: _nameCtrl,
                  descriptionCtrl: _descriptionCtrl,
                ),
                SizedBox(height: spacing.md),
                AdminProductCategoryTypeSection(
                  tokens: tokens,
                  l: l,
                  categories: _categories,
                  selectedCategoryId: _selectedCategoryId,
                  loadingCategories: _loadingCategories,
                  itemTypes: _itemTypes,
                  selectedItemTypeId: _selectedItemTypeId,
                  loadingItemTypes: _loadingItemTypes,
                  metaError: _metaError,
                  onCategoryChanged: (id) async {
                    if (id == null) return;
                    setState(() {
                      _selectedCategoryId = id;
                      _selectedItemTypeId = null;
                    });
                    await _loadItemTypesForCategory(id);
                  },
                  onItemTypeChanged: (id) {
                    setState(() => _selectedItemTypeId = id);
                  },
                  onCreateCategory: _showCreateCategoryDialog,
                  onCreateItemType: _showCreateItemTypeDialog,
                  onDeleteCategory: _deleteSelectedCategory,
                  onDeleteItemType: _deleteSelectedItemType,
                ),
                SizedBox(height: spacing.md),
                AdminProductPricingSection(
                  tokens: tokens,
                  l: l,
                  priceCtrl: _priceCtrl,
                  stockCtrl: _stockCtrl,
                  loadingCurrency: _loadingCurrency,
                  currencyLabel: _currencyLabel,
                ),
                SizedBox(height: spacing.md),
                AdminProductStatusSection(
                  tokens: tokens,
                  l: l,
                  statuses: _itemStatuses,
                  selectedStatusCode: _selectedStatusCode,
                  loadingStatuses: _loadingStatuses,
                  onChanged: (code) {
                    setState(() => _selectedStatusCode = code);
                  },
                  errorText: null,
                ),
                SizedBox(height: spacing.md),
                AdminProductImageSection(
                  tokens: tokens,
                  l: l,
                  pickedImage: _pickedImage,
                  existingImageUrl:
                      _resolveImageUrl(widget.initialProduct?.imageUrl),
                  onPickImage: _pickImage,
                  onRemoveImage: _removePickedImage,
                ),
                SizedBox(height: spacing.md),
                AdminProductConfigSection(
                  tokens: tokens,
                  l: l,
                  skuCtrl: _skuCtrl,
                  selectedProductType: _selectedProductType,
                  onProductTypeChanged: (val) {
                    setState(() {
                      _selectedProductType = val;

                      if (val == ProductTypeDto.external) {
                        _downloadable = false;
                        _downloadUrlCtrl.clear();
                      } else {
                        _externalUrlCtrl.clear();
                        _buttonTextCtrl.clear();
                      }

                      if (_downloadable) {
                        _selectedProductType = ProductTypeDto.simple;
                        _virtualProduct = true;
                      }
                    });
                  },
                  virtualProduct: _virtualProduct,
                  onVirtualChanged: (v) {
                    setState(() {
                      if (_downloadable && !v) {
                        _virtualProduct = true;
                      } else {
                        _virtualProduct = v;
                      }
                    });
                  },
                  downloadable: _downloadable,
                  onDownloadableChanged: (v) {
                    setState(() {
                      _downloadable = v;

                      if (v) {
                        _selectedProductType = ProductTypeDto.simple;
                        _virtualProduct = true;
                        _externalUrlCtrl.clear();
                        _buttonTextCtrl.clear();
                      } else {
                        _downloadUrlCtrl.clear();
                      }
                    });
                  },
                  downloadUrlCtrl: _downloadUrlCtrl,
                  externalUrlCtrl: _externalUrlCtrl,
                  buttonTextCtrl: _buttonTextCtrl,
                ),
                SizedBox(height: spacing.md),
                AdminProductSaleSection(
                  tokens: tokens,
                  l: l,
                  salePriceCtrl: _salePriceCtrl,
                  saleStartCtrl: _saleStartCtrl,
                  saleEndCtrl: _saleEndCtrl,
                  onPickSaleStart: _pickSaleStartDate,
                  onPickSaleEnd: _pickSaleEndDate,
                ),
                SizedBox(height: spacing.md),
                AdminProductAttributesSection(
                  tokens: tokens,
                  l: l,
                  attributes: _attributes,
                  allowedAttributeCodes: _allowedAttributeCodes,
                  onAddAttribute: _addAttributeRow,
                  onRemoveAttribute: _removeAttributeRow,
                  availableCodesForRow: _availableCodesForRow,
                ),
                SizedBox(height: spacing.lg),
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: spacing.md),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _errorMessage!,
                        style: text.bodyMedium.copyWith(color: c.danger),
                      ),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.adminProductSaveButton),
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

class AdminFormSectionCard extends StatelessWidget {
  final dynamic tokens;
  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;

  const AdminFormSectionCard({
    super.key,
    required this.tokens,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: c.border.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: c.label.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (icon != null)
                  Padding(
                    padding: EdgeInsets.only(right: spacing.xs),
                    child: Icon(icon, size: 18, color: c.primary),
                  ),
                Text(
                  title!,
                  style: text.titleMedium.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (subtitle != null) ...[
              SizedBox(height: spacing.xs),
              Text(subtitle!, style: text.bodySmall.copyWith(color: c.muted)),
            ],
            SizedBox(height: spacing.sm),
          ],
          child,
        ],
      ),
    );
  }
}

class _AdminFormHeader extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;
  final bool isEdit;

  const _AdminFormHeader({
    required this.tokens,
    required this.l,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    final text = tokens.typography;
    final c = tokens.colors;
    final spacing = tokens.spacing;

    return Row(
      children: [
        Icon(
          isEdit ? Icons.edit_outlined : Icons.add_box_outlined,
          color: c.primary,
          size: 28,
        ),
        SizedBox(width: spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? l.adminProductEditTitle : l.adminProductCreateTitle,
                style: text.headlineSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: c.label,
                ),
              ),
              SizedBox(height: spacing.xs),
              Text(
                isEdit
                    ? l.adminProductEditSubtitle
                    : l.adminProductCreateSubtitle,
                style: text.bodySmall.copyWith(color: c.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminProductBasicInfoSection extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;
  final TextEditingController nameCtrl;
  final TextEditingController descriptionCtrl;

  const AdminProductBasicInfoSection({
    super.key,
    required this.tokens,
    required this.l,
    required this.nameCtrl,
    required this.descriptionCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return AdminFormSectionCard(
      tokens: tokens,
      title: l.adminProductSectionBasicInfoTitle,
      subtitle: l.adminProductSectionBasicInfoSubtitle,
      icon: Icons.text_fields_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.adminProductNameLabel, style: text.titleMedium),
          SizedBox(height: spacing.xs),
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(hintText: l.adminProductNameHint),
            validator: (v) => v == null || v.trim().isEmpty
                ? l.adminProductNameRequired
                : null,
          ),
          SizedBox(height: spacing.md),
          Text(l.adminProductDescriptionLabel, style: text.titleMedium),
          SizedBox(height: spacing.xs),
          TextFormField(
            controller: descriptionCtrl,
            maxLines: 3,
            decoration:
                InputDecoration(hintText: l.adminProductDescriptionHint),
          ),
        ],
      ),
    );
  }
}

class AdminProductCategoryTypeSection extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;

  final List<_CategoryOption> categories;
  final int? selectedCategoryId;
  final bool loadingCategories;

  final List<ItemType> itemTypes;
  final int? selectedItemTypeId;
  final bool loadingItemTypes;

  final String? metaError;

  final Future<void> Function(int?) onCategoryChanged;
  final ValueChanged<int?> onItemTypeChanged;

  final VoidCallback onCreateCategory;
  final VoidCallback onCreateItemType;
  final VoidCallback onDeleteCategory;
  final VoidCallback onDeleteItemType;

  const AdminProductCategoryTypeSection({
    super.key,
    required this.tokens,
    required this.l,
    required this.categories,
    required this.selectedCategoryId,
    required this.loadingCategories,
    required this.itemTypes,
    required this.selectedItemTypeId,
    required this.loadingItemTypes,
    required this.metaError,
    required this.onCategoryChanged,
    required this.onItemTypeChanged,
    required this.onCreateCategory,
    required this.onCreateItemType,
    required this.onDeleteCategory,
    required this.onDeleteItemType,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = tokens.spacing;
    final c = tokens.colors;
    final text = tokens.typography;

    final canDeleteCategory =
        !loadingCategories && selectedCategoryId != null && categories.isNotEmpty;
    final canDeleteType =
        !loadingItemTypes && selectedItemTypeId != null && itemTypes.isNotEmpty;

    return AdminFormSectionCard(
      tokens: tokens,
      title: l.adminProductSectionCategoryTypeTitle,
      subtitle: l.adminProductSectionCategoryTypeSubtitle,
      icon: Icons.category_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.adminProductCategoryLabel, style: text.titleMedium),
          SizedBox(height: spacing.xs),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  items: categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: loadingCategories ? null : onCategoryChanged,
                  decoration: InputDecoration(
                    hintText: loadingCategories
                        ? l.adminProductLoadingCategories
                        : l.adminProductSelectCategoryHint,
                  ),
                ),
              ),
              SizedBox(width: spacing.xs),
              IconButton(
                onPressed: loadingCategories ? null : onCreateCategory,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: l.adminCreateCategoryTooltip,
              ),
              IconButton(
                onPressed: canDeleteCategory ? onDeleteCategory : null,
                icon: const Icon(Icons.delete_outline),
                color: c.danger,
                tooltip: l.adminDeleteCategoryTooltip,
              ),
            ],
          ),
          SizedBox(height: spacing.md),
          Text(l.adminProductItemTypeLabel, style: text.titleMedium),
          SizedBox(height: spacing.xs),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedItemTypeId,
                  items: itemTypes
                      .map(
                        (it) => DropdownMenuItem<int>(
                          value: it.id,
                          child: Text(it.name),
                        ),
                      )
                      .toList(),
                  onChanged: loadingItemTypes || selectedCategoryId == null
                      ? null
                      : onItemTypeChanged,
                  decoration: InputDecoration(
                    hintText: selectedCategoryId == null
                        ? l.adminSelectCategoryFirst
                        : loadingItemTypes
                            ? l.adminProductLoadingItemTypes
                            : l.adminProductSelectItemTypeHint,
                  ),
                ),
              ),
              SizedBox(width: spacing.xs),
              IconButton(
                onPressed:
                    loadingItemTypes || selectedCategoryId == null ? null : onCreateItemType,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: l.adminCreateItemTypeTooltip,
              ),
              IconButton(
                onPressed: canDeleteType ? onDeleteItemType : null,
                icon: const Icon(Icons.delete_outline),
                color: c.danger,
                tooltip: l.adminDeleteItemTypeTooltip,
              ),
            ],
          ),
          if (metaError != null) ...[
            SizedBox(height: spacing.sm),
            Text(metaError!, style: text.bodySmall.copyWith(color: c.danger)),
          ],
        ],
      ),
    );
  }
}

class AdminProductPricingSection extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;
  final TextEditingController priceCtrl;
  final TextEditingController stockCtrl;
  final bool loadingCurrency;
  final String? currencyLabel;

  const AdminProductPricingSection({
    super.key,
    required this.tokens,
    required this.l,
    required this.priceCtrl,
    required this.stockCtrl,
    required this.loadingCurrency,
    required this.currencyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = tokens.spacing;
    final text = tokens.typography;
    final c = tokens.colors;

    return AdminFormSectionCard(
      tokens: tokens,
      title: l.adminProductSectionPricingTitle,
      subtitle: l.adminProductSectionPricingSubtitle,
      icon: Icons.sell_outlined,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l.adminProductPriceLabel, style: text.titleMedium),
                    const SizedBox(width: 6),
                    if (loadingCurrency)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (currencyLabel != null)
                      Text(
                        ' ($currencyLabel)',
                        style: text.bodySmall.copyWith(
                          color: c.muted.withOpacity(0.8),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: spacing.xs),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(hintText: l.adminPriceExampleHint),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return l.adminProductPriceRequired;
                    }
                    final value = double.tryParse(v.trim());
                    if (value == null || value <= 0) {
                      return l.adminProductPriceInvalid;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.adminProductStockLabel, style: text.titleMedium),
                SizedBox(height: spacing.xs),
                TextFormField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(hintText: l.adminStockHint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminProductImageSection extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;
  final XFile? pickedImage;
  final String? existingImageUrl;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const AdminProductImageSection({
    super.key,
    required this.tokens,
    required this.l,
    required this.pickedImage,
    required this.existingImageUrl,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  Widget build(BuildContext context) {
    final c = tokens.colors;
    final spacing = tokens.spacing;

    Widget placeholderImage() => Padding(
          padding: const EdgeInsets.all(16),
          child: Image.asset(
            'assets/branding/product_placeholder.png',
            fit: BoxFit.contain,
          ),
        );

    return AdminFormSectionCard(
      tokens: tokens,
      title: l.adminProductImageSectionTitle,
      subtitle: l.adminProductImageSectionSubtitle,
      icon: Icons.image_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(tokens.card.radius),
              border: Border.all(color: c.border.withOpacity(0.4)),
            ),
            child: pickedImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(tokens.card.radius),
                    child: Image.file(
                      File(pickedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                : existingImageUrl != null && existingImageUrl!.trim().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(tokens.card.radius),
                        child: Image.network(
                          existingImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Center(child: placeholderImage()),
                        ),
                      )
                    : Center(child: placeholderImage()),
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.upload),
                label: Text(l.adminProductPickImage),
              ),
              SizedBox(width: spacing.sm),
              if (pickedImage != null)
                TextButton.icon(
                  onPressed: onRemoveImage,
                  icon: const Icon(Icons.close),
                  label: Text(l.adminRemove),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminProductConfigSection extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;

  final TextEditingController skuCtrl;

  final ProductTypeDto selectedProductType;
  final ValueChanged<ProductTypeDto> onProductTypeChanged;

  final bool virtualProduct;
  final ValueChanged<bool> onVirtualChanged;

  final bool downloadable;
  final ValueChanged<bool> onDownloadableChanged;

  final TextEditingController downloadUrlCtrl;
  final TextEditingController externalUrlCtrl;
  final TextEditingController buttonTextCtrl;

  const AdminProductConfigSection({
    super.key,
    required this.tokens,
    required this.l,
    required this.skuCtrl,
    required this.selectedProductType,
    required this.onProductTypeChanged,
    required this.virtualProduct,
    required this.onVirtualChanged,
    required this.downloadable,
    required this.onDownloadableChanged,
    required this.downloadUrlCtrl,
    required this.externalUrlCtrl,
    required this.buttonTextCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return AdminFormSectionCard(
      tokens: tokens,
      title: l.adminProductSectionConfigTitle,
      subtitle: l.adminProductSectionConfigSubtitle,
      icon: Icons.settings_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.adminProductSkuLabel, style: text.titleMedium),
          SizedBox(height: spacing.xs),
          TextFormField(
            controller: skuCtrl,
            decoration: InputDecoration(hintText: l.adminProductSkuHint),
          ),
          SizedBox(height: spacing.md),
          Text(l.adminProductTypeLabel, style: text.titleMedium),
          SizedBox(height: spacing.xs),
          DropdownButtonFormField<ProductTypeDto>(
            value: selectedProductType,
            items: [
              DropdownMenuItem(
                value: ProductTypeDto.simple,
                child: Text(l.adminProductTypeSimple),
              ),
              DropdownMenuItem(
                value: ProductTypeDto.variable,
                child: Text(l.adminProductTypeVariable),
              ),
              DropdownMenuItem(
                value: ProductTypeDto.grouped,
                child: Text(l.adminProductTypeGrouped),
              ),
              DropdownMenuItem(
                value: ProductTypeDto.external,
                child: Text(l.adminProductTypeExternal),
              ),
            ],
            onChanged: (val) {
              if (val != null) onProductTypeChanged(val);
            },
          ),
          SizedBox(height: spacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.adminProductVirtualLabel),
            value: virtualProduct,
            onChanged: onVirtualChanged,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.adminProductDownloadableLabel),
            value: downloadable,
            onChanged: onDownloadableChanged,
          ),
          if (downloadable) ...[
            SizedBox(height: spacing.xs),
            Text(
              l.adminDownloadableRulesHint,
              style: text.bodySmall.copyWith(color: tokens.colors.muted),
            ),
            SizedBox(height: spacing.sm),
            TextFormField(
              controller: downloadUrlCtrl,
              decoration: InputDecoration(
                hintText: l.adminProductDownloadUrlHint,
              ),
            ),
          ],
          if (selectedProductType == ProductTypeDto.external) ...[
            SizedBox(height: spacing.md),
            TextFormField(
              controller: externalUrlCtrl,
              decoration: InputDecoration(
                hintText: l.adminProductExternalUrlHint,
              ),
            ),
            SizedBox(height: spacing.sm),
            TextFormField(
              controller: buttonTextCtrl,
              decoration: InputDecoration(
                hintText: l.adminProductButtonTextHint,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class AdminProductSaleSection extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;
  final TextEditingController salePriceCtrl;
  final TextEditingController saleStartCtrl;
  final TextEditingController saleEndCtrl;
  final VoidCallback onPickSaleStart;
  final VoidCallback onPickSaleEnd;

  const AdminProductSaleSection({
    super.key,
    required this.tokens,
    required this.l,
    required this.salePriceCtrl,
    required this.saleStartCtrl,
    required this.saleEndCtrl,
    required this.onPickSaleStart,
    required this.onPickSaleEnd,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = tokens.spacing;
    final text = tokens.typography;

    return AdminFormSectionCard(
      tokens: tokens,
      title: l.adminProductSectionSaleTitle,
      subtitle: l.adminProductSectionSaleSubtitle,
      icon: Icons.local_offer_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.adminProductSalePriceLabel, style: text.titleMedium),
          SizedBox(height: spacing.xs),
          TextFormField(
            controller: salePriceCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: l.adminProductSalePriceHint,
            ),
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: saleStartCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: l.adminProductSaleStartHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: onPickSaleStart,
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing.sm),
              Expanded(
                child: TextFormField(
                  controller: saleEndCtrl,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: l.adminProductSaleEndHint,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_today_outlined),
                      onPressed: onPickSaleEnd,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminProductAttributesSection extends StatelessWidget {
  final dynamic tokens;
  final AppLocalizations l;
  final List<_AttributeRow> attributes;
  final List<String> allowedAttributeCodes;
  final VoidCallback onAddAttribute;
  final void Function(int index) onRemoveAttribute;
  final List<String> Function(int index) availableCodesForRow;

  const AdminProductAttributesSection({
    super.key,
    required this.tokens,
    required this.l,
    required this.attributes,
    required this.allowedAttributeCodes,
    required this.onAddAttribute,
    required this.onRemoveAttribute,
    required this.availableCodesForRow,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = tokens.spacing;
    final c = tokens.colors;
    final text = tokens.typography;

    return AdminFormSectionCard(
      tokens: tokens,
      title: l.adminProductAttributesTitle,
      subtitle: l.adminProductAttributesSubtitle,
      icon: Icons.tune_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (attributes.isEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Text(
                l.adminProductNoAttributesHint,
                style: text.bodySmall.copyWith(color: c.muted),
              ),
            ),
          ...attributes.asMap().entries.map((entry) {
            final index = entry.key;
            final row = entry.value;

            final availableCodes = availableCodesForRow(index);
            if (availableCodes.isEmpty) {
              return const SizedBox.shrink();
            }

            row.selectedCode ??= availableCodes.first;
            if (!availableCodes.contains(row.selectedCode)) {
              row.selectedCode = availableCodes.first;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: spacing.sm,
                        vertical: spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(tokens.card.radius),
                        border: Border.all(color: c.border.withOpacity(0.4)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: StatefulBuilder(
                          builder: (ctx, setLocalState) {
                            return DropdownButton<String>(
                              value: row.selectedCode,
                              isExpanded: true,
                              items: availableCodes
                                  .map(
                                    (code) => DropdownMenuItem(
                                      value: code,
                                      child: Text(code),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                setLocalState(() => row.selectedCode = val);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: row.valueCtrl,
                      decoration: InputDecoration(
                        labelText: l.adminProductAttributeValueLabel,
                        hintText: l.adminProductAttributeValueHint,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemoveAttribute(index),
                    icon: Icon(Icons.delete, color: c.danger),
                  ),
                ],
              ),
            );
          }).toList(),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAddAttribute,
              icon: const Icon(Icons.add),
              label: Text(l.adminProductAddAttribute),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttributeRow {
  String? selectedCode;
  final TextEditingController valueCtrl = TextEditingController();

  _AttributeRow({this.selectedCode});

  void dispose() => valueCtrl.dispose();
}

class _CategoryOption {
  final int id;
  final String name;

  _CategoryOption({required this.id, required this.name});

  factory _CategoryOption.fromJson(Map<String, dynamic> j) {
    final raw = j['id'];
    final id = raw is int ? raw : int.tryParse('$raw') ?? 0;
    return _CategoryOption(
      id: id,
      name: (j['name'] ?? '').toString(),
    );
  }
}