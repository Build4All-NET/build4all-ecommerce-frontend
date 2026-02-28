import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/features/catalog/cubit/money.dart';

import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';
import '../utils/invoice_pdf.dart';

class OrderDetailsScreen extends StatelessWidget {
  final CheckoutSummaryModel summary;

  /// ✅ passed from checkout screen (so we can show name/phone/address)
  final ShippingAddress? address;
  final ShippingQuote? shipping;

  /// ✅ fallback names when backend returns itemName null in /checkout
  final Map<int, String>? itemNameById;

  const OrderDetailsScreen({
    super.key,
    required this.summary,
    this.address,
    this.shipping,
    this.itemNameById,
  });

  double _effectiveUnit(CheckoutLineSummaryModel l) {
    if (l.quantity <= 0) return l.unitPrice;
    return l.lineSubtotal / l.quantity;
  }

  String _lineName(CheckoutLineSummaryModel l) {
    final backendName = (l.itemName ?? '').trim();
    if (backendName.isNotEmpty) return backendName;

    final fallback = (itemNameById?[l.itemId] ?? '').trim();
    if (fallback.isNotEmpty) return fallback;

    return 'Item';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final code = (summary.orderCode ?? '').trim();
    final title =
        code.isNotEmpty ? 'Order $code' : l10n.orderDetailsTitle(summary.orderId);

    final totalTax = summary.itemTaxTotal + summary.shippingTaxTotal;

    final couponCode = (summary.couponCode ?? '').trim();
    final discount = summary.couponDiscount ?? 0.0;
    final showCoupon = couponCode.isNotEmpty;

    final dateValue = (summary.orderDate ?? '').trim();
    final shownDate = dateValue.isEmpty ? l10n.commonDash : dateValue;

    final a = address;
    final shipName = (shipping?.methodName ?? '').trim();
    final shipPrice = shipping?.price ?? 0.0;

    final receiverName = (a?.fullName ?? '').trim();
    final receiverPhone = (a?.phone ?? '').trim();
    final addressLine = (a?.addressLine ?? '').trim();
    final city = (a?.city ?? '').trim();
    final postal = (a?.postalCode ?? '').trim();
    final provider = (summary.paymentProviderCode ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Top info card
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kv('Date', shownDate),
                if (code.isNotEmpty) _kv('Order code', code),

                const SizedBox(height: 8),
                if (receiverName.isNotEmpty) _kv('Name', receiverName),
                if (receiverPhone.isNotEmpty) _kv('Phone', receiverPhone),
                if (addressLine.isNotEmpty) _kv('Address', addressLine),
                if (city.isNotEmpty) _kv('City', city),
                if (postal.isNotEmpty) _kv('Postal code', postal),

                const SizedBox(height: 8),
                if (shipName.isNotEmpty)
                  _kv('Shipping', '$shipName • ${money(context, shipPrice)}'),

                if (provider.isNotEmpty) _kv('Payment', provider),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            l10n.orderDetailsItemsTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          ...summary.lines.map((l) {
            final unit = _effectiveUnit(l);
            final name = _lineName(l); // ✅ FIXED

            return _card(
              marginBottom: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(
                          l10n.orderDetailsQtyUnitLine(
                            l.quantity,
                            money(context, unit),
                          ),
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    money(context, l.lineSubtotal),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 28),

          _row(context, l10n.orderDetailsSubtotal,
              money(context, summary.itemsSubtotal)),
          _row(context, l10n.orderDetailsShipping,
              money(context, summary.shippingTotal)),
          _row(context, l10n.orderDetailsTax, money(context, totalTax)),

          if (showCoupon)
            _row(
              context,
              l10n.orderDetailsCouponLine(couponCode),
              "-${money(context, discount)}",
            ),

          const SizedBox(height: 8),
          _row(
            context,
            l10n.orderDetailsGrandTotal,
            money(context, summary.grandTotal),
            bold: true,
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () async {
              final bytes = await InvoicePdf.build(
                summary,
                itemNameById: itemNameById,
              );

              final fileName =
                  code.isNotEmpty ? "invoice-$code.pdf" : "invoice-${summary.orderId}.pdf";

              await Printing.sharePdf(bytes: bytes, filename: fileName);
            },
            child: Text(l10n.orderDetailsDownloadInvoice),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child, double marginBottom = 0}) {
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(k, style: const TextStyle(color: Colors.black54))),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String left, String right,
      {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: style),
          Text(right, style: style),
        ],
      ),
    );
  }
}