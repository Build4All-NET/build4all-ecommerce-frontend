import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/l10n/app_localizations.dart';

import '../../domain/entities/admin_order_entities.dart';
import '../../domain/repositories/admin_orders_repository.dart';
import '../../domain/usecases/get_admin_order_details.dart';
import '../bloc/admin_order_details_bloc.dart';
import '../bloc/admin_order_details_event.dart';
import '../bloc/admin_order_details_state.dart';

class AdminOrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const AdminOrderDetailsScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailsScreen> createState() => _AdminOrderDetailsScreenState();
}

class _AdminOrderDetailsScreenState extends State<AdminOrderDetailsScreen> {
  late final AdminOrderDetailsBloc _bloc;
  bool _changed = false;

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
      AppToast.error(context, m);
    });
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
                    cancelText ?? 'Cancel',
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
                    confirmText ?? 'Confirm',
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
              buildWhen: (p, c) => p.data?.order.orderCode != c.data?.order.orderCode,
              builder: (context, state) {
                final code = (state.data?.order.orderCode ?? '').trim();
                final title = code.isNotEmpty
                    ? 'Order $code'
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
              listenWhen: (p, c) => p.error != c.error || p.message != c.message,
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

                final total =
                    (o.payment.orderTotal <= 0) ? o.totalPrice : o.payment.orderTotal;
                final paid = o.payment.paidAmount;
                final progress = total <= 0 ? 0.0 : (paid / total).clamp(0.0, 1.0);

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

                final rawStatus = (o.status).toUpperCase();
                final paymentState = o.payment.paymentState.toUpperCase();
                final paymentMethod = (o.paymentMethod ?? '').toUpperCase();
                final isCash = paymentMethod == 'CASH';
                final isRefunded = rawStatus == 'REFUNDED';

                final isPaid = paymentState == 'PAID' || o.fullyPaid == true;

                // ✅ IMPORTANT: allow marking CASH paid even if status is CANCELED
                // Only block if REFUNDED.
                final canMarkCashPaid = isCash && !isRefunded && paymentState != 'PAID';

                // ✅ If paid but not completed, allow completing even if status is CANCELED.
                final canComplete = isPaid && !isRefunded && rawStatus != 'COMPLETED';

                // Reject is only allowed when NOT paid and in pending-ish states
                final canReject = !isPaid &&
                    (rawStatus == 'PENDING' || rawStatus == 'CANCEL_REQUESTED') &&
                    !['REJECTED', 'CANCELED', 'REFUNDED', 'COMPLETED'].contains(rawStatus);

                // Your "reopen" action currently cancels + unpays (backend behavior)
                // So don't show it if already canceled/refunded.
                final canReopenAction = !isRefunded && rawStatus != 'CANCELED';

                // Restore is optional control: allow moving canceled back to pending
                final canRestore = !isRefunded && rawStatus == 'CANCELED';

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
                      borderRadius: BorderRadius.circular(tokens.card.radius),
                      border: Border.all(color: colors.border.withOpacity(0.22)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.adminPaymentSummary,
                                style: tokens.typography.titleMedium.copyWith(
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
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: payColor().withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                o.payment.paymentState,
                                style: tokens.typography.bodySmall.copyWith(
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
                            backgroundColor: colors.border.withOpacity(0.25),
                          ),
                        ),
                        SizedBox(height: spacing.sm),
                        _kv(tokens, colors, l10n.adminOrderTotal, money(total)),
                        _kv(tokens, colors, l10n.adminPaid, money(o.payment.paidAmount)),
                        if (!o.fullyPaid)
                          _kv(tokens, colors, l10n.adminRemaining,
                              money(o.payment.remainingAmount)),

                        // ✅ Mark CASH Paid stays visible even if status is CANCELED
                        if (canMarkCashPaid) ...[
                          SizedBox(height: spacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: state.updating
                                      ? null
                                      : () async {
                                          final ok = await _confirmAction(
                                            context: context,
                                            title: l10n.adminMarkCashPaidTitle,
                                            body: l10n.adminMarkCashPaidBody,
                                            confirmColor: colors.success,
                                            tokens: tokens,
                                            colors: colors,
                                            spacing: spacing,
                                            confirmText: l10n.confirm,
                                            cancelText: l10n.cancel,
                                          );
                                          if (!ok) return;

                                          context.read<AdminOrderDetailsBloc>().add(
                                                AdminOrderMarkCashPaidRequested(
                                                    orderId: o.id),
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
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check_circle_outline),
                                  label: Text(
                                    l10n.adminMarkCashPaidButton,
                                    style: tokens.typography.bodyMedium.copyWith(
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                      borderRadius: BorderRadius.circular(tokens.card.radius),
                      border: Border.all(color: colors.border.withOpacity(0.22)),
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
                              style: tokens.typography.bodyMedium.copyWith(
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
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: colors.primary.withOpacity(0.35),
                                ),
                              ),
                              child: Text(
                                _statusLabel(l10n, rawStatus),
                                style: tokens.typography.bodySmall.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: spacing.md),

                        if (orderCode.isNotEmpty) _kv(tokens, colors, 'Order Code', orderCode),
                        if (orderSeq != null) _kv(tokens, colors, 'Order Seq', '$orderSeq'),
                        if (orderCode.isNotEmpty || orderSeq != null)
                          _kv(tokens, colors, 'Internal ID', '#${o.id}'),

                        _kv(tokens, colors, 'Customer', customerDisplay),

                        if (phoneTxt.isNotEmpty && customerDisplay != phoneTxt)
                          _kv(tokens, colors, 'Phone', phoneTxt),
                        if ((o.shippingAddress ?? '').trim().isNotEmpty)
                          _kv(tokens, colors, 'Address', o.shippingAddress!.trim()),
                        if ((o.shippingCity ?? '').trim().isNotEmpty)
                          _kv(tokens, colors, 'City', o.shippingCity!.trim()),
                        if ((o.shippingPostalCode ?? '').trim().isNotEmpty)
                          _kv(tokens, colors, 'Postal Code', o.shippingPostalCode!.trim()),
                        if ((o.paymentMethod ?? '').trim().isNotEmpty)
                          _kv(tokens, colors, 'Payment Method', o.paymentMethod!.trim()),

                        // ✅ Mark Completed available even if status is CANCELED (your "control")
                        if (canComplete) ...[
                          SizedBox(height: spacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: state.updating
                                      ? null
                                      : () async {
                                          final ok = await _confirmAction(
                                            context: context,
                                            title: 'Mark Completed',
                                            body: 'This will mark the order as completed.',
                                            confirmColor: colors.success,
                                            tokens: tokens,
                                            colors: colors,
                                            spacing: spacing,
                                            confirmText: 'Complete',
                                            cancelText: l10n.cancel,
                                          );
                                          if (!ok) return;

                                          context.read<AdminOrderDetailsBloc>().add(
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
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.verified),
                                  label: Text(
                                    'Mark Completed',
                                    style: tokens.typography.bodyMedium.copyWith(
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ],
                            ],
                          ),
                        ],

                        // ✅ "Reopen" button (your backend makes it: CANCELED + UNPAID)
                        if (canReopenAction) ...[
                          SizedBox(height: spacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: state.updating
                                      ? null
                                      : () async {
                                          final ok = await _confirmAction(
                                            context: context,
                                            title: 'Reopen (Cancel + Unpay)',
                                            body: 'This will cancel the order and reset payment back to UNPAID.',
                                            confirmColor: colors.danger,
                                            tokens: tokens,
                                            colors: colors,
                                            spacing: spacing,
                                            confirmText: 'Reopen',
                                            cancelText: l10n.cancel,
                                          );
                                          if (!ok) return;

                                          context.read<AdminOrderDetailsBloc>().add(
                                                AdminOrderReopenRequested(orderId: o.id),
                                              );
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: colors.danger,
                                    side: BorderSide(color: colors.danger.withOpacity(0.45)),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: spacing.md,
                                      vertical: spacing.sm,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.restart_alt),
                                  label: Text(
                                    'Reopen',
                                    style: tokens.typography.bodyMedium.copyWith(
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ],
                            ],
                          ),
                        ],

                        // ✅ Restore canceled order back to Pending (optional but gives you control)
                        if (canRestore) ...[
                          SizedBox(height: spacing.md),
                          OutlinedButton.icon(
                            onPressed: state.updating
                                ? null
                                : () async {
                                    final ok = await _confirmAction(
                                      context: context,
                                      title: 'Restore to Pending',
                                      body: 'This will restore the order back to Pending.',
                                      confirmColor: colors.primary,
                                      tokens: tokens,
                                      colors: colors,
                                      spacing: spacing,
                                      confirmText: 'Restore',
                                      cancelText: l10n.cancel,
                                    );
                                    if (!ok) return;

                                    context.read<AdminOrderDetailsBloc>().add(
                                          AdminOrderStatusUpdateRequested(
                                            orderId: o.id,
                                            status: 'PENDING',
                                          ),
                                        );
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.primary,
                              side: BorderSide(color: colors.primary.withOpacity(0.45)),
                              padding: EdgeInsets.symmetric(
                                horizontal: spacing.md,
                                vertical: spacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.undo),
                            label: Text(
                              'Restore to Pending',
                              style: tokens.typography.bodyMedium.copyWith(
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
                                          final ok = await _confirmAction(
                                            context: context,
                                            title: l10n.adminRejectOrderTitle,
                                            body: l10n.adminRejectOrderBody,
                                            confirmColor: colors.danger,
                                            tokens: tokens,
                                            colors: colors,
                                            spacing: spacing,
                                            confirmText: l10n.confirm,
                                            cancelText: l10n.cancel,
                                          );
                                          if (!ok) return;

                                          context.read<AdminOrderDetailsBloc>().add(
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
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.block),
                                  label: Text(
                                    l10n.adminRejectOrderButton,
                                    style: tokens.typography.bodyMedium.copyWith(
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
                                  child: CircularProgressIndicator(strokeWidth: 2),
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
                      child: Icon(Icons.image_outlined, color: colors.muted, size: 22),
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
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  color: colors.border.withOpacity(0.12),
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: progress.expectedTotalBytes != null &&
                                              progress.expectedTotalBytes! > 0
                                          ? progress.cumulativeBytesLoaded /
                                              progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => placeholder(),
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
                      borderRadius: BorderRadius.circular(tokens.card.radius),
                      border: Border.all(color: colors.border.withOpacity(0.22)),
                    ),
                    child: Row(
                      children: [
                        itemImage(it),
                        SizedBox(width: spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.item.itemName,
                                style: tokens.typography.bodyMedium.copyWith(
                                  color: colors.label,
                                  fontWeight: FontWeight.w800,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: spacing.xs),
                              if ((it.item.location ?? '').trim().isNotEmpty)
                                Text(
                                  it.item.location!.trim(),
                                  style: tokens.typography.bodySmall.copyWith(
                                      color: colors.muted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              Text(
                                l10n.adminQtyPriceLine(it.quantity, money(it.price)),
                                style: tokens.typography.bodySmall.copyWith(
                                    color: colors.muted),
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
                          .map((it) => Padding(
                                padding: EdgeInsets.only(bottom: spacing.sm),
                                child: itemCard(it),
                              ))
                          .toList(),
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final crossAxisCount = w >= 1024 ? 2 : 1;

                      const cardHeight = 92.0;
                      final cardWidth =
                          (w - (crossAxisCount - 1) * spacing.sm) / crossAxisCount;
                      final aspect = cardWidth / cardHeight;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: data.items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: spacing.sm,
                          crossAxisSpacing: spacing.sm,
                          childAspectRatio: aspect.clamp(2.8, 6.0),
                        ),
                        itemBuilder: (_, idx) => itemCard(data.items[idx]),
                      );
                    },
                  );
                }

                return ListView(
                  padding: EdgeInsets.all(spacing.md),
                  children: [
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
              style: tokens.typography.bodySmall.copyWith(color: colors.muted),
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