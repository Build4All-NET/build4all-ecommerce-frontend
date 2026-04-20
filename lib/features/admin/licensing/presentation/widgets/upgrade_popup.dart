import 'package:build4front/common/widgets/primary_button.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/admin/licensing/data/models/owner_app_access_response.dart';
import 'package:build4front/features/admin/licensing/domain/entities/available_payment_method.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/plan_pricing.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_plan.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'billing_cycle_selector.dart';
import 'plan_selection_card.dart';

/// Opens the upgrade popup as a bottom sheet using the project's standard
/// modal style (safe area, rounded top corners, transparent background).
///
/// The returned future resolves with `true` if the user confirmed payment
/// (i.e. tapped "Pay now") and `null`/`false` otherwise.
Future<T?> showUpgradePopup<T>({
  required BuildContext context,
  required List<UpgradePlan> plans,
  bool isLoading = false,
  bool isProcessing = false,
  PlanCode? initialSelectedPlan,
  BillingCycle initialBillingCycle = BillingCycle.MONTHLY,
  List<AvailablePaymentMethod> paymentMethods = const [],
  String? selectedPaymentMethodCode,
  String? errorMessage,
  void Function(PlanCode? plan, BillingCycle cycle)? onSelectionChanged,
  ValueChanged<String>? onPaymentMethodSelected,
  void Function(PlanCode plan, BillingCycle cycle)? onPayNow,
  VoidCallback? onClose,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => UpgradePopup(
      isLoading: isLoading,
      isProcessing: isProcessing,
      plans: plans,
      initialSelectedPlan: initialSelectedPlan,
      initialBillingCycle: initialBillingCycle,
      paymentMethods: paymentMethods,
      selectedPaymentMethodCode: selectedPaymentMethodCode,
      errorMessage: errorMessage,
      onSelectionChanged: onSelectionChanged,
      onPaymentMethodSelected: onPaymentMethodSelected,
      onPayNow: onPayNow,
      onClose: onClose,
    ),
  );
}

/// Pure presentational popup for the owner upgrade flow.
///
/// Owns only the local selection state (plan + billing cycle). Parents get
/// notified through [onSelectionChanged] and trigger payment via [onPayNow].
/// Visibility/navigation is controlled by the caller through [onClose].
class UpgradePopup extends StatefulWidget {
  /// Fetching available plans from the backend.
  final bool isLoading;

  /// Payment request is in flight (shows spinner on the CTA, disables inputs).
  final bool isProcessing;

  /// Plans the owner can upgrade to. Empty list renders an empty state.
  final List<UpgradePlan> plans;

  /// Pre-selected plan (optional). When null, no plan is selected on open.
  final PlanCode? initialSelectedPlan;

  /// Starting billing cycle; defaults to monthly.
  final BillingCycle initialBillingCycle;

  /// Payment methods the owner may pick from. When empty, the section
  /// is hidden (and [onPayNow] stays disabled until a method is set).
  final List<AvailablePaymentMethod> paymentMethods;

  /// Pre-selected payment method code. When null, the owner must pick one
  /// before the CTA is enabled.
  final String? selectedPaymentMethodCode;

  /// Optional inline error to show above the plans section.
  final String? errorMessage;

  /// Called whenever the plan or billing cycle changes.
  /// `plan` may be null if selection was cleared.
  final void Function(PlanCode? plan, BillingCycle cycle)? onSelectionChanged;

  /// Called when the user picks a payment method.
  final ValueChanged<String>? onPaymentMethodSelected;

  /// Called when the user taps the CTA after selecting a plan.
  final void Function(PlanCode plan, BillingCycle cycle)? onPayNow;

  /// Called when the user dismisses the popup (cancel button / drag down).
  /// The caller is responsible for actually popping the route if needed.
  final VoidCallback? onClose;

  const UpgradePopup({
    super.key,
    required this.plans,
    this.isLoading = false,
    this.isProcessing = false,
    this.initialSelectedPlan,
    this.initialBillingCycle = BillingCycle.MONTHLY,
    this.paymentMethods = const [],
    this.selectedPaymentMethodCode,
    this.errorMessage,
    this.onSelectionChanged,
    this.onPaymentMethodSelected,
    this.onPayNow,
    this.onClose,
  });

  @override
  State<UpgradePopup> createState() => _UpgradePopupState();
}

