import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/features/products/presentation/widgets/sales_summary_widget.dart';
import 'package:woo_management_app/widgets/custom_button.dart';

import '../../../../widgets/app_reusable_text.dart';

class TopPerformerProductSummary extends StatefulWidget {
  final List<dynamic> products;
  const TopPerformerProductSummary({super.key, required this.products});

  @override
  State<TopPerformerProductSummary> createState() =>
      _TopPerformerProductSummaryState();
}

class _TopPerformerProductSummaryState
    extends State<TopPerformerProductSummary> {
  int selectedTabIndex = 0;

  List<Map<String, dynamic>> _filterProductsByTab() {
    final now = DateTime.now();
    DateTime start;
    if (selectedTabIndex == 0) {
      // Today
      start = DateTime(now.year, now.month, now.day);
    } else if (selectedTabIndex == 1) {
      // Last week
      start = now.subtract(Duration(days: 7));
    } else {
      // Last month
      start = DateTime(now.year, now.month - 1, now.day);
    }
    return List<Map<String, dynamic>>.from(widget.products).where((p) {
      final dateStr = p['date_created'] ?? '';
      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;
      return date.isAfter(start);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Sort and filter products by selected tab
    final filteredProducts = _filterProductsByTab();
    filteredProducts.sort(
      (a, b) => (int.tryParse(b['total_sales']?.toString() ?? '0') ?? 0)
          .compareTo(int.tryParse(a['total_sales']?.toString() ?? '0') ?? 0),
    );
    final salesData =
        filteredProducts
            .take(3)
            .map(
              (p) => SalesItem(
                productName: p['name'] ?? '',
                formattedSales: '\$${p['price'] ?? '0'}',
                salesCount:
                    int.tryParse(p['total_sales']?.toString() ?? '0') ?? 0,
                icon: Icons.shopping_bag_outlined,
                imageUrl:
                    (p['images'] != null && p['images'].isNotEmpty)
                        ? p['images'][0]['src']
                        : null,
              ),
            )
            .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppReusableText(text: 'Top Performers'),
            Gap(27),
            SalesSummary(
              salesData: salesData,
              onTabChanged: (index) {
                setState(() {
                  selectedTabIndex = index;
                });
                final tabNames = ['Today', 'Last Week', 'Last Months'];
                print('Selected tab: ${tabNames[index]}');
              },
              onItemTap: (item) {
                print('Tapped on ${item.productName}');
              },
              showProductImage: true,
            ),
            Gap(24),
            CustomButton(
              text: 'View all Store Products',
              onPressed: () {
                Navigator.pushNamed(context, RouteNames.wooAllProduct);
              },
            ),
          ],
        ),
      ),
    );
  }
}
