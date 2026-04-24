import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:build4front/core/config/env.dart';
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
  final Map<String, bool> _toggles = {};

  bool _connectionTestPassed = false;

  bool get _isStripe => widget.methodName.toUpperCase() == 'STRIPE';

  String get _computedWebhookUrl {
    final fromSchema = widget.schema['webhookUrl']?.toString().trim();
    if (fromSchema != null && fromSchema.isNotEmpty) {
      return fromSchema;
    }

    final base = Env.apiBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final ownerProjectId = Env.ownerProjectLinkId.trim();
    return '$base/api/webhooks/payments/checkout/stripe/$ownerProjectId';
  }

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
      } else if (type == 'boolean') {
        final existing = widget.existingValues[key];
        final def = f['default'];
        _toggles[key] = _coerceBool(existing) ?? _coerceBool(def) ?? false;
      } else {
        final existing = widget.existingValues[key]?.toString();
        final def = f['default']?.toString();
        final initialText = (type == 'password') ? '' : (existing ?? def ?? '');
        _controllers[key] = TextEditingController(text: initialText);
      }
    }
  }

  bool? _coerceBool(Object? v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;

    final s = v.toString().trim().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;

    return null;
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
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: c.body),
              ),

              SizedBox(height: s.sm),

              Text(
                l10n.paymentSavedKeepHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: c.muted),
              ),

              if (description != null && description.isNotEmpty) ...[
                SizedBox(height: s.md),
                _buildInfoCard(
                  context,
                  icon: Icons.info_outline,
                  text: description,
                  actionLabel: docsUrl != null && docsUrl.isNotEmpty
                      ? l10n.paymentOpenProviderDocs
                      : null,
                  onAction: docsUrl != null && docsUrl.isNotEmpty
                      ? () => _openUrl(docsUrl)
                      : null,
                ),
              ],

              if (_isStripe) ...[
                SizedBox(height: s.md),
                _buildStripeWebhookCard(context),
              ],

              SizedBox(height: s.lg),

              ..._fields.map((f) => _buildField(context, f)),

              SizedBox(height: s.md),

              BlocConsumer<OwnerPaymentConfigBloc, OwnerPaymentConfigState>(
                listenWhen: (p, n) {
                  final code = widget.methodName.toUpperCase();
                  return p.testResults[code] != n.testResults[code] &&
                      n.testResults[code] != null;
                },
                listener: (ctx, state) {
                  final l10n = AppLocalizations.of(ctx)!;
                  final code = widget.methodName.toUpperCase();
                  final outcome = state.testResults[code];

                  if (outcome == null) return;

                  if (outcome.ok) {
                    setState(() => _connectionTestPassed = true);
                    AppToast.success(ctx, l10n.connectionSucceeded);
                  } else {
                    setState(() => _connectionTestPassed = false);
                    AppToast.error(
                      ctx,
                      outcome.error ?? l10n.connectionFailed,
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
                        testing
                            ? l10n.paymentTestingConnection
                            : l10n.paymentTestConnection,
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
                          borderRadius: BorderRadius.circular(theme.card.radius),
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

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String text,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final theme = context.watch<ThemeCubit>().state.tokens;
    final c = theme.colors;
    final s = theme.spacing;

    return Container(
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
              Icon(icon, size: 18, color: c.primary),
              SizedBox(width: s.sm),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: c.body),
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: s.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAction,
                icon: Icon(Icons.open_in_new, size: 16, color: c.primary),
                label: Text(
                  actionLabel,
                  style: TextStyle(color: c.primary),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: 0),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStripeWebhookCard(BuildContext context) {
    final theme = context.watch<ThemeCubit>().state.tokens;
    final c = theme.colors;
    final s = theme.spacing;
    final l10n = AppLocalizations.of(context)!;

    final webhookUrl = _computedWebhookUrl;

    Widget step(String text) {
      return Padding(
        padding: EdgeInsets.only(bottom: s.xs),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: c.body,
                height: 1.35,
              ),
        ),
      );
    }

    Widget eventName(String text) {
      return Container(
        margin: EdgeInsets.only(right: s.xs, bottom: s.xs),
        padding: EdgeInsets.symmetric(horizontal: s.sm, vertical: s.xs),
        decoration: BoxDecoration(
          color: c.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: c.primary.withOpacity(0.25)),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: c.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(s.md),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(theme.card.radius),
        border: Border.all(
          color: c.primary.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.webhook, color: c.primary, size: 18),
              SizedBox(width: s.sm),
              Expanded(
                child: Text(
                  l10n.stripeWebhookSetupTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: c.label,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),

          SizedBox(height: s.sm),

          Text(
            l10n.stripeWebhookSetupDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: c.body,
                  height: 1.35,
                ),
          ),

          SizedBox(height: s.md),

          step(l10n.stripeWebhookStep1),
          step(l10n.stripeWebhookStep2),
          step(l10n.stripeWebhookStep3),
          step(l10n.stripeWebhookStep4),
          step(l10n.stripeWebhookStep5),

          SizedBox(height: s.xs),

          Wrap(
            children: [
              eventName('checkout.session.completed'),
              eventName('payment_intent.succeeded'),
              eventName('payment_intent.payment_failed'),
              eventName('charge.refunded'),
            ],
          ),

          SizedBox(height: s.sm),

          step(l10n.stripeWebhookStep6),
          step(l10n.stripeWebhookStep7),
          step(l10n.stripeWebhookStep8),

          SizedBox(height: s.sm),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(s.sm),
            decoration: BoxDecoration(
              color: c.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(theme.card.radius),
              border: Border.all(color: c.primary.withOpacity(0.20)),
            ),
            child: Text(
              l10n.stripeWebhookImportant,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: c.label,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
            ),
          ),

          SizedBox(height: s.md),

          Text(
            l10n.stripeWebhookUrlLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: c.label,
                  fontWeight: FontWeight.w800,
                ),
          ),

          SizedBox(height: s.xs),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(s.md),
            decoration: BoxDecoration(
              color: c.background,
              borderRadius: BorderRadius.circular(theme.card.radius),
              border: Border.all(
                color: c.border.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: SelectableText(
              webhookUrl,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: c.label,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),

          SizedBox(height: s.sm),

          Wrap(
            spacing: s.sm,
            runSpacing: s.sm,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: webhookUrl));

                  if (mounted) {
                    AppToast.success(context, l10n.stripeWebhookCopied);
                  }
                },
                icon: const Icon(Icons.copy, size: 16),
                label: Text(l10n.stripeWebhookCopyButton),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _openUrl('https://dashboard.stripe.com/webhooks'),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.stripeWebhookOpenStripe),
              ),
            ],
          ),
        ],
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
      } else if (type == 'boolean') {
        out[key] = _toggles[key] ?? false;
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
    setState(() => _connectionTestPassed = false);

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
        onChanged: (nv) {
          setState(() {
            _selected[key] = nv ?? '';
            _connectionTestPassed = false;
          });
        },
        decoration: InputDecoration(
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: c.primary, width: 1),
          ),
        ),
      );
    } else if (type == 'boolean') {
      final v = _toggles[key] ?? false;

      input = SwitchListTile.adaptive(
        value: v,
        onChanged: (nv) {
          setState(() {
            _toggles[key] = nv;
            _connectionTestPassed = false;
          });
        },
        contentPadding: EdgeInsets.zero,
        title: Text(
          v ? l10n.paymentOn : l10n.paymentOff,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: c.label),
        ),
        activeColor: c.primary,
      );
    } else {
      final ctrl = _controllers[key]!;
      final isPassword = type == 'password';
      final isTextArea = type == 'textarea';
      final isNumber = type == 'number';

      final String? hintText =
          (isPassword && widget.existingValues[key] != null)
              ? l10n.paymentSavedKeepHint
              : placeholder;

      input = TextField(
        controller: ctrl,
        obscureText: isPassword,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: isTextArea ? 4 : 1,
        onChanged: (_) {
          if (_connectionTestPassed) {
            setState(() => _connectionTestPassed = false);
          }
        },
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: c.label),
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
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: c.muted),
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
                        l10n.paymentLearnMore,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                l10n.paymentLearnMore,
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
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        AppToast.error(context, l10n.paymentCouldNotOpenUrl);
      }
    }
  }

  void _onSave() {
    final l10n = AppLocalizations.of(context)!;

    if (_isStripe && !_connectionTestPassed) {
      AppToast.error(context, l10n.stripeWebhookMustTestFirst);
      return;
    }

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
      } else if (type == 'boolean') {
        out[key] = _toggles[key] ?? false;
        continue;
      } else {
        final raw = (_controllers[key]?.text ?? '').trim();

        if (raw.isEmpty) {
          finalValue = widget.existingValues[key];
        } else {
          if (type == 'number') {
            final parsed = num.tryParse(raw);

            if (parsed == null) {
              AppToast.error(context, l10n.paymentInvalidNumber(key));
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
        AppToast.error(context, l10n.paymentMissingRequiredField(key));
        return;
      }

      if (!missing) {
        out[key] = finalValue;
      }
    }

    Navigator.pop<Map<String, Object?>>(context, out);
  }
}