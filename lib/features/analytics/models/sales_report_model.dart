class SalesReportModel {
  final double totalSales;
  final double netSales;
  final double averageSales;
  final int totalOrders;
  final int totalItems;
  final double totalTax;
  final double totalShipping;
  final double totalRefunds;
  final double totalDiscount;
  final String totalsGroupedBy;
  final Map<String, SalesReportTotal> totals;

  const SalesReportModel({
    required this.totalSales,
    required this.netSales,
    required this.averageSales,
    required this.totalOrders,
    required this.totalItems,
    required this.totalTax,
    required this.totalShipping,
    required this.totalRefunds,
    required this.totalDiscount,
    required this.totalsGroupedBy,
    required this.totals,
  });

  factory SalesReportModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawTotals =
        (json['totals'] as Map<String, dynamic>?) ?? {};

    final Map<String, SalesReportTotal> parsedTotals = {};
    rawTotals.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedTotals[key] = SalesReportTotal.fromJson(value);
      }
    });

    return SalesReportModel(
      totalSales:
          double.tryParse(json['total_sales']?.toString() ?? '0') ?? 0.0,
      netSales: double.tryParse(json['net_sales']?.toString() ?? '0') ?? 0.0,
      averageSales:
          double.tryParse(json['average_sales']?.toString() ?? '0') ?? 0.0,
      totalOrders:
          int.tryParse(json['total_orders']?.toString() ?? '0') ?? 0,
      totalItems:
          int.tryParse(json['total_items']?.toString() ?? '0') ?? 0,
      totalTax: double.tryParse(json['total_tax']?.toString() ?? '0') ?? 0.0,
      totalShipping:
          double.tryParse(json['total_shipping']?.toString() ?? '0') ?? 0.0,
      totalRefunds:
          double.tryParse(json['total_refunds']?.toString() ?? '0') ?? 0.0,
      totalDiscount:
          double.tryParse(json['total_discount']?.toString() ?? '0') ?? 0.0,
      totalsGroupedBy:
          json['totals_grouped_by']?.toString() ?? 'day',
      totals: parsedTotals,
    );
  }
}

class SalesReportTotal {
  final double sales;
  final int orders;
  final int items;
  final double tax;
  final double shipping;
  final double discount;
  final int customers;

  const SalesReportTotal({
    required this.sales,
    required this.orders,
    required this.items,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.customers,
  });

  factory SalesReportTotal.fromJson(Map<String, dynamic> json) {
    return SalesReportTotal(
      sales: double.tryParse(json['sales']?.toString() ?? '0') ?? 0.0,
      orders: int.tryParse(json['orders']?.toString() ?? '0') ?? 0,
      items: int.tryParse(json['items']?.toString() ?? '0') ?? 0,
      tax: double.tryParse(json['tax']?.toString() ?? '0') ?? 0.0,
      shipping: double.tryParse(json['shipping']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      customers: int.tryParse(json['customers']?.toString() ?? '0') ?? 0,
    );
  }
}