class _UpgradePopupState extends State<UpgradePopup> {
  late PlanCode? _selectedPlan;
  late BillingCycle _cycle;
  String? _selectedMethodCode;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.initialSelectedPlan;
    _cycle = widget.initialBillingCycle;
    _selectedMethodCode = widget.selectedPaymentMethodCode;
  }

  @override
  void didUpdateWidget(covariant UpgradePopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep local state in sync if the parent intentionally changes inputs
    // (e.g. after data refresh).
    if (oldWidget.initialSelectedPlan != widget.initialSelectedPlan &&
        widget.initialSelectedPlan != _selectedPlan) {
      _selectedPlan = widget.initialSelectedPlan;
    }
    if (oldWidget.initialBillingCycle != widget.initialBillingCycle &&
        widget.initialBillingCycle != _cycle) {
      _cycle = widget.initialBillingCycle;
    }
    if (oldWidget.selectedPaymentMethodCode !=
            widget.selectedPaymentMethodCode &&
        widget.selectedPaymentMethodCode != _selectedMethodCode) {
      _selectedMethodCode = widget.selectedPaymentMethodCode;
    }
  }

  double _bottomInset(BuildContext context) {
    final media = MediaQuery.of(context);
    final safe = media.viewPadding.bottom;
    final keyboard = media.viewInsets.bottom;
    return keyboard > 0 ? keyboard : safe;
  }

  void _selectPlan(PlanCode code) {
    if (widget.isProcessing) return;
    final next = code == _selectedPlan ? null : code;
    setState(() => _selectedPlan = next);
    widget.onSelectionChanged?.call(next, _cycle);
  }

  void _selectCycle(BillingCycle cycle) {
    if (widget.isProcessing) return;
    setState(() => _cycle = cycle);
    widget.onSelectionChanged?.call(_selectedPlan, cycle);
  }

  void _selectMethod(String code) {
    if (widget.isProcessing) return;
    setState(() => _selectedMethodCode = code);
    widget.onPaymentMethodSelected?.call(code);
  }

  bool get _hasSelection =>
      _selectedPlan != null &&
      _selectedMethodCode != null &&
      _selectedMethodCode!.isNotEmpty;

  void _handlePayNow() {
    final plan = _selectedPlan;
    if (plan == null ||
        widget.isProcessing ||
        _selectedMethodCode == null ||
        _selectedMethodCode!.isEmpty) {
      return;
    }
    widget.onPayNow?.call(plan, _cycle);
  }

  void _handleClose() {
    if (widget.isProcessing) return;
    widget.onClose?.call();
  }

  UpgradePlan? get _selectedPlanDetails {
    if (_selectedPlan == null) return null;
    for (final p in widget.plans) {
      if (p.code == _selectedPlan) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final textTheme = Theme.of(context).textTheme;
    final inset = _bottomInset(context);
    final hasSelection = _hasSelection;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: inset),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Handle(colors: colors),
                  const SizedBox(height: 14),
                  _Header(
                    colors: colors,
                    textTheme: textTheme,
                    title: l10n.upgradeSheetTitle,
                    subtitle: l10n.upgradeSheetSubtitle,
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.errorMessage != null &&
                              widget.errorMessage!.isNotEmpty) ...[
                            _InlineError(
                              message: widget.errorMessage!,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 10),
                          ],
                          _buildPlansSection(l10n, colors, textTheme),
                          const SizedBox(height: 14),
                          _SectionLabel(
                            text: l10n.upgradeBillingCycleLabel,
                            colors: colors,
                            textTheme: textTheme,
                          ),
                          const SizedBox(height: 8),
                          BillingCycleSelector(
                            value: _cycle,
                            onChanged: _selectCycle,
                          ),
                          const SizedBox(height: 14),
                          if (_selectedPlanDetails != null)
                            _PricePreview(
                              pricing: _selectedPlanDetails!.pricing,
                              cycle: _cycle,
                            ),
                          if (widget.paymentMethods.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _SectionLabel(
                              text: l10n.upgradePaymentMethodLabel,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                            const SizedBox(height: 8),
                            _PaymentMethodList(
                              methods: widget.paymentMethods,
                              selectedCode: _selectedMethodCode,
                              disabled: widget.isProcessing,
                              onSelected: _selectMethod,
                            ),
                          ] else if (!widget.isLoading) ...[
                            const SizedBox(height: 14),
                            _InlineError(
                              message: l10n.upgradeNoPaymentMethods,
                              colors: colors,
                              textTheme: textTheme,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: hasSelection
                        ? l10n.payNowLabel
                        : l10n.sendRequestLabel,
                    isLoading: widget.isProcessing,
                    onPressed: (hasSelection &&
                            !widget.isLoading &&
                            !widget.isProcessing)
                        ? _handlePayNow
                        : null,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed:
                          widget.isProcessing ? null : _handleClose,
                      child: Text(l10n.cancelLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlansSection(
    AppLocalizations l10n,
    dynamic colors,
    TextTheme textTheme,
  ) {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (widget.plans.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          l10n.noUpgradeAvailable,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: colors.body),
        ),
      );
    }

    return Column(
      children: [
        for (final plan in widget.plans)
          PlanSelectionCard(
            plan: plan,
            selected: _selectedPlan == plan.code,
            cycle: _cycle,
            onTap: (plan.available && !widget.isProcessing)
                ? () => _selectPlan(plan.code)
                : null,
          ),
      ],
    );
  }
}

class _Handle extends StatelessWidget {
  final dynamic colors;
  const _Handle({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: colors.border.withOpacity(0.5),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final dynamic colors;
  final TextTheme textTheme;
  final String title;
  final String subtitle;

  const _Header({
    required this.colors,
    required this.textTheme,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(.10),
                shape: BoxShape.circle,
                border: Border.all(color: colors.primary.withOpacity(.18)),
              ),
              child: Icon(Icons.upgrade, color: colors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.label,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: colors.body),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final dynamic colors;
  final TextTheme textTheme;

  const _SectionLabel({
    required this.text,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        text,
        style: textTheme.bodySmall?.copyWith(
          color: colors.body,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  final String message;
  final dynamic colors;
  final TextTheme textTheme;

  const _InlineError({
    required this.message,
    required this.colors,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.error.withOpacity(.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withOpacity(.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePreview extends StatelessWidget {
  final PlanPricing pricing;
  final BillingCycle cycle;

  const _PricePreview({required this.pricing, required this.cycle});

  String _fmt(double n) {
    if (n == n.roundToDouble()) return n.toStringAsFixed(0);
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    final isYearly = cycle == BillingCycle.YEARLY;
    final currency = pricing.currency;
    final amount = isYearly ? pricing.effectiveYearlyPrice : pricing.monthlyPrice;
    final period = isYearly ? l10n.perYearSuffix : l10n.perMonthSuffix;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.upgradePriceLabel,
            style: textTheme.bodySmall?.copyWith(
              color: colors.body,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fmt(amount)} $currency',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.label,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  period,
                  style: textTheme.bodyMedium?.copyWith(color: colors.body),
                ),
              ),
            ],
          ),
          if (isYearly && pricing.hasYearlyDiscount) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  '${_fmt(pricing.yearlyPrice)} $currency',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.body,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.success.withOpacity(.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.success.withOpacity(.4)),
                  ),
                  child: Text(
                    pricing.discountLabel ??
                        (pricing.discountPercent != null
                            ? '-${pricing.discountPercent}%'
                            : l10n.upgradeYearlyDiscountBadge),
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentMethodList extends StatelessWidget {
  final List<AvailablePaymentMethod> methods;
  final String? selectedCode;
  final bool disabled;
  final ValueChanged<String> onSelected;

  const _PaymentMethodList({
    required this.methods,
    required this.selectedCode,
    required this.disabled,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        for (final method in methods)
          _PaymentMethodTile(
            method: method,
            selected: selectedCode == method.selectionCode,
            disabled: disabled,
            colors: colors,
            textTheme: textTheme,
            onTap: disabled ? null : () => onSelected(method.selectionCode),
          ),
      ],
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final AvailablePaymentMethod method;
  final bool selected;
  final bool disabled;
  final dynamic colors;
  final TextTheme textTheme;
  final VoidCallback? onTap;

  const _PaymentMethodTile({
    required this.method,
    required this.selected,
    required this.disabled,
    required this.colors,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withOpacity(.08)
                : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colors.primary.withOpacity(.35)
                  : colors.border.withOpacity(.20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? colors.primary : colors.body,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName.isNotEmpty
                          ? method.displayName
                          : method.typeName,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colors.label,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.typeName,
                      style: textTheme.bodySmall?.copyWith(color: colors.body),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
