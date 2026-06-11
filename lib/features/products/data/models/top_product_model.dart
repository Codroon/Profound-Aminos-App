/// A single row in the "Top Products" ranking, built from the WooCommerce
/// Analytics products report (`wc-analytics/reports/products`).
class TopProductModel {
  final int productId;
  final String name;
  final int itemsSold;
  final double netRevenue;
  final String? imageUrl;
  final String price;

  const TopProductModel({
    required this.productId,
    required this.name,
    required this.itemsSold,
    required this.netRevenue,
    this.imageUrl,
    required this.price,
  });

  TopProductModel copyWith({String? imageUrl}) {
    return TopProductModel(
      productId: productId,
      name: name,
      itemsSold: itemsSold,
      netRevenue: netRevenue,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price,
    );
  }

  /// Parses one item from the analytics products report. With
  /// `extended_info=true` the name/image/price live under `extended_info`.
  factory TopProductModel.fromReportJson(Map<String, dynamic> json) {
    final rawInfo = json['extended_info'];
    final info = rawInfo is Map ? rawInfo : const {};
    return TopProductModel(
      productId: int.tryParse(json['product_id']?.toString() ?? '') ?? 0,
      name: info['name']?.toString() ?? 'Unknown',
      itemsSold: int.tryParse(json['items_sold']?.toString() ?? '0') ?? 0,
      netRevenue:
          double.tryParse(json['net_revenue']?.toString() ?? '0') ?? 0.0,
      imageUrl: _extractImageUrl(info['image']?.toString()),
      price: info['price']?.toString() ?? '0',
    );
  }

  /// The report's `image` field is sometimes a bare URL and sometimes a full
  /// HTML `<img …>` tag (Profound's store returns the latter). Pull the `src`
  /// URL out of the tag when present, otherwise treat the value as a URL.
  static String? _extractImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final trimmed = raw.trim();
    if (trimmed.contains('<img')) {
      final match =
          RegExp(r'''src\s*=\s*["']([^"']+)["']''').firstMatch(trimmed);
      final src = match?.group(1)?.trim();
      return (src != null && src.isNotEmpty) ? src : null;
    }
    return trimmed.startsWith('http') ? trimmed : null;
  }
}
