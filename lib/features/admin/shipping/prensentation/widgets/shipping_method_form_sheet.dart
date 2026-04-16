import 'dart:async';

import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';

import 'package:build4front/features/catalog/data/models/country_model.dart';
import 'package:build4front/features/catalog/data/models/region_model.dart';
import 'package:build4front/features/catalog/data/services/catalog_api_service.dart';

import 'package:build4front/common/widgets/app_text_field.dart';
import 'package:build4front/common/widgets/app_search_field.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/primary_button.dart';

import '../../domain/entities/shipping_method.dart';
import '../utils/shipping_method_type_ui.dart';

class ShippingMethodFormSheet extends StatefulWidget {
  final int ownerProjectId;
  final ShippingMethod? initial;

  const ShippingMethodFormSheet({
    super.key,
    required this.ownerProjectId,
    this.initial,
  });

  @override
  State<ShippingMethodFormSheet> createState() =>
      _ShippingMethodFormSheetState();
}

class _ShippingMethodFormSheetState extends State<ShippingMethodFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _store = AdminTokenStore();
  final _catalogApi = CatalogApiService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _flatCtrl;
  late final TextEditingController _perKgCtrl;
  late final TextEditingController _thresholdCtrl;

  bool _enabled = true;

  bool _loadingCatalog = true;
  String? _catalogError;

  List<CountryModel> _countries = [];
  List<RegionModel> _allRegions = [];
  CountryModel? _selectedCountry;
  RegionModel? _selectedRegion;

  ShippingMethodTypeUi? _type;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');

    _flatCtrl = TextEditingController(
      text: p != null ? p.flatRate.toStringAsFixed(2) : '',
    );
    _perKgCtrl = TextEditingController(
      text: p != null ? p.pricePerKg.toStringAsFixed(2) : '',
    );
    _thresholdCtrl = TextEditingController(
      text: p?.freeShippingThreshold != null
          ? p!.freeShippingThreshold!.toStringAsFixed(2)
          : '',
    );

    _enabled = p?.enabled ?? true;
    _type =
        ShippingMethodTypeUi.fromApi(p?.methodType) ??
        ShippingMethodTypeUi.flatRate;

    _bootstrapCatalog(
      initialCountryId: p?.countryId,
      initialRegionId: p?.regionId,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _flatCtrl.dispose();
    _perKgCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  CountryModel? _findLebanon(List<CountryModel> countries) {
    final byIso = countries.where(
      (c) => c.iso2Code.trim().toUpperCase() == 'LB',
    );
    if (byIso.isNotEmpty) return byIso.first;

    final byName = countries.where(
      (c) => c.name.trim().toLowerCase().contains('lebanon'),
    );
    if (byName.isNotEmpty) return byName.first;

    return null;
  }

  Future<void> _bootstrapCatalog({
    int? initialCountryId,
    int? initialRegionId,
  }) async {
    final token = await _store.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      setState(() {
        _loadingCatalog = false;
        _catalogError = 'Missing admin token';
      });
      return;
    }

    try {
      final countries = await _catalogApi.listCountries(authToken: token);
      final regions = await _catalogApi.listRegions(authToken: token);

      CountryModel? initCountry;
      RegionModel? initRegion;

      if (initialCountryId != null) {
        initCountry = countries
            .where((c) => c.id == initialCountryId)
            .firstOrNull;
      }
      if (initialRegionId != null) {
        initRegion = regions.where((r) => r.id == initialRegionId).firstOrNull;
      }
      if (initCountry == null && initRegion != null) {
        initCountry = countries
            .where((c) => c.id == initRegion!.countryId)
            .firstOrNull;
      }

      // ✅ DEFAULT Lebanon on create
      initCountry ??= _findLebanon(countries);

      setState(() {
        _countries = countries;
        _allRegions = regions;
        _selectedCountry = initCountry;
        _selectedRegion = initRegion;
        _loadingCatalog = false;
        _catalogError = null;
      });
        } catch (e) {
      setState(() {
        _loadingCatalog = false;
        _catalogError = ExceptionMapper.toMessage(e);
      });
    }
  }

  List<RegionModel> get _filteredRegions {
    final c = _selectedCountry;
    if (c == null) return [];
    return _allRegions.where((r) => r.countryId == c.id).toList();
  }

  void _onCountryChanged(CountryModel? c) {
    setState(() {
      _selectedCountry = c;
      _selectedRegion = null;
    });
  }

  double _parseD(String v) =>
      double.tryParse(v.trim().replaceAll(',', '.')) ?? 0;

  Map<String, dynamic> _buildBody() {
    final flat = _parseD(_flatCtrl.text);
    final perKg = _parseD(_perKgCtrl.text);
    final thresholdText = _thresholdCtrl.text.trim();
    final threshold = thresholdText.isEmpty ? null : _parseD(thresholdText);

    return {
      'ownerProjectId': widget.ownerProjectId,
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'methodType': (_type ?? ShippingMethodTypeUi.flatRate).apiName,
      'flatRate': flat,
      'pricePerKg': perKg,
      'freeShippingThreshold': threshold,
      'enabled': _enabled,
      if (_selectedCountry != null) 'countryId': _selectedCountry!.id,
      if (_selectedRegion != null) 'regionId': _selectedRegion!.id,
    };
  }

  void _submit(AppLocalizations l) {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCountry == null) {
      AppToast.error(
        context,
        l.adminShippingCountryRequired ?? 'Country is required',
        
      );
      return;
    }

    Navigator.pop(context, _buildBody());
  }

  bool get _showFlat =>
      _type == ShippingMethodTypeUi.flatRate ||
      _type == ShippingMethodTypeUi.priceBased ||
      _type == ShippingMethodTypeUi.freeOverThreshold;

  bool get _showPerKg =>
      _type == ShippingMethodTypeUi.weightBased ||
      _type == ShippingMethodTypeUi.pricePerKg ||
      _type == ShippingMethodTypeUi.freeOverThreshold;

  bool get _showThreshold => _type == ShippingMethodTypeUi.freeOverThreshold;

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;
    final l = AppLocalizations.of(context)!;
    

    final title = _isEdit
        ? (l.adminShippingEditTitle ?? 'Edit shipping method')
        : (l.adminShippingCreateTitle ?? 'Create shipping method');

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: spacing.lg,
          right: spacing.lg,
          top: spacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + spacing.lg,
        ),
        child: _loadingCatalog
            ? SizedBox(
                height: 240,
                child: Center(
                  child: CircularProgressIndicator(color: c.primary),
                ),
              )
            : _catalogError != null
            ? _ErrorState(
                title: title,
                error: _catalogError!,
                onCancel: () => Navigator.pop(context),
                onRetry: () {
                  setState(() {
                    _loadingCatalog = true;
                    _catalogError = null;
                  });
                  _bootstrapCatalog(
                    initialCountryId: widget.initial?.countryId,
                    initialRegionId: widget.initial?.regionId,
                  );
                },
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium.copyWith(color: c.label),
                      ),
                      SizedBox(height: spacing.md),

                      AppTextField(
                        label: l.adminShippingNameLabel ?? 'Name',
                        controller: _nameCtrl,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? (l.adminShippingNameRequired ??
                                  'Name is required')
                            : null,
                      ),
                      SizedBox(height: spacing.sm),

                      AppTextField(
                        label: l.adminShippingDescLabel ?? 'Description',
                        controller: _descCtrl,
                      ),
                      SizedBox(height: spacing.md),

                      Text(
                        l.adminShippingTypeLabel ?? 'Method type',
                        style: text.titleMedium,
                      ),
                      SizedBox(height: spacing.xs),
                      DropdownButtonFormField<ShippingMethodTypeUi>(
                        value: _type,
                        decoration: InputDecoration(
                          hintText: l.adminShippingTypeHint ?? 'Select type',
                        ),
                        items: ShippingMethodTypeUi.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(e.label(l)),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      SizedBox(height: spacing.md),

                      if (_showFlat) ...[
                        AppTextField(
                          label: l.adminShippingFlatRateLabel ?? 'Flat rate',
                          controller: _flatCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                      ],

                      if (_showPerKg) ...[
                        AppTextField(
                          label: l.adminShippingPerKgLabel ?? 'Price per kg',
                          controller: _perKgCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                      ],

                      if (_showThreshold) ...[
                        AppTextField(
                          label:
                              l.adminShippingThresholdLabel ??
                              'Free over threshold',
                          controller: _thresholdCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                      ],

                      SizedBox(height: spacing.md),

                      Text(
                        l.adminShippingCountryLabel ?? 'Country',
                        style: text.titleMedium,
                      ),
                      SizedBox(height: spacing.xs),
                      _SearchablePicker<CountryModel>(
                        items: _countries,
                        value: _selectedCountry,
                        label: (x) => '${x.name} (${x.iso2Code})',
                        hintText:
                            l.adminShippingCountryHint ?? 'Select country',
                        onChanged: _onCountryChanged,
                      ),
                      SizedBox(height: spacing.md),

                      Text(
                        l.adminShippingRegionLabel ?? 'Region',
                        style: text.titleMedium,
                      ),
                      SizedBox(height: spacing.xs),
                      _SearchablePicker<RegionModel>(
                        items: _filteredRegions,
                        value: _selectedRegion,
                        enabled: _selectedCountry != null,
                        label: (x) => x.name,
                        hintText: _selectedCountry == null
                            ? (l.adminShippingSelectCountryFirst ??
                                  'Select country first')
                            : (l.adminShippingRegionHint ??
                                  'Select region (optional)'),
                        onChanged: (r) => setState(() => _selectedRegion = r),
                      ),
                      SizedBox(height: spacing.md),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.adminShippingEnabledLabel ?? 'Enabled'),
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),

                      SizedBox(height: spacing.lg),

                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(l.adminCancel ?? l.commonCancel),
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

/* ================= Error UI ================= */

class _ErrorState extends StatelessWidget {
  final String title;
  final String error;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.title,
    required this.error,
    required this.onCancel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;
    final l = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: text.titleMedium.copyWith(color: c.label)),
        SizedBox(height: spacing.md),
        Text(error, style: text.bodyMedium.copyWith(color: c.danger)),
        SizedBox(height: spacing.lg),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                child: Text(l.commonCancel),
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: PrimaryButton(label: l.commonRetry, onPressed: onRetry),
            ),
          ],
        ),
      ],
    );
  }
}

