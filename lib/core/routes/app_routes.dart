import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/core/di/injection_container.dart';
import 'package:woo_management_app/core/routes/routes_name.dart';
import 'package:woo_management_app/features/gorgias/presentation/pages/gorgias_dashboard.dart';
import 'package:woo_management_app/features/products/presentation/pages/woo_all_products_page.dart';
import 'package:woo_management_app/features/products/bloc/product_performance/product_performance_bloc.dart';
import 'package:woo_management_app/features/products/presentation/pages/woo_product_performance_page.dart';

import '../../features/analytics/models/revenue_period.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';
import '../../features/analytics/presentation/pages/orders_details_page.dart';
import '../../features/home/presentation/pages/bottom_nav_page.dart';
import '../../features/home/presentation/widgets/woo_all_orders_page.dart';
import '../../features/shipping/bloc/shipping_bloc.dart';
import '../../features/shipping/data/models/shipment_period.dart';
import '../../features/shipping/presentation/pages/all_shipments_page.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
          builder: (_) => BlocProvider(
            create: (_) => sl<ProductPerformanceBloc>(),
            child: const WooProductPerformancePage(),
          ),
        );
      case RouteNames.wooAllProduct:
        return MaterialPageRoute(builder: (_) => const WooAllProductsPage());
      case RouteNames.analytics:
        final period = settings.arguments is RevenuePeriod
            ? settings.arguments as RevenuePeriod
            : RevenuePeriod.thisWeek;
        return MaterialPageRoute(
            builder: (_) => AnalyticsPage(initialPeriod: period));
      case RouteNames.ordersDetails:
        return MaterialPageRoute(builder: (_) => const OrdersDetailsPage());
      case RouteNames.gorgiasDashboard:
        final ticketId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => GorgiasDashboard(highlightTicketId: ticketId),
        );
      case RouteNames.wooAllOrders:
        final orderId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => WooAllOrdersPage(highlightOrderId: orderId),
        );
      
      // Shipping Routes
      case RouteNames.shipments:
        // Push notifications pass a String highlight id; the shipping dashboard
        // passes the selected ShipmentPeriod to carry its time filter through.
        final shipmentArgs = settings.arguments;
        final shipmentId = shipmentArgs is String ? shipmentArgs : null;
        final shipmentPeriod =
            shipmentArgs is ShipmentPeriod ? shipmentArgs : null;
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) => ShippingBloc(),
            child: AllShipmentsPage(
              highlightShipmentId: shipmentId,
              period: shipmentPeriod,
            ),
          ),
        );
      
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

