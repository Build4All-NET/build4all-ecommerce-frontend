import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class InvoicePdf {
  static Future<Uint8List> build(
    CheckoutSummaryModel s, {
    String? fallbackSymbol,
    String? title,
    Map<int, String>? itemNameById, // ✅ NEW
  }) async {
    pw.ThemeData? theme;
    try {
      final base = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoNaskhArabic-Regular.ttf'),
      );
      final bold = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoNaskhArabic-Bold.ttf'),
      );
      theme = pw.ThemeData.withFont(base: base, bold: bold);
    } catch (_) {
      theme = null; // will fallback to Helvetica
    }

    final doc = pw.Document(theme: theme);

    final sym = _pickSymbol(s.currencySymbol, fallbackSymbol);
    String money(num v) => _formatMoney(v, sym);

    final totalTax = s.itemTaxTotal + s.shippingTaxTotal;

    final couponCode = (s.couponCode ?? '').trim();
    final discount = s.couponDiscount ?? 0.0;
    final showCoupon = couponCode.isNotEmpty;

    final orderCode = (s.orderCode ?? '').trim();
    final providerPaymentId = (s.providerPaymentId ?? '').trim();
    final shownOrderCode = orderCode.isNotEmpty
        ? orderCode
        : (providerPaymentId.isNotEmpty ? providerPaymentId : '—');

    final dateText = _formatDateSafe(s.orderDate);

    final provider = (s.paymentProviderCode ?? '').trim();
    final paymentStatus = (s.paymentStatus ?? '').trim();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (ctx) {
          final w = ctx.page.pageFormat.availableWidth;
          final leftW = w * 0.62;
          final rightW = w - leftW;

          pw.Widget kvLine(String k, String v, {bool bold = false}) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Table(
                columnWidths: const {
                  0: pw.FixedColumnWidth(85),
                  1: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text(
                        k,
                        style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        v,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          pw.Widget totalsRow(String l, String r, {bool bold = false}) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(l,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      )),
                  pw.Text(r,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                      )),
                ],
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ✅ Header as TABLE (no flex crash)
              pw.Table(
                columnWidths: {
                  0: pw.FixedColumnWidth(leftW),
                  1: pw.FixedColumnWidth(rightW),
                },
                children: [
                  pw.TableRow(
                    verticalAlignment: pw.TableCellVerticalAlignment.top,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.only(right: 12),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              (title ?? 'INVOICE').toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            kvLine('Order', shownOrderCode, bold: true),
                            kvLine('Date', dateText),
                          ],
                        ),
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: pw.BorderRadius.circular(10),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            kvLine('Provider', provider.isEmpty ? '—' : provider),
                            kvLine('Status', paymentStatus.isEmpty ? '—' : paymentStatus),
                            kvLine('Ref', providerPaymentId.isEmpty ? '—' : providerPaymentId),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 14),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 10),

              pw.Text(
                'Items',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 8),

              pw.Table.fromTextArray(
                headers: const ['Item', 'Qty', 'Unit', 'Total'],
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(0.8),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.2),
                },
                data: s.lines.map((l) {
                  final backendName = (l.itemName ?? '').trim();
                  final fallback = (itemNameById?[l.itemId] ?? '').trim();

                  final name = backendName.isNotEmpty
                      ? backendName
                      : (fallback.isNotEmpty ? fallback : 'Item');

                  final effectiveUnit = (l.quantity <= 0)
                      ? l.unitPrice
                      : (l.lineSubtotal / l.quantity);

                  return [
                    name,
                    l.quantity.toString(),
                    money(effectiveUnit),
                    money(l.lineSubtotal),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 16),

              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  children: [
                    totalsRow('Subtotal', money(s.itemsSubtotal)),
                    totalsRow('Shipping', money(s.shippingTotal)),
                    totalsRow('Tax', money(totalTax)),
                    if (showCoupon) totalsRow('Coupon ($couponCode)', '-${money(discount)}'),
                    pw.Divider(color: PdfColors.grey300),
                    totalsRow('Grand Total', money(s.grandTotal), bold: true),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static String _pickSymbol(String? fromOrder, String? fallback) {
    final a = (fromOrder ?? '').trim();
    if (a.isNotEmpty) return a;
    final b = (fallback ?? '').trim();
    if (b.isNotEmpty) return b;
    return '\$';
  }

  static String _formatMoney(num v, String symbol) {
    final val = v.toDouble();
    final sign = val < 0 ? '-' : '';
    final abs = val.abs().toStringAsFixed(2);
    return '$sign$symbol$abs';
  }

  static String _formatDateSafe(String? raw) {
    final s = (raw ?? '').trim();
    if (s.isEmpty) return '—';
    try {
      final dt = DateTime.parse(s).toLocal();
      String two(int x) => x.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return s;
    }
  }
}