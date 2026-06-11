import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/features/products/bloc/product_performance/product_performance_bloc.dart';
import 'package:woo_management_app/features/products/bloc/product_performance/product_performance_event.dart';
import 'package:woo_management_app/features/products/bloc/product_performance/product_performance_state.dart';
import 'package:woo_management_app/features/products/presentation/widgets/product_chart_card.dart';
import 'package:woo_management_app/features/products/presentation/widgets/product_performance_shimmer.dart';
import 'package:woo_management_app/features/products/presentation/widgets/top_products_card.dart';
import 'package:woo_management_app/widgets/shared_appbar.dart';

class WooProductPerformancePage extends StatefulWidget {
  const WooProductPerformancePage({super.key});

  @override
  State<WooProductPerformancePage> createState() =>
      _WooProductPerformancePageState();
}

class _WooProductPerformancePageState
    extends State<WooProductPerformancePage> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<ProductPerformanceBloc>();
    final state = bloc.state;
    bloc.add(LoadProductChart(state.chartPeriod));
    bloc.add(LoadTopProducts(state.topPeriod));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SharedAppbar(title: 'Product Performance'),
      body: BlocBuilder<ProductPerformanceBloc, ProductPerformanceState>(
        builder: (context, state) {
          // Full-page shimmer only on the very first load (nothing to show yet).
          final firstLoad = state.chartLoading &&
              state.topLoading &&
              state.chartSpots.isEmpty &&
              state.topProducts.isEmpty;
          if (firstLoad) {
            return const ProductPerformanceShimmer();
          }

          final bloc = context.read<ProductPerformanceBloc>();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                ProductChartCard(
                  period: state.chartPeriod,
                  soldCount: state.soldCount,
                  chartSpots: state.chartSpots,
                  xLabels: state.chartLabels,
                  isLoading: state.chartLoading,
                  onPeriodChanged: (p) => bloc.add(LoadProductChart(p)),
                ),
                const SizedBox(height: 16),
                TopProductsCard(
                  period: state.topPeriod,
                  products: state.topProducts,
                  visibleCount: state.topVisibleCount,
                  isLoading: state.topLoading,
                  onPeriodChanged: (p) => bloc.add(LoadTopProducts(p)),
                  onLoadMore: () => bloc.add(const ShowMoreTopProducts()),
                  onViewAll: () {
                    Navigator.pushNamed(context, RouteNames.wooAllProduct);
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
