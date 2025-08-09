import 'package:woo_management_app/core/network/network_info.dart';
import 'package:woo_management_app/core/storage/cache_manager.dart';
import 'package:woo_management_app/core/constants/storage_constants.dart';

import '../../../core/services/woocommerce_service.dart';

abstract class AnalyticsRepository {
  Future<List<dynamic>> getSalesReport({String? dateMin, String? dateMax});
  Future<List<dynamic>> getOrders({required int page, required int perPage});
  Future<List<dynamic>> getProducts({required int page, required int perPage});
  Future<void> clearAnalyticsCache();
}

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final NetworkInfo networkInfo;
  final CacheManager cacheManager;
  final WooCommerceService wooCommerceService = WooCommerceService();

  AnalyticsRepositoryImpl({
    required this.networkInfo,
    required this.cacheManager,
  });

  @override
  Future<List<dynamic>> getSalesReport({String? dateMin, String? dateMax}) async {
    // Create cache key based on date parameters
    final cacheKey = 'sales_report_${dateMin ?? 'default'}_${dateMax ?? 'default'}';
    if (await networkInfo.isConnected) {
      final salesReport = await wooCommerceService.getSalesReport(
        dateMin: dateMin,
        dateMax: dateMax,
      );
      await cacheManager.cacheData(
        cacheKey,
        salesReport,
        duration: StorageConstants.shortCacheDuration,
      );
      return salesReport;
    } else {
      final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      throw Exception('No internet connection and no cached data available.');
    }
  }

  @override
  Future<List<dynamic>> getOrders({required int page, required int perPage}) async {
    final cacheKey = 'orders_report_page_${page}_perPage_${perPage}';
    if (await networkInfo.isConnected) {
      final orders = await wooCommerceService.getOrders(page: page, perPage: perPage);
      await cacheManager.cacheData(
        cacheKey,
        orders,
        duration: StorageConstants.shortCacheDuration,
      );
      return orders;
    } else {
      final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      throw Exception('No internet connection and no cached data available.');
    }
  }

  @override
  Future<List<dynamic>> getProducts({required int page, required int perPage}) async {
    final cacheKey = 'products_report_page_${page}_perPage_${perPage}';
    if (await networkInfo.isConnected) {
      final products = await wooCommerceService.getProducts(page: page, perPage: perPage);
      await cacheManager.cacheData(
        cacheKey,
        products,
        duration: StorageConstants.shortCacheDuration,
      );
      return products;
    } else {
      final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
      throw Exception('No internet connection and no cached data available.');
    }
  }

  @override
  Future<void> clearAnalyticsCache() async {
    await cacheManager.removeCachedData('sales_report');
    await cacheManager.removeCachedData('products_report_page_1_perPage_100');
    await cacheManager.removeCachedData('orders_report_page_1_perPage_100');
  }
}