import 'package:flutter/foundation.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_bloc.dart';
import 'package:woo_management_app/features/analytics/bloc/analytics_event.dart';
import 'package:woo_management_app/features/products/bloc/product_bloc.dart';
import 'package:woo_management_app/features/products/bloc/product_event.dart';

/// Service to preload data when the app starts
class DataPreloadService {
  final AnalyticsBloc analyticsBloc;
  final ProductBloc productBloc;

  DataPreloadService({
    required this.analyticsBloc,
    required this.productBloc,
  });

  /// Preload all necessary data for the app
  Future<void> preloadData() async {
    try {
      debugPrint('DataPreloadService: Starting data preload');
      
      // Load analytics data
      analyticsBloc.add(const FetchAnalytics(0));
      
      // Load products data
      productBloc.add(const FetchProducts(page: 1, perPage: 20));
      
      debugPrint('DataPreloadService: Data preload initiated');
    } catch (e) {
      debugPrint('DataPreloadService: Error preloading data - $e');
    }
  }
}