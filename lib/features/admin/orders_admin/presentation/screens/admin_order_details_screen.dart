import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/features/invoices/presentation/mappers/admin_order_invoice_mapper.dart';
import 'package:build4front/features/invoices/presentation/utils/invoice_pdf.dart';

import '../../domain/entities/admin_order_entities.dart';
import '../../domain/repositories/admin_orders_repository.dart';
import '../../domain/usecases/get_admin_order_details.dart';
import '../bloc/admin_order_details_bloc.dart';
import '../bloc/admin_order_details_event.dart';
import '../bloc/admin_order_details_state.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final int orderId;

  const AdminOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  State<AdminOrderDetailsScreen> createState() =>
      _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  late final AdminOrderDetailsBloc _bloc;
  bool _changed = false;
  bool _downloadingInvoice = false;

  @override
  void initState() {
    super.initState();
    final repo = context.read<AdminOrdersRepository>();
    _bloc = AdminOrderDetailsBloc(
      getDetails: GetAdminOrderDetails(repo),
      repo: repo,
    )..add(AdminOrderDetailsStarted(widget.orderId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  void _toast(String msg, {bool error = false}) {
    final m = msg.trim();
    if (m.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (error) {
        AppToast.error(context, m);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(m)),
        );
      }
    });
  }

  Future<void> _downloadInvoice(OrderDetailsResponse data) async {
    try {
      setState(() => _downloadingInvoice = true);

      final invoice = AdminOrderInvoiceMapper.fromAdminOrder(data);
      final l10n = AppLocalizations.of(context)!;

      await InvoicePdf.share(
        invoice,
        labels: StandardInvoicePdfLabels(
          invoiceTitle: l10n.invoiceTitle,
          orderLabel: l10n.invoiceOrder,
          dateLabel: l10n.invoiceDate,
          providerLabel: l10n.commonProvider,
          statusLabel: l10n.commonStatus,
          refLabel: l10n.commonRef,
          itemsLabel: l10n.invoiceItems,
          itemLabel: l10n.commonItem,
          qtyLabel: l10n.commonQty,
          unitLabel: l10n.commonUnit,
          totalLabel: l10n.commonTotal,
          subtotalLabel: l10n.invoiceSubtotal,
          shippingLabel: l10n.invoiceShipping,
          taxLabel: l10n.invoiceTax,
          grandTotalLabel: l10n.invoiceGrandTotal,
          couponLine: (code) => l10n.invoiceCouponLine(code),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        AppLocalizations.of(context)!
            .adminOrderInvoiceDownloadFailed(e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() => _downloadingInvoice = false);
      }
    }
  }

  int? _tryInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  int? _extractItemId(OrderDetailsItem it) {
    final dynamic item = it.item;

    try {
      final v = item.id;
      final parsed = _tryInt(v);
      if (parsed != null) return parsed;
    } catch (_) {}

    return null;
  }

  int? _readOrderCountryId(OrderDetailsHeader o) {
    return o.shippingCountryId;
  }

  int? _readOrderRegionId(OrderDetailsHeader o) {
    return o.shippingRegionId;
  }

  bool _looksShippable(OrderDetailsResponse data) {
    final o = data.order;
    return o.shippingMethodId != null ||
        ((o.shippingAddress ?? '').trim().isNotEmpty) ||
        ((o.shippingCity ?? '').trim().isNotEmpty) ||
        ((o.shippingPhone ?? '').trim().isNotEmpty);
  }

  Future<void> _openEditOrderDialog(OrderDetailsResponse data) async {
    final o = data.order;
    final l10n = AppLocalizations.of(context)!;

    final fullNameCtrl = TextEditingController(text: o.shippingFullName ?? '');
    final phoneCtrl = TextEditingController(text: o.shippingPhone ?? '');
    final addressCtrl = TextEditingController(text: o.shippingAddress ?? '');
    final cityCtrl = TextEditingController(text: o.shippingCity ?? '');
    final postalCtrl = TextEditingController(text: o.shippingPostalCode ?? '');

    final qtyCtrls = <int, TextEditingController>{};

    for (final it in data.items) {
      final itemId = _extractItemId(it);
      if (itemId == null) continue;
      qtyCtrls[itemId] =
          TextEditingController(text: it.quantity.toString());
    }

    final countryId = _readOrderCountryId(o);
    final regionId = _readOrderRegionId(o);
    final shippingRequired = _looksShippable(data);

    if (shippingRequired && (countryId == null || o.shippingMethodId == null)) {
      _toast(l10n.adminOrderCannotEditMissingShipping, error: true);
      return;
    }

    final ok = await showDialog<bool>(
          context: context,
          builder: (_) {
            final tokens = context.read<ThemeCubit>().state.tokens;
            final colors = tokens.colors;
            final spacing = tokens.spacing;

            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                l10n.adminOrderEditTitle,
                style: tokens.typography.titleMedium.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.adminOrderEditRemoveHint,
                        style: tokens.typography.bodySmall.copyWith(
                          color: colors.muted,
                        ),
                      ),
                      SizedBox(height: spacing.md),
                      ...data.items.map((it) {
                        final itemId = _extractItemId(it);
                        if (itemId == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: EdgeInsets.only(bottom: spacing.sm),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.item.itemName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: tokens.typography.bodyMedium.copyWith(
                                    color: colors.label,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(width: spacing.sm),
                              SizedBox(
                                width: 90,
                                child: TextField(
                                  controller: qtyCtrls[itemId],
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: l10n.commonQty,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (shippingRequired) ...[
                        SizedBox(height: spacing.md),
                        TextField(
                          controller: fullNameCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.commonFullName,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        TextField(
                          controller: phoneCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.commonPhone,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        TextField(
                          controller: addressCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.commonAddress,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        TextField(
                          controller: cityCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.commonCity,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        TextField(
                          controller: postalCtrl,
                          decoration: InputDecoration(
                            labelText: l10n.commonPostalCode,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!ok) return;

    final lines = <Map<String, dynamic>>[];

    for (final it in data.items) {
      final itemId = _extractItemId(it);
      if (itemId == null) continue;

      final qty = int.tryParse(qtyCtrls[itemId]!.text.trim()) ?? 0;
      lines.add({
        'itemId': itemId,
        'quantity': qty,
      });
    }

    final body = <String, dynamic>{
      'lines': lines,
      if (shippingRequired)
        'shippingAddress': {
          'countryId': countryId,
          'regionId': regionId,
          'city': cityCtrl.text.trim(),
          'postalCode': postalCtrl.text.trim(),
          'shippingMethodId': o.shippingMethodId,
          'shippingMethodName': o.shippingMethodName,
          'addressLine': addressCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'fullName': fullNameCtrl.text.trim(),
        },
    };

    debugPrint('EDIT BODY => $body');

    if (!mounted) return;

    _bloc.add(
      AdminOrderEditRequested(
        orderId: o.id,
        body: body,
      ),
    );
  }

  Future<bool> _confirmAction({
    required BuildContext context,
    required String title,
    required String body,
    required Color confirmColor,
    required dynamic tokens,
    required dynamic colors,
    required dynamic spacing,
    String? confirmText,
    String? cancelText,
  }) async {
    final l10n = AppLocalizations.of(context)!;

    return (await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (_) {
            return AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                title,
                style: tokens.typography.titleMedium.copyWith(
                  color: colors.label,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text(
                body,
                style: tokens.typography.bodyMedium.copyWith(
                  color: colors.body,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    cancelText ?? l10n.commonCancel,
                    style: tokens.typography.bodyMedium.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: spacing.md,
                      vertical: spacing.sm,
                    ),
                  ),
                  child: Text(
                    confirmText ?? l10n.commonConfirm,
                    style: tokens.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            );
          },
        )) ??
        false;
  }

  String _statusLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'PENDING':
        return l10n.adminOrderStatusPending;
      case 'CANCEL_REQUESTED':
        return l10n.adminOrderStatusCancelRequested;
      case 'CANCELED':
        return l10n.adminOrderStatusCanceled;
      case 'REJECTED':
        return l10n.adminOrderStatusRejected;
      case 'REFUNDED':
        return l10n.adminOrderStatusRefunded;
      case 'COMPLETED':
        return l10n.adminOrderStatusCompleted;
      default:
        return code;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    final screenW = MediaQuery.sizeOf(context).width;
    final isWide = screenW >= 720;

    return BlocProvider.value(
      value: _bloc,
      child: WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _changed);
          return false;
        },
        child: Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context, _changed),
            ),
            title: BlocBuilder<AdminOrderDetailsBloc, AdminOrderDetailsState>(
              buildWhen: (p, c) =>
                  p.data?.order.orderCode != c.data?.order.orderCode,
              builder: (context, state) {
                final code = (state.data?.order.orderCode ?? '').trim();
                final title = code.isNotEmpty
                    ? '${l10n.invoiceOrder} $code'
                    : l10n.adminOrderDetailsTitle(widget.orderId);

                return Text(
                  title,
                  style: tokens.typography.titleMedium.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w900,
                  ),
                );
              },
            ),
          ),
          body: SafeArea(
            child: BlocConsumer<AdminOrderDetailsBloc, AdminOrderDetailsState>(
              listenWhen: (p, c) =>
                  p.error != c.error || p.message != c.message,
              listener: (context, state) {
                final err = (state.error ?? '').trim();
                if (err.isNotEmpty) {
                  _toast(err, error: true);
                  return;
                }

                final msg = (state.message ?? '').trim();
                if (msg.isNotEmpty) {
                  _changed = true;
                  _toast(msg);
                }
              },
              builder: (context, state) {
                if (state.loading && state.data == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = state.data;
                if (data == null) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(spacing.md),
                      child: Text(
                        state.error ?? l10n.adminOrderFailedToLoad,
                        style: tokens.typography.bodyMedium.copyWith(
                          color: colors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final o = data.order;

                final total = (o.payment.orderTotal <= 0)
                    ? o.totalPrice
                    : o.payment.orderTotal;
                final paid = o.payment.paidAmount;
                final progress =
                    total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

                final currencySymbol = (o.currency?.symbol ?? '').trim();

                String money(double v) {
                  final txt = v.toStringAsFixed(2);
                  return currencySymbol.isEmpty ? txt : '$currencySymbol$txt';
                }

                Color payColor() {
                  final p = o.payment.paymentState.toUpperCase();
                  if (p == 'PAID') return colors.success;
                  if (p == 'PARTIAL') return colors.primary;
                  if (p == 'UNPAID') return colors.danger;
                  return colors.muted;
                }

                final rawStatus = o.status.toUpperCase();
                final paymentState = o.payment.paymentState.toUpperCase();
                final paymentMethod = (o.paymentMethod ?? '').toUpperCase();
                final isCash = paymentMethod == 'CASH';
                final isRefunded = rawStatus == 'REFUNDED';

                final isPaid = paymentState == 'PAID' || o.fullyPaid == true;

                final canMarkCashPaid =
                    isCash && !isRefunded && paymentState != 'PAID';

                final canComplete =
                    isPaid && !isRefunded && rawStatus != 'COMPLETED';

                final canReject = !isPaid &&
                    (rawStatus == 'PENDING' ||
                        rawStatus == 'CANCEL_REQUESTED') &&
                    ![
                      'REJECTED',
                      'CANCELED',
                      'REFUNDED',
                      'COMPLETED',
                    ].contains(rawStatus);

                final canReopenAction =
                    !isRefunded && rawStatus != 'CANCELED';
                final canRestore =
                    !isRefunded && rawStatus == 'CANCELED';

                final canEdit = isCash &&
                    (rawStatus == 'PENDING' ||
                        rawStatus == 'CANCEL_REQUESTED');

                final phoneTxt = (o.shippingPhone ?? '').trim();
                final headerName = (o.shippingFullName ?? '').trim();

                final uniqueCustomers = data.items
                    .map((e) => e.user.fullName.trim())
                    .where((e) => e.isNotEmpty)
                    .toSet()
                    .toList();

                final fallbackPhone = (o.shippingPhone ?? '').trim();

                final customerDisplay = headerName.isNotEmpty
                    ? headerName
                    : uniqueCustomers.isEmpty
                        ? (fallbackPhone.isNotEmpty ? fallbackPhone : '—')
                        : uniqueCustomers.length == 1
                            ? uniqueCustomers.first
                            : '${uniqueCustomers.first} (+${uniqueCustomers.length - 1})';

                final orderCode = (o.orderCode ?? '').trim();
                final orderSeq = o.orderSeq;

                Widget paymentCard() {
                  return Container(
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius:
                          BorderRadius.circular(tokens.card.radius),
                      border: Border.all(
                        color: colors.border.withOpacity(0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.adminPaymentSummary,
                                style:
                                    tokens.typography.titleMedium.copyWith(
                                  color: colors.label,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.sm,
                                vertical: spacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: payColor().withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(999),
                                border: Border.all(
                                  color: payColor().withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                o.payment.paymentState,
                                style:
                                    tokens.typography.bodySmall.copyWith(
                                  color: payColor(),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor:
                                colors.border.withOpacity(0.25),
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        _kv(tokens, colors, l10n.adminOrderTotal, money(total)),
                        _kv(tokens, colors, l10n.adminPaid, money(o.payment.paidAmount)),
                        if (!o.fullyPaid)
                          _kv(
                            tokens,
                            colors,
                            l10n.adminRemaining,
                            money(o.payment.remainingAmount),
                          ),
                        if (canMarkCashPaid) ...[
                          SizedBox(height: spacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: state.updating
                                      ? null
                                      : () async {
                                          final ok =
                                              await _confirmAction(
                                            context: context,
                                            title: l10n.adminMarkCashPaidTitle,
                                            body: l10n.adminMarkCashPaidBody,
                                            confirmColor: colors.success,
                                            tokens: tokens,
                                            colors: colors,
                                            spacing: spacing,
                                            confirmText: l10n.commonConfirm,
                                            cancelText: l10n.commonCancel,
                                          );
                                          if (!ok) return;

                                          _bloc.add(
                                            AdminOrderMarkCashPaidRequested(
                                              orderId: o.id,
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.success,
                                    foregroundColor: colors.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.md,
                                      vertical: spacing.sm,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  label: Text(
                                    l10n.adminMarkCashPaidButton,
                                    style: tokens.typography.bodyMedium
                                        .copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              if (state.updating) ...[
                                SizedBox(width: spacing.sm),
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }

                Widget orderInfoCard() {
                  return Container(
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius:
                          BorderRadius.circular(tokens.card.radius),
                      border: Border.all(
                        color: colors.border.withOpacity(0.22),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminOrderInfo,
                          style: tokens.typography.titleMedium.copyWith(
                            color: colors.label,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        Row(
                          children: [
                            Text(
                              '${l10n.adminStatus}: ',
                              style:
                                  tokens.typography.bodyMedium.copyWith(
                                color: colors.body,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.sm,
                                vertical: spacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.12),
                                borderRadius:
                                    BorderRadius.circular(999),
                                border: Border.all(
                                  color: colors.primary.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                _statusLabel(l10n, rawStatus),
                                style:
                                    tokens.typography.bodySmall.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.md),
                        if (orderCode.isNotEmpty)
                          _kv(
                            tokens,
                            colors,
                            l10n.orderDetailsOrderCode,
                            orderCode,
                          ),
                        if (orderSeq != null)
                          _kv(
                            tokens,
                            colors,
                            l10n.adminOrderSequenceLabel,
                            '$orderSeq',
                          ),
                        if (orderCode.isNotEmpty || orderSeq != null)
                          _kv(
                            tokens,
                            colors,
                            l10n.adminOrderInternalIdLabel,
                            '#${o.id}',
                          ),
                        _kv(
                          tokens,
                          colors,
                          l10n.commonCustomer,
                          customerDisplay,
                        ),
                        if (phoneTxt.isNotEmpty && customerDisplay != phoneTxt)
                          _kv(
                            tokens,
                            colors,
                            l10n.commonPhone,
                            phoneTxt,
                          ),
                        if ((o.shippingAddress ?? '').trim().isNotEmpty)
                          _kv(
                            tokens,
                            colors,
                            l10n.commonAddress,
                            o.shippingAddress!.trim(),
                          ),
                        if ((o.shippingCity ?? '').trim().isNotEmpty)
                          _kv(
                            tokens,
                            colors,
                            l10n.commonCity,
                            o.shippingCity!.trim(),
                          ),
                        if ((o.shippingPostalCode ?? '').trim().isNotEmpty)
                          _kv(
                            tokens,
                            colors,
                            l10n.commonPostalCode,
                            o.shippingPostalCode!.trim(),
                          ),
                        if ((o.paymentMethod ?? '').trim().isNotEmpty)
                          _kv(
                            tokens,
                            colors,
                            l10n.adminPaymentMethodLabel,
                            o.paymentMethod!.trim(),
                          ),
                        if (canEdit) ...[
                          SizedBox(height: spacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: state.updating
                                  ? null
                                  : () => _openEditOrderDialog(data),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text(
                                l10n.adminOrderEditTitle,
                                style:
                                    tokens.typography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: spacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _downloadingInvoice
                                ? null
                                : () => _downloadInvoice(data),
                            icon: _downloadingInvoice
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.picture_as_pdf_outlined,
                                  ),
                            label: Text(
                              l10n.orderDetailsDownloadInvoice,
                            ),
                          ),
                        ),
                        if (canComplete) ...[
                          SizedBox(height: spacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: state.updating
                                      ? null
                                      : () async {
                                          final ok =
                                              await _confirmAction(
                                            context: context,
                                            title: l10n.adminOrderCompleteTitle,
                                            body: l10n.adminOrderCompleteBody,
                                            confirmColor: colors.success,
                                            tokens: tokens,
                                            colors: colors,
                                            spacing: spacing,
                                            confirmText:
                                                l10n.adminOrderComplete,
                                            cancelText:
                                                l10n.commonCancel,
                                          );
                                          if (!ok) return;

                                          _bloc.add(
                                            AdminOrderStatusUpdateRequested(
                                              orderId: o.id,
                                              status: 'COMPLETED',
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.success,
                                    foregroundColor: colors.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.md,
                                      vertical: spacing.sm,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.verified),
                                  label: Text(
                                    l10n.adminOrderComplete,
                                    style: tokens.typography.bodyMedium
                                        .copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              if (state.updating) ...[
                                SizedBox(width: spacing.sm),
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (canReopenAction) ...[
                          SizedBox(height: spacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: state.updating
                                      ? null
                                      : () async {
                                          final ok =
                                              await _confirmAction(
                                            context: context,
                                            title:
                                                l10n.adminOrderReopenTitle,
                                            body:
                                                l10n.adminOrderReopenBody,
                                            confirmColor: colors.danger,
                                            tokens: tokens,
                                            colors: colors,
                                            spacing: spacing,
                                            confirmText:
                                                l10n.adminOrderReopen,
                                            cancelText:
                                                l10n.commonCancel,
                                          );
                                          if (!ok) return;

                                          _bloc.add(
                                            AdminOrderReopenRequested(
                                              orderId: o.id,
                                            ),
                                          );
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.danger,
                                    side: BorderSide(
                                      color: colors.danger
                                          .withOpacity(0.45),
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.md,
                                      vertical: spacing.sm,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.restart_alt),
                                  label: Text(
                                    l10n.adminOrderReopen,
                                    style: tokens.typography.bodyMedium
                                        .copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              if (state.updating) ...[
                                SizedBox(width: spacing.sm),
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        if (canRestore) ...[
                          SizedBox(height: spacing.md),
                          OutlinedButton.icon(
                            onPressed: state.updating
                                ? null
                                : () async {
                                    final ok = await _confirmAction(
                                      context: context,
                                      title:
                                          l10n.adminOrderRestoreTitle,
                                      body:
                                          l10n.adminOrderRestoreBody,
                                      confirmColor: colors.primary,
                                      tokens: tokens,
                                      colors: colors,
                                      spacing: spacing,
                                      confirmText:
                                          l10n.adminOrderRestore,
                                      cancelText:
                                          l10n.commonCancel,
                                    );
                                    if (!ok) return;

                                    _bloc.add(
                                      AdminOrderStatusUpdateRequested(
                                        orderId: o.id,
                                        status: 'PENDING',
                                      ),
                                    );
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.primary,
                              side: BorderSide(
                                color:
                                    colors.primary.withOpacity(0.45),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.md,
                                vertical: spacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.undo),
                            label: Text(
                              l10n.adminOrderRestore,
                              style: tokens.typography.bodyMedium
                                  .copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                        if (canReject) ...[
                          SizedBox(height: spacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: state.updating
                                      ? null
                                      : () async {
                                          final ok =
                                              await _confirmAction(
                                            context: context,
                                            title:
                                                l10n.adminRejectOrderTitle,
                                            body:
                                                l10n.adminRejectOrderBody,
                                            confirmColor: colors.danger,
                                            tokens: tokens,
                                            colors: colors,
                                            spacing: spacing,
                                            confirmText:
                                                l10n.commonConfirm,
                                            cancelText:
                                                l10n.commonCancel,
                                          );
                                          if (!ok) return;

                                          _bloc.add(
                                            AdminOrderStatusUpdateRequested(
                                              orderId: o.id,
                                              status: 'REJECTED',
                                            ),
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.danger,
                                    foregroundColor: colors.onPrimary,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.md,
                                      vertical: spacing.sm,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.block),
                                  label: Text(
                                    l10n.adminRejectOrderButton,
                                    style: tokens.typography.bodyMedium
                                        .copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              if (state.updating) ...[
                                SizedBox(width: spacing.sm),
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }

                Widget itemsHeader() {
                  return Text(
                    l10n.adminItemsCount(data.itemsCount),
                    style: tokens.typography.titleMedium.copyWith(
                      color: colors.label,
                      fontWeight: FontWeight.w900,
                    ),
                  );
                }

                Widget itemImage(OrderDetailsItem it) {
                  final url = it.item.imageUrl?.trim();

                  Widget placeholder() {
                    return Container(
                      color: colors.border.withOpacity(0.18),
                      child: Icon(
                        Icons.image_outlined,
                        color: colors.muted,
                        size: 22,
                      ),
                    );
                  }

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: (url == null || url.isEmpty)
                          ? placeholder()
                          : Image.network(
                              url,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color:
                                      colors.border.withOpacity(0.12),
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: progress
                                                      .expectedTotalBytes !=
                                                  null &&
                                              progress.expectedTotalBytes! >
                                                  0
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) =>
                                  placeholder(),
                            ),
                    ),
                  );
                }

                Widget itemCard(OrderDetailsItem it) {
                  final itemTotal = it.price * it.quantity;

                  return Container(
                    padding: EdgeInsets.all(spacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius:
                          BorderRadius.circular(tokens.card.radius),
                      border: Border.all(
                        color: colors.border.withOpacity(0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        itemImage(it),
                        SizedBox(width: spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.item.itemName,
                                style: tokens.typography.bodyMedium
                                    .copyWith(
                                  color: colors.label,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: spacing.xs),
                              if ((it.item.location ?? '')
                                  .trim()
                                  .isNotEmpty)
                                Text(
                                  it.item.location!.trim(),
                                  style: tokens.typography.bodySmall
                                      .copyWith(
                                    color: colors.muted,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                l10n.adminQtyPriceLine(
                                  it.quantity,
                                  money(it.price),
                                ),
                                style: tokens.typography.bodySmall
                                    .copyWith(
                                  color: colors.muted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: spacing.sm),
                        Text(
                          money(itemTotal),
                          style: tokens.typography.bodyMedium.copyWith(
                            color: colors.label,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                Widget itemsList() {
                  if (!isWide) {
                    return Column(
                      children: data.items
                          .map(
                            (it) => Padding(
                              padding:
                                  EdgeInsets.only(bottom: spacing.sm),
                              child: itemCard(it),
                            ),
                          )
                          .toList(),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final crossAxisCount = w >= 1024 ? 2 : 1;

                      const cardHeight = 92.0;
                      final cardWidth =
                          (w - (crossAxisCount - 1) * spacing.sm) /
                              crossAxisCount;
                      final aspect = cardWidth / cardHeight;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: data.items.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing.sm,
                          crossAxisSpacing: spacing.sm,
                          childAspectRatio: aspect.clamp(2.8, 6.0),
                        ),
                        itemBuilder: (_, idx) =>
                            itemCard(data.items[idx]),
                      );
                    },
                  );
                }

                return ListView(
                  padding: EdgeInsets.all(spacing.md),
                  children: [
                    if (isWide)
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(child: paymentCard()),
                          SizedBox(width: spacing.md),
                          Expanded(child: orderInfoCard()),
                        ],
                      )
                    else ...[
                      paymentCard(),
                      SizedBox(height: spacing.md),
                      orderInfoCard(),
                    ],
                    SizedBox(height: spacing.md),
                    itemsHeader(),
                    SizedBox(height: spacing.sm),
                    itemsList(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(dynamic tokens, dynamic colors, String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              k,
              style: tokens.typography.bodySmall.copyWith(
                color: colors.muted,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: tokens.typography.bodySmall.copyWith(
                color: colors.label,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}