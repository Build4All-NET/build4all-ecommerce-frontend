import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/common/widgets/app_text_field.dart';
import 'package:build4front/common/widgets/app_search_field.dart';

import 'package:build4front/features/catalog/data/models/country_model.dart';
import 'package:build4front/features/catalog/data/models/region_model.dart';
import 'package:build4front/features/catalog/data/services/catalog_api_service.dart';
import 'package:build4front/features/auth/data/services/auth_token_store.dart';
import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';

class CheckoutAddressForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool showPickerErrors;

  final ShippingAddress initial;
  final ValueChanged<ShippingAddress> onApply;

  const CheckoutAddressForm({
    super.key,
    required this.formKey,
    required this.showPickerErrors,
    required this.initial,
    required this.onApply,
  });

  @override
  State<CheckoutAddressForm> createState() => _CheckoutAddressFormState();
}

class _CheckoutAddressFormState extends State<CheckoutAddressForm> {
  final _catalogApi = CatalogApiService();
  final _tokenStore = AuthTokenStore();

  bool _loadingCatalog = true;
  String? _catalogError;

  List<CountryModel> _countries = [];
  List<RegionModel> _allRegions = [];

  CountryModel? _selectedCountry;
  RegionModel? _selectedRegion;

  late final TextEditingController _cityCtrl;
  late final TextEditingController _postalCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _notesCtrl;

  // ✅ Focus nodes
  late final FocusNode _nameFocus;
  late final FocusNode _notesFocus;
  late final FocusNode _phoneFocus;

  // ✅ Phone state
  String _phoneInitialValue = ''; // original raw stored value
  String _phoneDisplayValue = ''; // local digits shown in IntlPhoneField
  String? _fullPhone; // full international e.g. +96170123456
  String _phoneLocalDigits = ''; // local digits only (e.g. 70123456)

  Timer? _debounce;
  bool _prefillAppliedOnce = false;

  // ✅ Prevent duplicate onApply calls
  String? _lastSentSignature;

