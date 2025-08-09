import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:woo_management_app/core/di/injection_container.dart' as di;
import '../../../../widgets/shared_appbar.dart';
import '../widgets/order_analytics_card.dart';
import '../widgets/revenue_analaytics_card.dart';
import '../widgets/revenue_products_card.dart';
import '../../bloc/analytics_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedAppbar(title: 'Product Performance'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RevenueAnalyticsCard(),
              Gap(24),
              OrderAnalyticsCard(),
              Gap(24),
              RevenueProductsCard(),
            ],
          ),
        ),
      ),
    );
  }
}
