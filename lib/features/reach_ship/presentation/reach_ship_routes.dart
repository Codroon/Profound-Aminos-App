import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reach_ship_bloc.dart';
import '../repository/reach_ship_repository.dart';
import 'pages/reach_ship_main_page.dart';
import 'pages/shipping_rates_page.dart';
import 'pages/create_shipment_page.dart';
import 'pages/shipment_tracking_page.dart';
import 'pages/shipment_management_page.dart';
import '../models/shipment.dart';

class ReachShipRoutes {
  static const String main = '/reach-ship';
  static const String rates = '/reach-ship/rates';
  static const String create = '/reach-ship/create';
  static const String tracking = '/reach-ship/tracking';
  static const String management = '/reach-ship/management';
  static const String trackingWithNumber =
      '/reach-ship/tracking/:trackingNumber';
  static const String editShipment = '/reach-ship/edit/:shipmentId';

  static Map<String, WidgetBuilder> get routes {
    return {
      main: (context) => _wrapWithBloc(const ReachShipMainPage()),
      rates: (context) => _wrapWithBloc(const ShippingRatesPage()),
      create: (context) => _wrapWithBloc(const CreateShipmentPage()),
      tracking: (context) => _wrapWithBloc(const ShipmentTrackingPage()),
      management: (context) => _wrapWithBloc(const ShipmentManagementPage()),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '');

    switch (uri.pathSegments.first) {
      case 'reach-ship':
        return _handleReachShipRoutes(uri, settings);
      default:
        return null;
    }
  }

  static Route<dynamic>? _handleReachShipRoutes(
    Uri uri,
    RouteSettings settings,
  ) {
    if (uri.pathSegments.length == 1) {
      // /reach-ship
      return MaterialPageRoute(
        builder: (context) => _wrapWithBloc(const ReachShipMainPage()),
        settings: settings,
      );
    }

    if (uri.pathSegments.length == 2) {
      switch (uri.pathSegments[1]) {
        case 'rates':
          return MaterialPageRoute(
            builder: (context) => _wrapWithBloc(const ShippingRatesPage()),
            settings: settings,
          );
        case 'create':
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder:
                (context) => _wrapWithBloc(
                  CreateShipmentPage(
                    editingShipment: args?['editingShipment'] as Shipment?,
                  ),
                ),
            settings: settings,
          );
        case 'tracking':
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder:
                (context) => _wrapWithBloc(
                  ShipmentTrackingPage(
                    trackingNumber: args?['trackingNumber'] as String?,
                    shipment: args?['shipment'] as Shipment?,
                  ),
                ),
            settings: settings,
          );
        case 'management':
          return MaterialPageRoute(
            builder: (context) => _wrapWithBloc(const ShipmentManagementPage()),
            settings: settings,
          );
      }
    }

    if (uri.pathSegments.length == 3) {
      switch (uri.pathSegments[1]) {
        case 'tracking':
          final trackingNumber = uri.pathSegments[2];
          return MaterialPageRoute(
            builder:
                (context) => _wrapWithBloc(
                  ShipmentTrackingPage(trackingNumber: trackingNumber),
                ),
            settings: settings,
          );
        case 'edit':
          final shipmentId = uri.pathSegments[2];
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder:
                (context) => _wrapWithBloc(
                  CreateShipmentPage(
                    editingShipment: args?['shipment'] as Shipment?,
                  ),
                ),
            settings: settings,
          );
      }
    }

    return null;
  }

  static Widget _wrapWithBloc(Widget child) {
    return BlocProvider(
      create:
          (context) => ReachShipBloc(
            repository: context.read<ReachShipRepository>(),
            connectivity: context.read<Connectivity>(),
          ),
      child: child,
    );
  }

  // Navigation helper methods
  static void navigateToMain(BuildContext context) {
    Navigator.of(context).pushNamed(main);
  }

  static void navigateToRates(BuildContext context) {
    Navigator.of(context).pushNamed(rates);
  }

  static void navigateToCreate(
    BuildContext context, {
    Shipment? editingShipment,
  }) {
    Navigator.of(context).pushNamed(
      create,
      arguments:
          editingShipment != null ? {'editingShipment': editingShipment} : null,
    );
  }

  static void navigateToTracking(
    BuildContext context, {
    String? trackingNumber,
    Shipment? shipment,
  }) {
    Navigator.of(context).pushNamed(
      tracking,
      arguments: {
        if (trackingNumber != null) 'trackingNumber': trackingNumber,
        if (shipment != null) 'shipment': shipment,
      },
    );
  }

  static void navigateToManagement(BuildContext context) {
    Navigator.of(context).pushNamed(management);
  }

  static void navigateToTrackingWithNumber(
    BuildContext context,
    String trackingNumber,
  ) {
    Navigator.of(context).pushNamed('/reach-ship/tracking/$trackingNumber');
  }

  static void navigateToEditShipment(BuildContext context, Shipment shipment) {
    Navigator.of(context).pushNamed(
      '/reach-ship/edit/${shipment.id}',
      arguments: {'shipment': shipment},
    );
  }

  // Push methods for better navigation control
  static Future<T?> pushMain<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => _wrapWithBloc(const ReachShipMainPage()),
      ),
    );
  }

  static Future<T?> pushRates<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => _wrapWithBloc(const ShippingRatesPage()),
      ),
    );
  }

  static Future<T?> pushCreate<T>(
    BuildContext context, {
    Shipment? editingShipment,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder:
            (context) => _wrapWithBloc(
              CreateShipmentPage(editingShipment: editingShipment),
            ),
      ),
    );
  }

  static Future<T?> pushTracking<T>(
    BuildContext context, {
    String? trackingNumber,
    Shipment? shipment,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder:
            (context) => _wrapWithBloc(
              ShipmentTrackingPage(
                trackingNumber: trackingNumber,
                shipment: shipment,
              ),
            ),
      ),
    );
  }

  static Future<T?> pushManagement<T>(BuildContext context) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        builder: (context) => _wrapWithBloc(const ShipmentManagementPage()),
      ),
    );
  }

  // Replace methods for navigation replacement
  static Future<T?> replaceWithMain<T>(BuildContext context) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute(
        builder: (context) => _wrapWithBloc(const ReachShipMainPage()),
      ),
    );
  }

  static Future<T?> replaceWithRates<T>(BuildContext context) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute(
        builder: (context) => _wrapWithBloc(const ShippingRatesPage()),
      ),
    );
  }

  static Future<T?> replaceWithCreate<T>(
    BuildContext context, {
    Shipment? editingShipment,
  }) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute(
        builder:
            (context) => _wrapWithBloc(
              CreateShipmentPage(editingShipment: editingShipment),
            ),
      ),
    );
  }

  static Future<T?> replaceWithTracking<T>(
    BuildContext context, {
    String? trackingNumber,
    Shipment? shipment,
  }) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute(
        builder:
            (context) => _wrapWithBloc(
              ShipmentTrackingPage(
                trackingNumber: trackingNumber,
                shipment: shipment,
              ),
            ),
      ),
    );
  }

  static Future<T?> replaceWithManagement<T>(BuildContext context) {
    return Navigator.of(context).pushReplacement<T, void>(
      MaterialPageRoute(
        builder: (context) => _wrapWithBloc(const ShipmentManagementPage()),
      ),
    );
  }
}