/* ================= Searchable Picker (SAFE) ================= */

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
    final l = AppLocalizations.of(context)!;
    final spacing = tokens.spacing;

    final disabled = !enabled || items.isEmpty;

    return InkWell(
      onTap: disabled
          ? null
          : () async {
              final picked = await showModalBottomSheet<T>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
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
                    ? 'No options'
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
  Timer? _debounce;
  late List<T> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      final q = _searchCtrl.text.trim().toLowerCase();
      setState(() {
        _filtered = q.isEmpty
            ? widget.items
            : widget.items
                  .where((i) => widget.label(i).toLowerCase().contains(q))
                  .toList();
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    // ✅ read not watch (no rebuild storms with keyboard)
    final tokens = context.read<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;
    

    final radius = tokens.card.radius;
    final height = MediaQuery.of(context).size.height * 0.88;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          ),
          child: Column(
            children: [
              SizedBox(height: spacing.sm),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: c.border.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              SizedBox(height: spacing.md),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: Text(
                  widget.title,
                  style: text.titleMedium.copyWith(
                    color: c.label,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              SizedBox(height: spacing.md),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.lg),
                child: AppSearchField(
                  hintText: l.searchLabel,
                  controller: _searchCtrl,
                ),
              ),

              SizedBox(height: spacing.md),

              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l.noResultsLabel,
                          style: text.bodyMedium.copyWith(color: c.muted),
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          color: c.border.withOpacity(0.12),
                          height: 1,
                        ),
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
      ),
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