  @override
  void initState() {
    super.initState();

    _cityCtrl = TextEditingController(text: widget.initial.city ?? '');
    _postalCtrl = TextEditingController(text: widget.initial.postalCode ?? '');
    _addressCtrl = TextEditingController(text: widget.initial.addressLine ?? '');
    _nameCtrl = TextEditingController(text: widget.initial.fullName ?? '');
    _notesCtrl = TextEditingController(text: widget.initial.notes ?? '');

    _nameFocus = FocusNode();
    _notesFocus = FocusNode();
    _phoneFocus = FocusNode();

    _nameFocus.addListener(() {
      if (!_nameFocus.hasFocus) _notifyParent();
    });

    _notesFocus.addListener(() {
      if (!_notesFocus.hasFocus) _notifyParent();
    });

    // ✅ Only sync phone to parent when user leaves the field
    _phoneFocus.addListener(() {
      if (!_phoneFocus.hasFocus) _notifyParent();
    });

    _setInitialPhoneFrom(widget.initial.phone);

    // ✅ Only pricing-relevant text fields debounce notify
    _cityCtrl.addListener(_debouncedNotify);
    _postalCtrl.addListener(_debouncedNotify);
    _addressCtrl.addListener(_debouncedNotify);

    _bootstrapCatalog(
      initialCountryId: widget.initial.countryId,
      initialRegionId: widget.initial.regionId,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();

    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _addressCtrl.dispose();
    _nameCtrl.dispose();
    _notesCtrl.dispose();

    _nameFocus.dispose();
    _notesFocus.dispose();
    _phoneFocus.dispose();

    super.dispose();
  }

  void _debouncedNotify() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _notifyParent);
  }

  String? _emptyToNull(String? s) {
    final v = (s ?? '').trim();
    return v.isEmpty ? null : v;
  }

  void _setInitialPhoneFrom(String? phone) {
    _phoneInitialValue = (phone ?? '').trim();
    _fullPhone = _emptyToNull(_phoneInitialValue);

    final digits = _phoneInitialValue.replaceAll(RegExp(r'\D'), '');
    _phoneLocalDigits =
        digits.length > 8 ? digits.substring(digits.length - 8) : digits;

    // ✅ IntlPhoneField.initialValue should be local number only
    _phoneDisplayValue = _phoneLocalDigits;
  }

  ShippingAddress _buildAddress() {
    return ShippingAddress(
      countryId: _selectedCountry?.id,
      regionId: _selectedRegion?.id,
      city: _emptyToNull(_cityCtrl.text),
      postalCode: _emptyToNull(_postalCtrl.text),
      addressLine: _emptyToNull(_addressCtrl.text),
      phone: _emptyToNull(_fullPhone),
      fullName: _emptyToNull(_nameCtrl.text),
      notes: _emptyToNull(_notesCtrl.text),
    );
  }

  String _signatureOf(ShippingAddress a) {
    return [
      a.countryId?.toString() ?? '',
      a.regionId?.toString() ?? '',
      a.city ?? '',
      a.postalCode ?? '',
      a.addressLine ?? '',
      a.phone ?? '',
      a.fullName ?? '',
      a.notes ?? '',
    ].join('|');
  }

  void _notifyParent() {
    final address = _buildAddress();
    final sig = _signatureOf(address);

    if (sig == _lastSentSignature) return;
    _lastSentSignature = sig;

    widget.onApply(address);
  }

  void _applyIfNotNull(TextEditingController ctrl, String? incoming) {
    if (incoming == null) return;
    final v = incoming.trim();
    if (v == ctrl.text) return;

    ctrl.value = ctrl.value.copyWith(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
      composing: TextRange.empty,
    );
  }

  CountryModel? _findLebanon(List<CountryModel> countries) {
    return countries
            .where((c) => c.iso2Code.toUpperCase() == 'LB')
            .firstOrNull ??
        countries
            .where((c) => c.name.toLowerCase().trim() == 'lebanon')
            .firstOrNull ??
        countries
            .where((c) => c.name.toLowerCase().contains('lebanon'))
            .firstOrNull;
  }

  void _applyInitialToUi(ShippingAddress s) {
    if (_prefillAppliedOnce) return;

    _applyIfNotNull(_cityCtrl, s.city);
    _applyIfNotNull(_postalCtrl, s.postalCode);
    _applyIfNotNull(_addressCtrl, s.addressLine);
    _applyIfNotNull(_nameCtrl, s.fullName);
    _applyIfNotNull(_notesCtrl, s.notes);

    _setInitialPhoneFrom(s.phone);

    if (s.countryId != null && _countries.isNotEmpty) {
      final found = _countries.where((c) => c.id == s.countryId).firstOrNull;
      if (found != null) _selectedCountry = found;
    }

    if (s.regionId != null && _allRegions.isNotEmpty) {
      final found = _allRegions.where((r) => r.id == s.regionId).firstOrNull;
      if (found != null) {
        if (_selectedCountry == null || found.countryId == _selectedCountry!.id) {
          _selectedRegion = found;
        }
      }
    }

    _prefillAppliedOnce = true;
    _debouncedNotify();

    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant CheckoutAddressForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Ignore parent "echo" rebuilds if incoming == current local form data
    final incomingSig = _signatureOf(widget.initial);
    final localSig = _signatureOf(_buildAddress());
    if (incomingSig == localSig) return;

    // ✅ Ignore if parent didn't actually change anything meaningful
    final oldSig = _signatureOf(oldWidget.initial);
    if (incomingSig == oldSig) return;

    // ✅ Apply only true external updates (screen reload / backend prefill / etc.)
    _prefillAppliedOnce = false;

    if (!_loadingCatalog && _countries.isNotEmpty) {
      _applyInitialToUi(widget.initial);
    }
  }

  Future<void> _bootstrapCatalog({
    int? initialCountryId,
    int? initialRegionId,
  }) async {
    try {
      final token = await _tokenStore.getToken();
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      if (token == null || token.isEmpty) {
        setState(() {
          _loadingCatalog = false;
          _catalogError = l10n.missingUserToken;
        });
        return;
      }

      final countries = await _catalogApi.listCountries(authToken: token);
      final regions = await _catalogApi.listRegions(authToken: token);

      CountryModel? initCountry;
      RegionModel? initRegion;

      // 1) try saved IDs
      if (initialCountryId != null) {
        initCountry =
            countries.where((c) => c.id == initialCountryId).firstOrNull;
      }
      if (initialRegionId != null) {
        initRegion = regions.where((r) => r.id == initialRegionId).firstOrNull;
      }
      if (initCountry == null && initRegion != null) {
        initCountry =
            countries.where((c) => c.id == initRegion?.countryId).firstOrNull;
      }

      // 2) default to Lebanon
      initCountry ??= _findLebanon(countries);

      // 3) if region doesn't match country, reset
      if (initRegion != null && initCountry != null) {
        if (initRegion.countryId != initCountry.id) {
          initRegion = null;
        }
      }

      setState(() {
        _countries = countries;
        _allRegions = regions;
        _selectedCountry = initCountry;
        _selectedRegion = initRegion;
        _loadingCatalog = false;
        _catalogError = null;
      });

      _applyInitialToUi(widget.initial);
      _notifyParent();
    } catch (e) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final c = tokens.colors;
    final text = tokens.typography;

    if (_loadingCatalog) {
      return Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Center(child: CircularProgressIndicator(color: c.primary)),
      );
    }

    if (_catalogError != null) {
      return Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.checkoutAddressTitle,
              style: text.titleMedium.copyWith(color: c.label),
            ),
            SizedBox(height: spacing.sm),
            Text(
              _catalogError!,
              style: text.bodyMedium.copyWith(color: c.danger),
            ),
            SizedBox(height: spacing.sm),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _loadingCatalog = true;
                  _catalogError = null;
                });
                _bootstrapCatalog(
                  initialCountryId: widget.initial.countryId,
                  initialRegionId: widget.initial.regionId,
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final countryIso = (_selectedCountry?.iso2Code ?? 'LB').toUpperCase();

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.adminTaxCountryLabel),
          SizedBox(height: spacing.xs),
          _SearchablePicker<CountryModel>(
            items: _countries,
            value: _selectedCountry,
            label: (x) => '${x.name} (${x.iso2Code})',
            hintText: l10n.adminTaxSelectCountryFirst,
            onChanged: (picked) {
              setState(() {
                _selectedCountry = picked;
                _selectedRegion = null;
              });
              _notifyParent();
            },
          ),

          if (widget.showPickerErrors && _selectedCountry == null) ...[
            SizedBox(height: spacing.xs),
            Text(
              l10n.fieldRequired,
              style: text.bodySmall.copyWith(color: c.danger),
            ),
          ],

          SizedBox(height: spacing.md),
          Text(l10n.adminTaxRegionLabel),
          SizedBox(height: spacing.xs),
          _SearchablePicker<RegionModel>(
            items: _filteredRegions,
            value: _selectedRegion,
            enabled: _selectedCountry != null,
            label: (x) => x.name,
            hintText: l10n.adminTaxRegionLabel,
            onChanged: (picked) {
              setState(() => _selectedRegion = picked);
              _notifyParent();
            },
          ),

          if (widget.showPickerErrors && _selectedRegion == null) ...[
            SizedBox(height: spacing.xs),
            Text(
              l10n.fieldRequired,
              style: text.bodySmall.copyWith(color: c.danger),
            ),
          ],

          SizedBox(height: spacing.md),

          // ✅ Full name (optional)
          TextFormField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            keyboardType: TextInputType.name,
            onEditingComplete: () {
              _notifyParent();
              FocusScope.of(context).nextFocus();
            },
            onFieldSubmitted: (_) => _notifyParent(),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r"[A-Za-zÀ-ÿ\u0600-\u06FF\s'\-]"),
              ),
            ],
            decoration: InputDecoration(
              labelText: l10n.checkoutFullNameLabel,
              hintText: l10n.checkoutFullNameHint,
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.card.radius),
                borderSide: BorderSide(color: c.border.withOpacity(0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.card.radius),
                borderSide: BorderSide(color: c.border.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.card.radius),
                borderSide: BorderSide(color: c.primary, width: 1.4),
              ),
            ),
          ),

          SizedBox(height: spacing.sm),

          // ✅ Required
          AppTextField(
            label: l10n.checkoutAddressLineLabel,
            controller: _addressCtrl,
            hintText: l10n.checkoutAddressLineHint,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return l10n.fieldRequired;
              return null;
            },
          ),
          SizedBox(height: spacing.sm),

          // ✅ Required
          AppTextField(
            label: l10n.checkoutCityLabel,
            controller: _cityCtrl,
            hintText: l10n.checkoutCityHint,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return l10n.fieldRequired;
              return null;
            },
          ),
          SizedBox(height: spacing.sm),

          // ✅ Optional (force no validation in case AppTextField defaults to required)
          AppTextField(
            label: l10n.checkoutPostalCodeLabel,
            controller: _postalCtrl,
            hintText: l10n.checkoutPostalCodeHint,
            textInputAction: TextInputAction.next,
            validator: (_) => null,
          ),
          SizedBox(height: spacing.sm),

          // ✅ PHONE (fixed: no parent sync on every digit)
          IntlPhoneField(
            key: ValueKey(countryIso), // stable key; remount only when country changes
            focusNode: _phoneFocus,
            initialCountryCode: countryIso,
            initialValue: _phoneDisplayValue, // local digits only

            disableLengthCheck: true,

            autovalidateMode: widget.showPickerErrors
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,

            // If your package version doesn't support this property, remove it.
            invalidNumberMessage: '',

            decoration: InputDecoration(
              labelText: l10n.checkoutPhoneLabel,
              filled: true,
              fillColor: c.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.card.radius),
                borderSide: BorderSide(color: c.border.withOpacity(0.25)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.card.radius),
                borderSide: BorderSide(color: c.border.withOpacity(0.25)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(tokens.card.radius),
                borderSide: BorderSide(color: c.primary, width: 1.4),
              ),
            ),

            onChanged: (phone) {
              final localDigits = phone.number.replaceAll(RegExp(r'\D'), '');

              _phoneLocalDigits = localDigits;
              _fullPhone = _emptyToNull(phone.completeNumber);

              // ✅ DO NOT notify parent here
              // (prevents bloc updates + rebuild + keyboard closing on each digit)
              // Sync happens on blur via _phoneFocus listener.
            },

            onCountryChanged: (_) {
              // Country selection impacts final phone format; sync is okay here.
              _debouncedNotify();
            },

            validator: (phone) {
              final rawLocal =
                  (phone?.number ?? '').replaceAll(RegExp(r'\D'), '');
              final localDigits =
                  rawLocal.isNotEmpty ? rawLocal : _phoneLocalDigits;

              if (localDigits.isEmpty) {
                return l10n.fieldRequired;
              }

              // ✅ Before submit: don't validate aggressively while typing
              if (!widget.showPickerErrors) return null;

              final selectedIso =
                  (_selectedCountry?.iso2Code ?? countryIso).toUpperCase();

              // LB rule = exactly 8 local digits
              if (selectedIso == 'LB') {
                if (localDigits.length != 8) return l10n.invalidPhone;
              } else {
                // generic fallback for non-LB
                if (localDigits.length < 6) return l10n.invalidPhone;
              }

              return null;
            },
          ),

          SizedBox(height: spacing.sm),

          // ✅ Optional (force no validation in case AppTextField defaults to required)
          AppTextField(
            label: l10n.checkoutNotesLabel,
            controller: _notesCtrl,
            hintText: l10n.checkoutNotesHint,
            textInputAction: TextInputAction.done,
            validator: (_) => null,
          ),
        ],
      ),
    );
  }
}

/* ===== searchable picker ===== */

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
    final l10n = AppLocalizations.of(context)!;
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
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(tokens.card.radius),
                  ),
                ),
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
                    ? l10n.noOptions
                    : (value == null ? hintText : label(value as T)),
                style: text.bodyMedium.copyWith(
                  color: items.isEmpty
                      ? c.muted
                      : (value == null ? c.muted : c.label),
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: c.muted),
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
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final spacing = tokens.spacing;
    final text = tokens.typography;

    final h = MediaQuery.of(context).size.height;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: h * 0.78,
        child: Padding(
          padding: EdgeInsets.only(
            left: spacing.lg,
            right: spacing.lg,
            top: spacing.lg,
            bottom: spacing.lg,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: text.titleMedium.copyWith(
                        color: c.label,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(height: spacing.md),
              AppSearchField(
                hintText: l10n.searchLabel,
                controller: _searchCtrl,
              ),
              SizedBox(height: spacing.md),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(spacing.lg),
                          child: Text(
                            l10n.noResultsLabel,
                            style: text.bodyMedium.copyWith(color: c.muted),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
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
      ),
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}