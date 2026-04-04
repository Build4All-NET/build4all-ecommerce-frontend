import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/exceptions/exception_mapper.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/core/network/globals.dart' as g;
import 'package:build4front/l10n/app_localizations.dart';

import 'package:build4front/features/invoices/presentation/mappers/user_order_invoice_mapper.dart';
import 'package:build4front/features/invoices/presentation/utils/invoice_pdf.dart';

import '../../data/services/orders_api_service.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool loading = true;
  bool downloadingInvoice = false;
  String? error;

  Map<String, dynamic>? order;
  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _absUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;

    final root = (g.appServerRoot ?? '').trim();
    if (root.isEmpty) return u;

    if (root.endsWith('/') && u.startsWith('/')) {
      return root.substring(0, root.length - 1) + u;
    }
    if (!root.endsWith('/') && !u.startsWith('/')) return '$root/$u';
    return root + u;
  }

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  String _msg(Object e, {String? fallback}) {
    final mapped = ExceptionMapper.toMessage(e).trim();
    if (mapped.isNotEmpty && mapped != 'Something went wrong.') {
      return mapped;
    }
    return fallback ?? 'Something went wrong. Please try again.';
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = context.read<OrdersApiService>();
      final raw = await api.getOrderDetailsRaw(widget.orderId);

      final o = raw['order'];
      final list = raw['items'];

      setState(() {
        order = (o is Map) ? o.cast<String, dynamic>() : null;
        items = (list is List)
            ? list.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
            : [];
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = ExceptionMapper.toMessage(e);
        loading = false;
      });
    }
  }

  Future<void> _downloadInvoice() async {
    if (order == null) return;

    final l10n = AppLocalizations.of(context)!;

    try {
      setState(() => downloadingInvoice = true);

      final invoice = UserOrderInvoiceMapper.fromRaw(
        order: order!,
        items: items,
      );

      await InvoicePdf.share(invoice);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _msg(
              e,
              fallback: '${l10n.orderDetailsDownloadInvoice} failed.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => downloadingInvoice = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;

    final code = (order?['orderCode'] ?? '').toString().trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ordersDetailsTitle(code)),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Text(
                      error!,
                      style: tokens.typography.bodyMedium.copyWith(
                        color: colors.danger,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(spacing.md),
                    children: [
                      if (order != null) ...[
                        _HeaderCard(order: order!, money: _money),
                        SizedBox(height: spacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: downloadingInvoice ? null : _downloadInvoice,
                            icon: downloadingInvoice
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.picture_as_pdf_outlined),
                            label: Text(l10n.orderDetailsDownloadInvoice),
                          ),
                        ),
                        SizedBox(height: spacing.md),
                      ],
                      Text(
                        l10n.ordersDetailsItemsTitle,
                        style: tokens.typography.titleMedium.copyWith(
                          color: colors.label,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: spacing.sm),
                      ...items.map((row) {
                        final item = (row['item'] is Map)
                            ? (row['item'] as Map).cast<String, dynamic>()
                            : <String, dynamic>{};

                        final name = (item['itemName'] ?? 'Item').toString();
                        final img = _absUrl(item['imageUrl']?.toString());

                        final qty = _toInt(row['quantity']);
                        final unitPrice = _toDouble(
                          row['unitPrice'],
                          fallback: _toDouble(row['price']),
                        );
                        final lineTotal = _toDouble(
                          row['lineTotal'],
                          fallback: unitPrice * qty,
                        );

                        return Container(
                          margin: EdgeInsets.only(bottom: spacing.sm),
                          padding: EdgeInsets.all(tokens.card.padding),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(tokens.card.radius),
                            border: Border.all(
                              color: colors.border.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 62,
                                  height: 62,
                                  color: colors.background,
                                  child: img.isEmpty
                                      ? Icon(
                                          Icons.image_not_supported_outlined,
                                          color: colors.muted,
                                        )
                                      : Image.network(
                                          img,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.broken_image_outlined,
                                            color: colors.muted,
                                          ),
                                        ),
                                ),
                              ),
                              SizedBox(width: spacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: tokens.typography.bodyMedium.copyWith(
                                        color: colors.label,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: spacing.xs),
                                    Text(
                                      '${l10n.ordersDetailsQty}: $qty',
                                      style: tokens.typography.bodySmall.copyWith(
                                        color: colors.muted,
                                      ),
                                    ),
                                    SizedBox(height: spacing.xs),
                                    Wrap(
                                      spacing: spacing.sm,
                                      runSpacing: spacing.xs,
                                      children: [
                                        Text(
                                          '${l10n.ordersDetailsUnit}: ${_money(unitPrice)}',
                                          style: tokens.typography.bodySmall.copyWith(
                                            color: colors.body,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          '•',
                                          style: tokens.typography.bodySmall.copyWith(
                                            color: colors.muted,
                                          ),
                                        ),
                                        Text(
                                          '${l10n.ordersDetailsLineTotal}: ${_money(lineTotal)}',
                                          style: tokens.typography.bodySmall.copyWith(
                                            color: colors.body,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String Function(double) money;

  const _HeaderCard({
    required this.order,
    required this.money,
  });

  double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = context.watch<ThemeCubit>().state.tokens;
    final colors = t.colors;
    final spacing = t.spacing;

    final statusUi = (order['orderStatusUi'] ?? order['orderStatus'] ?? '').toString();
    final total = _toDouble(order['totalPrice']);
    final paid = order['fullyPaid'] == true;

    final payment = (order['payment'] is Map)
        ? (order['payment'] as Map).cast<String, dynamic>()
        : null;
    final paidAmount = _toDouble(payment?['paidAmount']);
    final remaining = _toDouble(payment?['remainingAmount']);
    final paymentState = (payment?['paymentState'] ?? '').toString();

    return Container(
      padding: EdgeInsets.all(t.card.padding),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(t.card.radius),
        border: Border.all(color: colors.border.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.ordersDetailsStatus}: $statusUi',
            style: t.typography.bodyMedium.copyWith(color: colors.body),
          ),
          SizedBox(height: spacing.xs),
          Text(
            '${l10n.ordersDetailsOrderTotal}: ${money(total)}',
            style: t.typography.bodyMedium.copyWith(
              color: colors.label,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            paid ? l10n.ordersPaid : l10n.ordersUnpaid,
            style: t.typography.bodySmall.copyWith(
              color: paid ? colors.success : colors.muted,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (paymentState.isNotEmpty) ...[
            SizedBox(height: spacing.xs),
            Text(
              '${l10n.ordersDetailsPayment}: $paymentState • '
              '${l10n.ordersDetailsPaidAmount}: ${money(paidAmount)} • '
              '${l10n.ordersDetailsRemaining}: ${money(remaining)}',
              style: t.typography.bodySmall.copyWith(color: colors.muted),
            ),
          ],
        ],
      ),
    );
  }
}