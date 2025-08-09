import 'package:flutter/material.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/gorgias_dashboard.dart';
import 'package:woo_management_app/features/home/presentation/pages/gorgias_dashboard.dart';
import 'package:woo_management_app/features/products/presentation/pages/woo_all_products_page.dart';
import 'package:woo_management_app/features/products/presentation/pages/woo_product_performance_page.dart';

import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/home/presentation/pages/bottom_nav_page.dart';
import '../../features/home/presentation/widgets/woo_all_orders_page.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth Routes
      // case RouteNames.transactions:
      //   return MaterialPageRoute(
      //     builder: (_) => const TransactionHistoryPage(),
      //   );
      //
      // // Profile Routes
      case RouteNames.editProfile:
        return MaterialPageRoute(builder: (_) => BottomNavScreen());
      case RouteNames.wooProduct:
        return MaterialPageRoute(
          builder: (_) => const WooProductPerformancePage(),
        );
      case RouteNames.wooAllProduct:
        return MaterialPageRoute(builder: (_) => const WooAllProductsPage());
      case RouteNames.analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsPage());
      case RouteNames.gorgiasDashboard:
        return MaterialPageRoute(builder: (_) => GorgiasDashboard());
      case RouteNames.wooAllOrders:
        return MaterialPageRoute(builder: (_) => WooAllOrdersPage());
      //
      // // Other Routes
      // case RouteNames.notifications:
      //   return MaterialPageRoute(builder: (_) => const NotificationsPage());
      // case RouteNames.leaderboard:
      //   return MaterialPageRoute(builder: (_) => const LeaderboardPage());
      // case RouteNames.bettingHistory:
      //   return MaterialPageRoute(builder: (_) => const BettingHistoryPage());
      // case RouteNames.bettingStats:
      //   return MaterialPageRoute(builder: (_) => const BettingStatsPage());

      // Default - Page Not Found
      default:
        return MaterialPageRoute(
          builder:
              (_) => Scaffold(
                body: Center(
                  child: Text('No route defined for ${settings.name}'),
                ),
              ),
        );
    }
  }
}
