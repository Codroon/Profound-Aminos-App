import 'package:woo_management_app/core/network/network_info.dart';
import 'package:woo_management_app/core/storage/cache_manager.dart';
import 'package:woo_management_app/core/constants/storage_constants.dart';
import 'package:woo_management_app/core/utils/app_logger.dart';

import '../../../core/services/woocommerce_service.dart';

abstract class AnalyticsRepository {
  Future<List<dynamic>> getSalesReport({
    String? dateMin,
    String? dateMax,
    String? period,
  });
  Future<List<dynamic>> getOrders({required int page, required int perPage});
  Future<List<dynamic>> getOrdersByDateRange({
    required String after,
    required String before,
    int page,
    int perPage,
  });
  Future<int> getOrdersTotalCount({String? after, String? before});
  Future<int> getProductsTotalCount();
  Future<List<dynamic>> getProducts({required int page, required int perPage});
  Future<List<dynamic>> getProductsReport({
    String? after,
    String? before,
    String orderBy,
    String order,
    int page,
    int perPage,
    bool extendedInfo,
  });
  Future<Map<int, String>> getProductImages(List<int> productIds);
  Future<Map<String, dynamic>> getRevenueStats({
    String? after,
    String? before,
    String? interval,
    int? perPage,
  });
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
  Future<List<dynamic>> getSalesReport({
    String? dateMin,
    String? dateMax,
    String? period,
  }) async {
    final cacheKey = 'sales_report_${dateMin ?? 'all'}_${dateMax ?? 'all'}_${period ?? 'day'}';
    if (await networkInfo.isConnected) {
      final salesReport = await wooCommerceService.getSalesReport(
        dateMin: dateMin,
        dateMax: dateMax,
        period: period,
      );
      await cacheManager.cacheData(
        cacheKey,
        salesReport,
        duration: StorageConstants.shortCacheDuration,
      );
      return salesReport;
    } else {
      final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
      if (cachedData != null) return cachedData;
      throw Exception('No internet connection and no cached data.');
    }
  }

