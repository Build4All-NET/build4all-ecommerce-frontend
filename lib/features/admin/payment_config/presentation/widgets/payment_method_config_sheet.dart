import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/common/widgets/app_toast.dart';

import '../bloc/owner_payment_config_bloc.dart';
import '../bloc/owner_payment_config_event.dart';
import '../bloc/owner_payment_config_state.dart';

class PaymentMethodConfigSheet extends StatefulWidget {
  final String methodName;
  final Map<String, dynamic> schema;
  final Map<String, dynamic> existingValues;

  const PaymentMethodConfigSheet({
    super.key,
    required this.methodName,
    required this.schema,
    required this.existingValues,
  });

  @override
  State<PaymentMethodConfigSheet> createState() =>
      _PaymentMethodConfigSheetState();
}

class _PaymentMethodConfigSheetState extends State<PaymentMethodConfigSheet> {
  late final List<Map<String, dynamic>> _fields;
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _selected = {};

  @override
  void initState() {
    super.initState();

    final rawFields = widget.schema['fields'];
    _fields = (rawFields is List)
        ? rawFields
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : <Map<String, dynamic>>[];

    for (final f in _fields) {
      final key = (f['key'] ?? '').toString();
      final type = (f['type'] ?? 'text').toString();

      if (type == 'select') {
        final existing = widget.existingValues[key]?.toString();
        final def = f['default']?.toString();
        _selected[key] = existing ?? def ?? '';
      } else {
        final existing = widget.existingValues[key]?.toString();
        final def = f['default']?.toString();

        // ✅ Password stays empty (don't show secrets)
        final initialText = (type == 'password') ? '' : (existing ?? def ?? '');

        _controllers[key] = TextEditingController(text: initialText);
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeCubit>().state.tokens;
    final c = theme.colors;
    final s = theme.spacing;
    final l10n = AppLocalizations.of(context)!;

    final title = (widget.schema['title'] ?? widget.methodName).toString();
    final description = widget.schema['description']?.toString();
    final docsUrl = widget.schema['docsUrl']?.toString();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: s.lg,
          right: s.lg,
          top: s.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + s.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: c.label,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: s.sm),
              Text(
                l10n.paymentFillFields,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: c.body),
              ),
              SizedBox(height: s.sm),
              Text(
                l10n.paymentSavedKeepHint,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: c.muted),
              ),
              if (description != null && description.isNotEmpty) ...[
                SizedBox(height: s.md),
                Container(
                  padding: EdgeInsets.all(s.md),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(theme.card.radius),
                    border: Border.all(
                      color: c.border.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: c.primary,
                          ),
                          SizedBox(width: s.sm),
                          Expanded(
                            child: Text(
                              description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: c.body),
                            ),
                          ),
                        ],
                      ),
                      if (docsUrl != null && docsUrl.isNotEmpty) ...[
                        SizedBox(height: s.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openUrl(docsUrl),
                            icon: Icon(
                              Icons.open_in_new,
                              size: 16,
                              color: c.primary,
                            ),
                            label: Text(
                              'Open provider docs',
                              style: TextStyle(color: c.primary),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: s.sm,
                                vertical: 0,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              SizedBox(height: s.lg),

              ..._fields.map((f) => _buildField(context, f)).toList(),

              SizedBox(height: s.md),
              BlocConsumer<OwnerPaymentConfigBloc, OwnerPaymentConfigState>(
                listenWhen: (p, n) {
                  final code = widget.methodName.toUpperCase();
                  return p.testResults[code] != n.testResults[code] &&
                      n.testResults[code] != null;
                },
                listener: (ctx, state) {
                  final code = widget.methodName.toUpperCase();
                  final outcome = state.testResults[code];
                  if (outcome == null) return;
                  if (outcome.ok) {
                    AppToast.success(ctx, 'Connection succeeded');
                  } else {
                    AppToast.error(
                      ctx,
                      outcome.error ?? 'Connection failed',
                    );
                  }
                },
                buildWhen: (p, n) {
                  final code = widget.methodName.toUpperCase();
                  return p.testingCodes.contains(code) !=
                          n.testingCodes.contains(code) ||
                      p.testResults[code] != n.testResults[code];
                },
                builder: (ctx, state) {
                  final code = widget.methodName.toUpperCase();
                  final testing = state.testingCodes.contains(code);

                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: testing ? null : () => _onTest(ctx),
                      icon: testing
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.primary,
                              ),
                            )
                          : Icon(Icons.link, color: c.primary),
                      label: Text(
                        testing ? 'Testing…' : 'Test connection',
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: s.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.paymentCancel),
                    ),
                  ),
                  SizedBox(width: s.md),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            theme.card.radius,
                          ),
                        ),
                      ),
                      onPressed: _onSave,
                      child: Text(l10n.paymentSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Object?> _collectValuesForTest() {
    final out = <String, Object?>{};

    for (final f in _fields) {
      final key = (f['key'] ?? '').toString();
      final type = (f['type'] ?? 'text').toString();

      if (type == 'select') {
        final sel = (_selected[key] ?? '').trim();
        if (sel.isNotEmpty) out[key] = sel;
      } else {
        final raw = (_controllers[key]?.text ?? '').trim();
        if (raw.isEmpty) continue;
        if (type == 'number') {
          final parsed = num.tryParse(raw);
          if (parsed != null) out[key] = parsed;
        } else {
          out[key] = raw;
        }
      }
    }
    return out;
  }

  void _onTest(BuildContext ctx) {
    final values = _collectValuesForTest();
    ctx.read<OwnerPaymentConfigBloc>().add(
          OwnerPaymentConfigTest(
            methodName: widget.methodName,
            configValues: values,
          ),
        );
  }

  Widget _buildField(BuildContext context, Map<String, dynamic> f) {
    final theme = context.watch<ThemeCubit>().state.tokens;
    final c = theme.colors;
    final s = theme.spacing;
    final l10n = AppLocalizations.of(context)!;

    final key = (f['key'] ?? '').toString();
    final label = (f['label'] ?? key).toString();
    final type = (f['type'] ?? 'text').toString();
    final requiredField = (f['required'] == true);
    final hint = f['hint']?.toString();
    final helpUrl = f['helpUrl']?.toString();
    final placeholder = f['placeholder']?.toString();

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(theme.card.radius),
      borderSide: BorderSide(color: c.border.withOpacity(0.25), width: 1),
    );

    Widget input;

    if (type == 'select') {
      final options = (f['options'] is List)
          ? (f['options'] as List).map((e) => e.toString()).toList()
          : <String>[];

      final v = _selected[key] ?? (options.isNotEmpty ? options.first : '');

      input = DropdownButtonFormField<String>(
        value: options.contains(v)
            ? v
            : (options.isNotEmpty ? options.first : null),
        items: options
            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
            .toList(),
        onChanged: (nv) => setState(() => _selected[key] = nv ?? ''),
        decoration: InputDecoration(
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: c.primary, width: 1),
          ),
        ),
      );
    } else {
      final ctrl = _controllers[key]!;
      final isPassword = type == 'password';
      final isTextArea = type == 'textarea';
      final isNumber = type == 'number';

      final String? hintText = (isPassword && widget.existingValues[key] != null)
          ? l10n.paymentSavedKeepHint
          : placeholder;

      input = TextField(
        controller: ctrl,
        obscureText: isPassword,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: isTextArea ? 4 : 1,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.label),
        decoration: InputDecoration(
          hintText: hintText,
          filled: true,
          fillColor: c.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: s.md,
            vertical: s.sm,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: c.primary, width: 1),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: s.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            requiredField ? '$label *' : label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: c.muted),
          ),
          SizedBox(height: s.xs),
          input,
          if (hint != null && hint.isNotEmpty) ...[
            SizedBox(height: s.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    hint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: c.muted),
                  ),
                ),
                if (helpUrl != null && helpUrl.isNotEmpty)
                  GestureDetector(
                    onTap: () => _openUrl(helpUrl),
                    child: Padding(
                      padding: EdgeInsets.only(left: s.sm),
                      child: Text(
                        'Learn more',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: c.primary,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          ] else if (helpUrl != null && helpUrl.isNotEmpty) ...[
            SizedBox(height: s.xs),
            GestureDetector(
              onTap: () => _openUrl(helpUrl),
              child: Text(
                'Learn more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: c.primary,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) AppToast.error(context, 'Could not open $url');
    }
  }

  void _onSave() {
    final out = <String, Object?>{};

    for (final f in _fields) {
      final key = (f['key'] ?? '').toString();
      final type = (f['type'] ?? 'text').toString();
      final requiredField = (f['required'] == true);

      Object? finalValue;

      if (type == 'select') {
        finalValue = (_selected[key] ?? '').trim();
        if ((finalValue as String).isEmpty) {
          finalValue = widget.existingValues[key]?.toString() ?? '';
        }
      } else {
        final raw = (_controllers[key]?.text ?? '').trim();

        if (raw.isEmpty) {
          // empty => keep existing (especially for passwords)
          finalValue = widget.existingValues[key];
        } else {
          if (type == 'number') {
            final parsed = num.tryParse(raw);
            if (parsed == null) {
              AppToast.error(context, 'Invalid number: $key');
              return;
            }
            finalValue = parsed;
          } else {
            finalValue = raw;
          }
        }
      }

      final missing =
          finalValue == null || finalValue.toString().trim().isEmpty;

      if (requiredField && missing) {
        AppToast.error(context, 'Missing required field: $key');
        return;
      }

      if (!missing) {
        out[key] = finalValue;
      }
    }

    Navigator.pop<Map<String, Object?>>(context, out);
  }
}
