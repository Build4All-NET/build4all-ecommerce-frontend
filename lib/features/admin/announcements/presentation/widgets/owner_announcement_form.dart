import 'dart:io';

import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/admin/product/data/services/product_api_service.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class OwnerAnnouncementForm extends StatefulWidget {
  final bool submitting;
  final void Function({
    required String title,
    required String message,
    required String announcementType,
    int? targetId,
    String? imagePath,
  }) onSubmit;

  const OwnerAnnouncementForm({
    super.key,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  State<OwnerAnnouncementForm> createState() => _OwnerAnnouncementFormState();
}

class _OwnerAnnouncementFormState extends State<OwnerAnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final AdminTokenStore _tokenStore = const AdminTokenStore();

  String _type = 'GENERAL';
  File? _imageFile;

  bool _loadingTargets = false;
  String? _targetError;

  int? _selectedTargetId;
  List<_TargetOption> _targetOptions = [];

  bool get _needsProductTarget {
    final cleanType = _type.trim().toUpperCase();
    return cleanType == 'PRODUCT' || cleanType == 'DISCOUNT';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  List<_AnnouncementTypeOption> _types(AppLocalizations l10n) {
    return [
      _AnnouncementTypeOption('GENERAL', l10n.adminAnnouncementsTypeGeneral),
      _AnnouncementTypeOption('PRODUCT', l10n.adminAnnouncementsTypeProduct),
      _AnnouncementTypeOption('DISCOUNT', l10n.adminAnnouncementsTypeDiscount),
      _AnnouncementTypeOption('SERVICE', l10n.adminAnnouncementsTypeService),
      _AnnouncementTypeOption(
        'MAINTENANCE',
        l10n.adminAnnouncementsTypeMaintenance,
      ),
    ];
  }

  int _readOwnerProjectId() {
    final fromProject = int.tryParse((g.projectId ?? '').trim());
    if (fromProject != null && fromProject > 0) {
      return fromProject;
    }

    final fromLink = int.tryParse((g.ownerProjectLinkId ?? '').trim());
    if (fromLink != null && fromLink > 0) {
      return fromLink;
    }

    return 0;
  }

  String _asString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse('$value') ?? 0;
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  String _productLabel(Map<String, dynamic> json) {
    final name = _asString(json['name']);
    if (name.isNotEmpty) return name;

    final title = _asString(json['title']);
    if (title.isNotEmpty) return title;

    return 'Product #${_asInt(json['id'])}';
  }

  String? _productSubtitle(Map<String, dynamic> json) {
    final sku = _asString(json['sku']);
    final price = _asDouble(json['effectivePrice'] ?? json['price']);

    if (sku.isNotEmpty && price != null) {
      return 'SKU: $sku • $price';
    }

    if (sku.isNotEmpty) {
      return 'SKU: $sku';
    }

    if (price != null) {
      return '$price';
    }

    return null;
  }

  Future<void> _loadTargetsForType(String type) async {
    final cleanType = type.trim().toUpperCase();

    if (cleanType != 'PRODUCT' && cleanType != 'DISCOUNT') {
      setState(() {
        _selectedTargetId = null;
        _targetOptions = [];
        _targetError = null;
        _loadingTargets = false;
      });
      return;
    }

    setState(() {
      _loadingTargets = true;
      _targetError = null;
      _selectedTargetId = null;
      _targetOptions = [];
    });

    try {
      final token = await _tokenStore.getToken();

      if (token == null || token.trim().isEmpty) {
        throw Exception('Missing owner token');
      }

      final ownerProjectId = _readOwnerProjectId();

      if (ownerProjectId <= 0) {
        throw Exception('Missing ownerProjectId');
      }

      final api = ProductApiService();

      final List<dynamic> rawList;

      if (cleanType == 'DISCOUNT') {
        rawList = await api.getDiscounted(
          authToken: token,
        );
      } else {
        rawList = await api.getProducts(
          ownerProjectId: ownerProjectId,
          authToken: token,
        );
      }

      final options = <_TargetOption>[];

      for (final item in rawList) {
        if (item is! Map) continue;

        final json = Map<String, dynamic>.from(item);
        final id = _asInt(json['id']);

        if (id <= 0) continue;

        options.add(
          _TargetOption(
            id: id,
            label: _productLabel(json),
            subtitle: _productSubtitle(json),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _targetOptions = options;
        _loadingTargets = false;
        _targetError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _targetOptions = [];
        _loadingTargets = false;
        _targetError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );

    if (picked == null) return;

    setState(() {
      _imageFile = File(picked.path);
    });
  }

  void _submit(AppLocalizations l10n) {
    if (!_formKey.currentState!.validate()) return;

    widget.onSubmit(
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      announcementType: _type,
      targetId: _needsProductTarget ? _selectedTargetId : null,
      imagePath: _imageFile?.path,
    );

    _titleCtrl.clear();
    _messageCtrl.clear();

    setState(() {
      _type = 'GENERAL';
      _imageFile = null;
      _selectedTargetId = null;
      _targetOptions = [];
      _targetError = null;
      _loadingTargets = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final text = Theme.of(context).textTheme;

    final types = _types(l10n);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withOpacity(.18)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.campaign_outlined,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminAnnouncementsNotifyAllTitle,
                        style: text.titleMedium?.copyWith(
                          color: colors.label,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.adminAnnouncementsNotifyAllDescription,
                        style: text.bodySmall?.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing.lg),

            TextFormField(
              controller: _titleCtrl,
              enabled: !widget.submitting,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementsTitleLabel,
                hintText: l10n.adminAnnouncementsTitleHint,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: spacing.md),

            TextFormField(
              controller: _messageCtrl,
              enabled: !widget.submitting,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementsMessageLabel,
                hintText: l10n.adminAnnouncementsMessageHint,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return l10n.adminAnnouncementsMessageRequired;
                }

                return null;
              },
            ),
            SizedBox(height: spacing.md),

            DropdownButtonFormField<String>(
              value: _type,
              decoration: InputDecoration(
                labelText: l10n.adminAnnouncementsTypeLabel,
                border: const OutlineInputBorder(),
              ),
              items: types
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item.value,
                      child: Text(item.label),
                    ),
                  )
                  .toList(),
              onChanged: widget.submitting
                  ? null
                  : (value) {
                      if (value == null) return;

                      setState(() {
                        _type = value;
                        _selectedTargetId = null;
                        _targetOptions = [];
                        _targetError = null;
                      });

                      _loadTargetsForType(value);
                    },
            ),

            if (_needsProductTarget) ...[
              SizedBox(height: spacing.md),

              if (_loadingTargets)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.border.withOpacity(.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Loading targets...',
                        style: text.bodyMedium?.copyWith(
                          color: colors.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  value: _selectedTargetId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _type == 'DISCOUNT'
                        ? 'Select discounted product'
                        : 'Select product',
                    border: const OutlineInputBorder(),
                    errorText: _targetError,
                  ),
                  items: _targetOptions.map((item) {
                    return DropdownMenuItem<int>(
                      value: item.id,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((item.subtitle ?? '').trim().isNotEmpty)
                            Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: colors.body,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: widget.submitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedTargetId = value;
                          });
                        },
                  validator: (value) {
                    if (_needsProductTarget && value == null) {
                      return _type == 'DISCOUNT'
                          ? 'Please select a discounted product'
                          : 'Please select a product';
                    }

                    return null;
                  },
                ),

              if (!_loadingTargets &&
                  _targetError == null &&
                  _targetOptions.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _type == 'DISCOUNT'
                        ? 'No discounted products found.'
                        : 'No products found.',
                    style: text.bodySmall?.copyWith(
                      color: colors.body,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],

            SizedBox(height: spacing.md),

            OutlinedButton.icon(
              onPressed: widget.submitting ? null : _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(l10n.chooseImage),
            ),

            if (_imageFile != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _imageFile!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              TextButton.icon(
                onPressed: widget.submitting
                    ? null
                    : () {
                        setState(() => _imageFile = null);
                      },
                icon: const Icon(Icons.close_rounded),
                label: Text(l10n.removeImage),
              ),
            ],

            SizedBox(height: spacing.lg),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.submitting ? null : () => _submit(l10n),
                icon: widget.submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  widget.submitting
                      ? l10n.adminAnnouncementsSendingButton
                      : l10n.adminAnnouncementsSendButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementTypeOption {
  final String value;
  final String label;

  const _AnnouncementTypeOption(this.value, this.label);
}

class _TargetOption {
  final int id;
  final String label;
  final String? subtitle;

  const _TargetOption({
    required this.id,
    required this.label,
    this.subtitle,
  });
}