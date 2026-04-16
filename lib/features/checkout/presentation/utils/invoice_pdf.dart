import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:build4front/features/checkout/data/models/checkout_summary_model.dart';

class StandardInvoicePdfLabels {
  final String invoiceTitle;
  final String orderLabel;
  final String dateLabel;
  final String providerLabel;
  final String statusLabel;
  final String refLabel;
  final String itemsLabel;
  final String itemLabel;
  final String qtyLabel;
  final String unitLabel;
  final String totalLabel;
  final String subtotalLabel;
  final String shippingLabel;
  final String taxLabel;
  final String grandTotalLabel;
  final String Function(String code)? couponLine;

  const StandardInvoicePdfLabels({
    required this.invoiceTitle,
    required this.orderLabel,
    required this.dateLabel,
    required this.providerLabel,
    required this.statusLabel,
    required this.refLabel,
    required this.itemsLabel,
    required this.itemLabel,
    required this.qtyLabel,
    required this.unitLabel,
    required this.totalLabel,
    required this.subtotalLabel,
    required this.shippingLabel,
    required this.taxLabel,
    required this.grandTotalLabel,
    this.couponLine,
  });
}

class InvoicePdf {
  static Future<Uint8List> build(
    CheckoutSummaryModel s, {
    String? fallbackSymbol,
    String? title,
    Map<int, String>? itemNameById,
    StandardInvoicePdfLabels? labels,
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
      theme = null;
    }

    final l = labels ??
        const StandardInvoicePdfLabels(
          invoiceTitle: 'Invoice',
          orderLabel: 'Order',
          dateLabel: 'Date',
          providerLabel: 'Provider',
          statusLabel: 'Status',
          refLabel: 'Ref',
          itemsLabel: 'Items',
          itemLabel: 'Item',
          qtyLabel: 'Qty',
          unitLabel: 'Unit',
          totalLabel: 'Total',
          subtotalLabel: 'Subtotal',
          shippingLabel: 'Shipping',
          taxLabel: 'Tax',
          grandTotalLabel: 'Grand Total',
        );

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
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        v,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: bold
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          pw.Widget totalsRow(String left, String right, {bool bold = false}) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    left,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: bold
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    right,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: bold
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
                              (title ?? l.invoiceTitle).toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 8),
                            kvLine(l.orderLabel, shownOrderCode, bold: true),
                            kvLine(l.dateLabel, dateText),
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
                            kvLine(
                              l.providerLabel,
                              provider.isEmpty ? '—' : provider,
                            ),
                            kvLine(
                              l.statusLabel,
                              paymentStatus.isEmpty ? '—' : paymentStatus,
                            ),
                            kvLine(
                              l.refLabel,
                              providerPaymentId.isEmpty ? '—' : providerPaymentId,
                            ),
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
                l.itemsLabel,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table.fromTextArray(
                headers: [
                  l.itemLabel,
                  l.qtyLabel,
                  l.unitLabel,
                  l.totalLabel,
                ],
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey200,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(0.8),
                  2: pw.FlexColumnWidth(1.2),
                  3: pw.FlexColumnWidth(1.2),
                },
                data: s.lines.map((line) {
                  final backendName = (line.itemName ?? '').trim();
                  final fallback = (itemNameById?[line.itemId] ?? '').trim();

                  final name = backendName.isNotEmpty
                      ? backendName
                      : (fallback.isNotEmpty ? fallback : l.itemLabel);

                  final effectiveUnit = (line.quantity <= 0)
                      ? line.unitPrice
                      : (line.lineSubtotal / line.quantity);

                  return [
                    name,
                    line.quantity.toString(),
                    money(effectiveUnit),
                    money(line.lineSubtotal),
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
                    totalsRow(l.subtotalLabel, money(s.itemsSubtotal)),
                    totalsRow(l.shippingLabel, money(s.shippingTotal)),
                    totalsRow(l.taxLabel, money(totalTax)),
                    if (showCoupon)
                      totalsRow(
                        l.couponLine != null
                            ? l.couponLine!(couponCode)
                            : 'Coupon ($couponCode)',
                        '-${money(discount)}',
                      ),
                    pw.Divider(color: PdfColors.grey300),
                    totalsRow(
                      l.grandTotalLabel,
                      money(s.grandTotal),
                      bold: true,
                    ),
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

  static Future<void> share(
    CheckoutSummaryModel s, {
    String? fallbackSymbol,
    String? title,
    Map<int, String>? itemNameById,
    StandardInvoicePdfLabels? labels,
  }) async {
    final bytes = await build(
      s,
      fallbackSymbol: fallbackSymbol,
      title: title,
      itemNameById: itemNameById,
      labels: labels,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'invoice.pdf',
    );
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