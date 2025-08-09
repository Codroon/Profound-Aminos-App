import 'package:woo_management_app/core/network/network_info.dart';
import 'package:woo_management_app/core/storage/cache_manager.dart';
import '../../../core/constants/storage_constants.dart';
import '../../../core/services/woocommerce_service.dart';
import '../../../core/services/wordpress_service.dart';

abstract class ProductRepository {
  Future<List<dynamic>> getProducts({required int page, required int perPage, String? searchTerm});
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data);
  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data);
  Future<void> deleteProduct(int id);
  Future<void> clearProductsCache();
  Future<List<int>> uploadImages(List<String> imagePaths, List<String> fileNames);
}

class ProductRepositoryImpl implements ProductRepository {
  final NetworkInfo networkInfo;
  final CacheManager cacheManager;
  final WooCommerceService wooCommerceService = WooCommerceService();
  final WordpressService wordpressService = WordpressService();

  ProductRepositoryImpl({
    required this.networkInfo,
    required this.cacheManager,
  });

  @override
  Future<List<dynamic>> getProducts({required int page, required int perPage, String? searchTerm}) async {
    final cacheKey = 'products_page_${page}_perPage_${perPage}_search_${searchTerm ?? ''}';
    if (await networkInfo.isConnected) {
      final products = await wooCommerceService.getProducts(
        page: page, perPage: perPage, searchTerm: searchTerm);
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
  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) {
    return wooCommerceService.createProduct(data);
  }

  @override
  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) {
    return wooCommerceService.updateProduct(id, data);
  }

  @override
  Future<void> deleteProduct(int id) {
    return wooCommerceService.deleteProduct(id);
  }

  @override
  Future<void> clearProductsCache() async {
    await cacheManager.clearCache();
  }

  @override
  Future<List<int>> uploadImages(List<String> imagePaths, List<String> fileNames) {
    return wordpressService.uploadImagesToMediaLibrary(imagePaths, fileNames);
  }
}