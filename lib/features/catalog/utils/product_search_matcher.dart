
import 'package:build4front/features/admin/product/domain/entities/product.dart';

class ProductSearchMatcher {
  static String _norm(String v) => v.trim().toLowerCase();

  static String _normSku(String? v) {
    final raw = (v ?? '').trim().toLowerCase();
    return raw.replaceFirst(RegExp(r'^sku[\s\-_:#]*'), '');
  }

  static bool matches(Product p, String query) {
    final q = _norm(query);
    if (q.isEmpty) return true;

    final name = _norm(p.name);
    final sku = _normSku(p.sku);

    if (q.length == 1) {
      return name.startsWith(q) || sku.startsWith(q);
    }

    return name.contains(q) || sku.contains(q);
  }
}