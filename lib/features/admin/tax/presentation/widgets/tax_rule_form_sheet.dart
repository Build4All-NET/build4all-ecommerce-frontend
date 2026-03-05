import 'dart:async';

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

import '../../domain/entities/tax_rule.dart';

class TaxRuleFormSheet extends StatefulWidget {
  final int ownerProjectId;
  final TaxRule? initial;

  const TaxRuleFormSheet({
    super.key,
    required this.ownerProjectId,
    this.initial,
  });

  @override
  State<TaxRuleFormSheet> createState() => _TaxRuleFormSheetState();
}

class _TaxRuleFormSheetState extends State<TaxRuleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _store = AdminTokenStore();
  final _catalogApi = CatalogApiService();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _rateCtrl;

  bool _appliesToShipping = false;
  bool _enabled = true;

  bool _loadingCatalog = true;
  String? _catalogError;

  List<CountryModel> _countries = [];
  List<RegionModel> _allRegions = [];

  CountryModel? _selectedCountry;
  RegionModel? _selectedRegion;

  bool get _isEdit => widget.initial != null;

  // -------------------------------
  // Rule name presets
  // -------------------------------
  static const String _customRuleKey = '__CUSTOM__';

  final List<_RulePreset> _presets = const [
    _RulePreset(key: 'VAT_11', name: 'VAT 11%', rate: 11.0),
    _RulePreset(key: 'VAT_5', name: 'VAT 5%', rate: 5.0),
    
  ];

  String _selectedPresetKey = _customRuleKey;

  // -------------------------------
  // Auto-sync name <-> rate
  // -------------------------------
  bool _lockNameToRate = true;
  bool _updatingName = false;
  bool _updatingRate = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _rateCtrl = TextEditingController(
      text: p != null ? p.rate.toStringAsFixed(2) : '',
    );

    _appliesToShipping = p?.appliesToShipping ?? false;
    _enabled = p?.enabled ?? true;

    _selectedPresetKey = _matchPresetKey(p?.name, p?.rate);

    _lockNameToRate = true;
    _rateCtrl.addListener(_onRateTyped);

    _bootstrapCatalog(
      initialCountryId: p?.countryId,
      initialRegionId: p?.regionId,
    );
  }

  @override
  void dispose() {
    _rateCtrl.removeListener(_onRateTyped);
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  // ✅ DEFAULT Lebanon helper
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

  String _matchPresetKey(String? name, double? rate) {
    if (rate != null) {
      final byRate = _presetByRate(rate);
      if (byRate != null) return byRate.key;
    }
    if (name != null && name.trim().isNotEmpty) {
      final lower = name.trim().toLowerCase();
      for (final p in _presets) {
        if (p.name.toLowerCase() == lower) return p.key;
      }
    }
    return _customRuleKey;
  }

  _RulePreset? _presetByRate(double rate) {
    for (final p in _presets) {
      if ((p.rate - rate).abs() < 0.0001) return p;
    }
    return null;
  }

  void _onRateTyped() {
    if (_updatingRate) return;

    final v = double.tryParse(_rateCtrl.text.trim().replaceAll(',', '.'));
    if (v == null) return;

    if (_lockNameToRate && !_updatingName) {
      _updatingName = true;
      _nameCtrl.text = _nameFromRate(v);
      _updatingName = false;
    }

    final preset = _presetByRate(v);
    final newKey = preset?.key ?? _customRuleKey;

    if (newKey != _selectedPresetKey) {
      setState(() => _selectedPresetKey = newKey);
    }
  }

  String _nameFromRate(double rate) {
    final clean = _prettyRate(rate);
    return 'VAT $clean%';
  }

  String _prettyRate(double v) {
    final rounded = (v * 100).round() / 100;
    if ((rounded - rounded.roundToDouble()).abs() < 0.0001) {
      return rounded.toInt().toString();
    }
    return rounded
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _onPresetChanged(String? key) {
    final k = key ?? _customRuleKey;

    setState(() {
      _selectedPresetKey = k;
      _lockNameToRate = true;
    });

    final preset = _presets.where((p) => p.key == k).firstOrNull;
    if (preset != null) {
      _updatingRate = true;
      _rateCtrl.text = preset.rate.toStringAsFixed(2);
      _updatingRate = false;

      _updatingName = true;
      _nameCtrl.text = preset.name;
      _updatingName = false;
    }
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

      // ✅ DEFAULT Lebanon if creating (no initial saved)
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
        _catalogError = e.toString();
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

  Map<String, dynamic> _buildBody() {
    final rate =
        double.tryParse(_rateCtrl.text.trim().replaceAll(',', '.')) ?? 0;

    return {
      'ownerProjectId': widget.ownerProjectId,
      'name': _nameCtrl.text.trim(),
      'rate': rate,
      'appliesToShipping': _appliesToShipping,
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
        l.adminTaxCountryRequired ?? 'Country is required',
        
      );
      return;
    }

    Navigator.pop(context, _buildBody());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;
    final l = AppLocalizations.of(context)!;

    final title = _isEdit
        ? (l.adminTaxEditRuleTitle ?? 'Edit tax rule')
        : (l.adminTaxCreateRuleTitle ?? 'Create tax rule');

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

                      // Presets
                      Text(
                        l.adminTaxRulePresetLabel ?? 'Rule template',
                        style: text.titleMedium,
                      ),
                      SizedBox(height: spacing.xs),
                      DropdownButtonFormField<String>(
                        value: _selectedPresetKey,
                        decoration: InputDecoration(
                          hintText:
                              l.adminTaxRulePresetHint ?? 'Select a template',
                        ),
                        items: [
                          ..._presets.map(
                            (p) => DropdownMenuItem(
                              value: p.key,
                              child: Text(p.name),
                            ),
                          ),
                          DropdownMenuItem(
                            value: _customRuleKey,
                            child: Text(l.adminCustom ?? 'Custom'),
                          ),
                        ],
                        onChanged: _onPresetChanged,
                      ),
                      SizedBox(height: spacing.md),

                      AppTextField(
                        label: l.adminTaxRuleNameLabel ?? 'Rule name',
                        controller: _nameCtrl,
                        keyboardType: TextInputType.text,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? (l.adminTaxRuleNameRequired ??
                                  'Rule name is required')
                            : null,
                      ),
                      SizedBox(height: spacing.sm),

                      _InlineSwitch(
                        value: _lockNameToRate,
                        label: l.adminTaxAutoNameLabel ?? 'Auto-name from rate',
                        onChanged: (v) {
                          setState(() => _lockNameToRate = v);
                          final rate = double.tryParse(
                            _rateCtrl.text.trim().replaceAll(',', '.'),
                          );
                          if (v && rate != null) {
                            _updatingName = true;
                            _nameCtrl.text = _nameFromRate(rate);
                            _updatingName = false;
                          }
                        },
                      ),
                      SizedBox(height: spacing.md),

                      AppTextField(
                        label: l.adminTaxRuleRateLabel ?? 'Rate (%)',
                        controller: _rateCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return l.adminTaxRuleRateRequired ??
                                'Rate is required';
                          }
                          final d = double.tryParse(
                            v.trim().replaceAll(',', '.'),
                          );
                          if (d == null || d < 0) {
                            return l.adminTaxRuleRateInvalid ?? 'Invalid rate';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: spacing.lg),

                      // Country/Region
                      Text(
                        l.adminTaxCountryLabel ?? 'Country',
                        style: text.titleMedium,
                      ),
                      SizedBox(height: spacing.xs),
                      _SearchablePicker<CountryModel>(
                        items: _countries,
                        value: _selectedCountry,
                        label: (x) => '${x.name} (${x.iso2Code})',
                        hintText: l.adminTaxCountryHint ?? 'Select country',
                        onChanged: _onCountryChanged,
                      ),
                      SizedBox(height: spacing.md),

                      Text(
                        l.adminTaxRegionLabel ?? 'Region',
                        style: text.titleMedium,
                      ),
                      SizedBox(height: spacing.xs),
                      _SearchablePicker<RegionModel>(
                        items: _filteredRegions,
                        value: _selectedRegion,
                        enabled: _selectedCountry != null,
                        label: (x) => x.name,
                        hintText: _selectedCountry == null
                            ? (l.adminTaxSelectCountryFirst ??
                                  'Select country first')
                            : (l.adminTaxRegionHint ??
                                  'Select region (optional)'),
                        onChanged: (r) => setState(() => _selectedRegion = r),
                      ),
                      SizedBox(height: spacing.lg),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          l.adminTaxAppliesToShippingLabel ??
                              'Applies to shipping',
                        ),
                        value: _appliesToShipping,
                        onChanged: (v) =>
                            setState(() => _appliesToShipping = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l.adminTaxEnabledLabel ?? 'Enabled'),
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                      SizedBox(height: spacing.lg),

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

/* =========================================================
   Inline switch
   ========================================================= */

class _InlineSwitch extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  const _InlineSwitch({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final text = tokens.typography;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: text.bodyMedium.copyWith(color: c.muted)),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/* =========================================================
   Error UI
   ========================================================= */

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
                child: const Text('Cancel'),
              ),
            ),
            SizedBox(width: spacing.sm),
            Expanded(
              child: PrimaryButton(label: 'Retry', onPressed: onRetry),
            ),
          ],
        ),
      ],
    );
  }
}

/* =========================================================
   Searchable picker (SAFE bottom sheet)
   ========================================================= */

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
      final next = q.isEmpty
          ? widget.items
          : widget.items
                .where((i) => widget.label(i).toLowerCase().contains(q))
                .toList();
      setState(() => _filtered = next);
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
    final l10n = AppLocalizations.of(context)!;

    // ✅ read not watch to prevent semantics crash during keyboard animations
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
                  hintText: l10n.searchLabel,
                  controller: _searchCtrl,
                ),
              ),

              SizedBox(height: spacing.md),

              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noResultsLabel,
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

/* =========================================================
   Preset model
   ========================================================= */

class _RulePreset {
  final String key;
  final String name;
  final double rate;

  const _RulePreset({
    required this.key,
    required this.name,
    required this.rate,
  });
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