  @override
  Future<List<dynamic>> getOrders({required int page, required int perPage}) async {
    final cacheKey = 'orders_report_page_${page}_perPage_$perPage';
    if (await networkInfo.isConnected) {
      try {
        final orders = await wooCommerceService.getOrders(page: page, perPage: perPage);
        await cacheManager.cacheData(
          cacheKey,
          orders,
          duration: StorageConstants.shortCacheDuration,
        );
        return orders;
      } catch (e) {
        final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          AppLog.cache('Analytics', 'getOrders failed → serving cached orders');
          return cachedData;
        }
        rethrow;
      }
    } else {
      final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
      if (cachedData != null) return cachedData;
      throw Exception('No internet and no cached data.');
    }
  }

  @override
  Future<List<dynamic>> getOrdersByDateRange({
    required String after,
    required String before,
    int page = 1,
    int perPage = 10,
  }) async {
    if (await networkInfo.isConnected) {
      return wooCommerceService.getOrdersByDateRange(
        after: after,
        before: before,
        page: page,
        perPage: perPage,
      );
    } else {
      throw Exception('No internet connection.');
    }
  }

  @override
  Future<int> getOrdersTotalCount({String? after, String? before}) async {
    final cacheKey = 'orders_total_count_${after ?? 'all'}_${before ?? 'all'}';
    if (await networkInfo.isConnected) {
      final count = await wooCommerceService.getOrdersTotalCount(
        after: after,
        before: before,
      );
      await cacheManager.cacheData(
        cacheKey,
        count,
        duration: StorageConstants.shortCacheDuration,
      );
      return count;
    } else {
      final cached = await cacheManager.getCachedData<int>(cacheKey);
      if (cached != null) return cached;
      throw Exception('No internet and no cached order count.');
    }
  }

  @override
  Future<int> getProductsTotalCount() async {
    const cacheKey = 'products_total_count';
    if (await networkInfo.isConnected) {
      try {
        final count = await wooCommerceService.getProductsTotalCount();
        await cacheManager.cacheData(
          cacheKey,
          count,
          duration: StorageConstants.shortCacheDuration,
        );
        return count;
      } catch (e) {
        final cached = await cacheManager.getCachedData<int>(cacheKey);
        if (cached != null) {
          AppLog.cache('Analytics', 'getProductsTotalCount failed → serving cached count');
          return cached;
        }
        rethrow;
      }
    } else {
      final cached = await cacheManager.getCachedData<int>(cacheKey);
      if (cached != null) return cached;
      throw Exception('No internet and no cached product count.');
    }
  }

  @override
  Future<List<dynamic>> getProducts({required int page, required int perPage}) async {
    final cacheKey = 'products_report_page_${page}_perPage_$perPage';
    if (await networkInfo.isConnected) {
      try {
        final products = await wooCommerceService.getProducts(page: page, perPage: perPage);
        await cacheManager.cacheData(
          cacheKey,
          products,
          duration: StorageConstants.shortCacheDuration,
        );
        return products;
      } catch (e) {
        final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          AppLog.cache('Analytics', 'getProducts failed → serving cached products');
          return cachedData;
        }
        rethrow;
      }
    } else {
      final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
      if (cachedData != null) return cachedData;
      throw Exception('No internet and no cached product data.');
    }
  }

  @override
  Future<List<dynamic>> getProductsReport({
    String? after,
    String? before,
    String orderBy = 'items_sold',
    String order = 'desc',
    int page = 1,
    int perPage = 100,
    bool extendedInfo = true,
  }) async {
    final cacheKey =
        'products_report_${after ?? 'all'}_${before ?? 'all'}_${orderBy}_${order}_${page}_$perPage';
    if (await networkInfo.isConnected) {
      try {
        final report = await wooCommerceService.getProductsReport(
          after: after,
          before: before,
          orderBy: orderBy,
          order: order,
          page: page,
          perPage: perPage,
          extendedInfo: extendedInfo,
        );
        await cacheManager.cacheData(
          cacheKey,
          report,
          duration: StorageConstants.shortCacheDuration,
        );
        return report;
      } catch (e) {
        final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
        if (cachedData != null) {
          AppLog.cache('Analytics', 'getProductsReport failed → serving cached report');
          return cachedData;
        }
        rethrow;
      }
    } else {
      final cachedData = await cacheManager.getCachedData<List<dynamic>>(cacheKey);
      if (cachedData != null) return cachedData;
      throw Exception('No internet and no cached product report.');
    }
  }

  @override
  Future<Map<int, String>> getProductImages(List<int> productIds) async {
    if (productIds.isEmpty || !await networkInfo.isConnected) return {};
    // The image bytes are cached on disk by CachedNetworkImage and the enriched
    // models are held in the bloc's in-memory cache, so this lightweight
    // metadata lookup doesn't need its own SharedPreferences cache entry.
    return wooCommerceService.getProductImages(productIds);
  }

  @override
  Future<Map<String, dynamic>> getRevenueStats({
    String? after,
    String? before,
    String? interval,
    int? perPage,
  }) async {
    final cacheKey =
        'revenue_stats_${after ?? 'all'}_${before ?? 'all'}_${interval ?? 'all'}_${perPage ?? 'def'}';
    if (await networkInfo.isConnected) {
      try {
        final stats = await wooCommerceService.getRevenueStats(
          after: after,
          before: before,
          interval: interval,
          perPage: perPage,
        );
        await cacheManager.cacheData(
          cacheKey,
          stats,
          duration: StorageConstants.shortCacheDuration,
        );
        return stats;
      } catch (e) {
        final cachedData = await cacheManager.getCachedData<Map<String, dynamic>>(cacheKey);
        if (cachedData != null) {
          AppLog.cache('Analytics', 'getRevenueStats failed → serving cached stats');
          return cachedData;
        }
        rethrow;
      }
    } else {
      final cachedData = await cacheManager.getCachedData<Map<String, dynamic>>(cacheKey);
      if (cachedData != null) return cachedData;
      throw Exception('No internet connection and no cached revenue stats.');
    }
  }

  @override
  Future<void> clearAnalyticsCache() async {
    await cacheManager.removeCachedData('sales_report');
  }
}