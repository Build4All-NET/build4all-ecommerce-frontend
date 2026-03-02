import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/app_search_field.dart';

import '../../data/repositories/owner_payment_config_repository_impl.dart';
import '../../data/services/owner_payment_config_api_service.dart';
import '../../domain/usecases/get_owner_payment_methods.dart';
import '../../domain/usecases/save_owner_payment_method_config.dart';
import '../bloc/owner_payment_config_bloc.dart';
import '../bloc/owner_payment_config_event.dart';
import '../bloc/owner_payment_config_state.dart';
import '../widgets/payment_method_config_sheet.dart';

class OwnerPaymentConfigScreen extends StatelessWidget {
  /// ✅ Token provider so screen can run in:
  /// - Owner app token store
  /// - Admin dashboard token store
  final Future<String?> Function()? getToken;

  const OwnerPaymentConfigScreen({
    super.key,
    this.getToken,
  });

  @override
  Widget build(BuildContext context) {
    final repo = OwnerPaymentConfigRepositoryImpl(
      api: OwnerPaymentConfigApiService(dio: Dio(), baseUrl: Env.apiBaseUrl),
      tokenProvider: () async {
        final t = await (getToken?.call());
        return (t ?? '').trim();
      },
    );

    return BlocProvider(
      create: (_) => OwnerPaymentConfigBloc(
        getMethods: GetOwnerPaymentMethods(repo),
        saveConfig: SaveOwnerPaymentMethodConfig(repo),
      )..add(OwnerPaymentConfigLoad()),
      child: const _OwnerPaymentConfigView(),
    );
  }
}

class _OwnerPaymentConfigView extends StatefulWidget {
  const _OwnerPaymentConfigView();

  @override
  State<_OwnerPaymentConfigView> createState() => _OwnerPaymentConfigViewState();
}

class _OwnerPaymentConfigViewState extends State<_OwnerPaymentConfigView> {
  String _q = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final s = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.surface,
        elevation: 0,
        title: Text(
          l10n.paymentMethodsTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: c.label,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: BlocConsumer<OwnerPaymentConfigBloc, OwnerPaymentConfigState>(
        listenWhen: (p, n) => p.error != n.error && n.error != null,
        listener: (context, state) {
          if (state.error != null) {
            AppToast.show(context, state.error!, isError: true);
          }
        },
        builder: (context, state) {
          final items = state.items.where((it) {
            if (!it.platformEnabled) return false;

            final q = _q.trim().toLowerCase();
            if (q.isEmpty) return true;

            final nameMatch = it.name.toLowerCase().contains(q);
            final titleMatch = (it.configSchema['title'] ?? '')
                .toString()
                .toLowerCase()
                .contains(q);

            return nameMatch || titleMatch;
          }).toList();

          return Padding(
            padding: EdgeInsets.all(s.lg),
            child: Column(
              children: [
                AppSearchField(
                  controller: _searchCtrl,
                  hintText: l10n.paymentSearchHint,
                  onChanged: (v) => setState(() => _q = v),
                  textInputAction: TextInputAction.search,
                ),
                SizedBox(height: s.lg),
                if (state.loading)
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: c.primary),
                    ),
                  )
                else if (items.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.paymentNoResults,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: c.body),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => SizedBox(height: s.md),
                      itemBuilder: (context, i) {
                        final it = items[i];
                        final code = it.name.toUpperCase();
                        final saving = state.savingCodes.contains(code);

                        return _PaymentMethodTile(
                          methodName: it.name,
                          title: (it.configSchema['title'] ?? it.name).toString(),
                          enabled: it.projectEnabled,
                          saving: saving,
                          incomplete: _isIncomplete(
                            it.configSchema,
                            it.configValues,
                          ),
                          onToggle: (val) async {
                            if (saving) return;

                            // ✅ DISABLE: save immediately + send empty config to backend
                            if (val == false) {
                              context.read<OwnerPaymentConfigBloc>().add(
                                    OwnerPaymentConfigSave(
                                      methodName: it.name,
                                      enabled: false,
                                      configValues: const {},
                                    ),
                                  );
                              return;
                            }

                            // ✅ ENABLE => configure
                            final result = await showModalBottomSheet<
                                Map<String, Object?>>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: c.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(tokens.card.radius),
                                ),
                              ),
                              builder: (_) => PaymentMethodConfigSheet(
                                methodName: it.name,
                                schema: it.configSchema,
                                existingValues: it.configValues,
                              ),
                            );

                            if (result == null) return;

                            context.read<OwnerPaymentConfigBloc>().add(
                                  OwnerPaymentConfigSave(
                                    methodName: it.name,
                                    enabled: true,
                                    configValues: result,
                                  ),
                                );

                            AppToast.show(context, l10n.paymentSavedKeepHint);
                          },
                          onConfigure: () async {
                            if (saving) return;

                            final result = await showModalBottomSheet<
                                Map<String, Object?>>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: c.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(tokens.card.radius),
                                ),
                              ),
                              builder: (_) => PaymentMethodConfigSheet(
                                methodName: it.name,
                                schema: it.configSchema,
                                existingValues: it.configValues,
                              ),
                            );

                            if (result == null) return;

                            context.read<OwnerPaymentConfigBloc>().add(
                                  OwnerPaymentConfigSave(
                                    methodName: it.name,
                                    enabled: true,
                                    configValues: result,
                                  ),
                                );

                            AppToast.show(context, l10n.paymentSavedKeepHint);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isIncomplete(Map<String, dynamic> schema, Map<String, dynamic> values) {
    final fields = schema['fields'];
    if (fields is! List) return false;

    for (final f in fields) {
      if (f is! Map) continue;
      final required = f['required'] == true;
      if (!required) continue;

      final key = (f['key'] ?? '').toString();
      final val = values[key];
      if (val == null || val.toString().trim().isEmpty) return true;
    }
    return false;
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final String methodName;
  final String title;
  final bool enabled;
  final bool saving;
  final bool incomplete;
  final ValueChanged<bool?> onToggle;
  final VoidCallback onConfigure;

  const _PaymentMethodTile({
    required this.methodName,
    required this.title,
    required this.enabled,
    required this.saving,
    required this.incomplete,
    required this.onToggle,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final c = tokens.colors;
    final s = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: c.border.withOpacity(0.25), width: 1),
      ),
      padding: EdgeInsets.all(s.md),
      child: Row(
        children: [
          Checkbox(
            value: enabled,
            onChanged: saving ? null : onToggle,
            activeColor: c.primary,
          ),
          SizedBox(width: s.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: c.label,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                SizedBox(height: s.xs),
                if (enabled && incomplete)
                  Text(
                    l10n.paymentIncomplete,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: c.error,
                          fontWeight: FontWeight.w600,
                        ),
                  )
                else
                  Text(
                    methodName.toUpperCase(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: c.muted),
                  ),
              ],
            ),
          ),
          SizedBox(width: s.sm),
          if (saving)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: c.primary,
              ),
            )
          else
            TextButton(
              onPressed: onConfigure,
              child: Text(l10n.paymentConfigure),
            ),
        ],
      ),
    );
  }
}