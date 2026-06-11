import 'dart:io';
import 'package:dio/dio.dart';
import '../error/error_handler.dart';
import '../network/app_http_client.dart';
import '../network/dio_http_adapter.dart';
import '../utils/app_logger.dart';
import 'dart:convert';
import './crediential_storage_service.dart';

class WooCommerceService {
  /// Network timeout — a request that exceeds this fails fast so loading
  /// states resolve instead of hanging forever, letting callers fall back
  /// to cached data.
  static const Duration _timeout = Duration(seconds: 30);

  /// One shared Dio for ALL WooCommerce REST calls app-wide. On iOS/macOS it
  /// runs over the native NSURLSession transport (HTTP/2, proper pooling) to
  /// avoid the dart:io connection-starvation hang; elsewhere it uses the
  /// platform-appropriate client from [createAppHttpClient].
  static final Dio _dio = _buildDio();

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
      ),
    );
    // Only iOS/macOS need the NSURLSession transport to dodge the dart:io
    // connection-starvation hang. Android already works on Dio's default
    // adapter, so leave it untouched.
    if (Platform.isIOS || Platform.isMacOS) {
      dio.httpClientAdapter = HttpToDioAdapter(createAppHttpClient());
    }
    return dio;
  }
  String _baseUrl = '';
  String _consumerKey = '';
  String _consumerSecret = '';

  // In-memory credential cache — avoids hitting the Keychain on every request.
  static Map<String, String>? _credCache;
  static DateTime? _credCachedAt;
  static const Duration _credTtl = Duration(minutes: 30);

  /// Clear the cached credentials (call after the user updates them).
  static void clearCredentialCache() {
    _credCache = null;
    _credCachedAt = null;
  }

  Future<void> _loadCredentials() async {
    if (_credCache != null &&
        _credCachedAt != null &&
        DateTime.now().difference(_credCachedAt!) < _credTtl) {
      _baseUrl = _credCache!['wooUrl'] ?? '';
      _consumerKey = _credCache!['wooKey'] ?? '';
      _consumerSecret = _credCache!['wooSecret'] ?? '';
      return;
    }
    final storage = CredentialStorageService();
    final creds = await storage.getCredentials();
    _baseUrl = creds['wooUrl'] ?? '';
    _consumerKey = creds['wooKey'] ?? '';
    _consumerSecret = creds['wooSecret'] ?? '';
    _credCache = {
      'wooUrl': _baseUrl,
      'wooKey': _consumerKey,
      'wooSecret': _consumerSecret,
    };
    _credCachedAt = DateTime.now();
  }

  /// Wraps a Dio call with start/outcome/elapsed logging so background API
  /// activity is visible in the VS Code terminal and Xcode console.
  Future<T> _traced<T>(String label, Future<T> Function() request) async {
    final sw = Stopwatch()..start();
    AppLog.net('WooCommerce', '$label → request START');
    try {
      final result = await request();
      AppLog.ok('WooCommerce', '$label → DONE in ${sw.elapsedMilliseconds}ms');
      return result;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        AppLog.timeout('WooCommerce',
            '$label → TIMEOUT after ${sw.elapsedMilliseconds}ms');
      } else {
        AppLog.error('WooCommerce',
            '$label → FAILED in ${sw.elapsedMilliseconds}ms: ${e.message}');
      }
      rethrow;
    } catch (e) {
      AppLog.error(
          'WooCommerce', '$label → FAILED in ${sw.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }

  Map<String, String> _basicAuthHeader() {
    String basicAuth =
        'Basic ${base64Encode(utf8.encode('$_consumerKey:$_consumerSecret'))}';
    return {'Authorization': basicAuth};
  }

  Map<String, dynamic> _urlParams(Map<String, dynamic> params) {
    return params;
  }

  /// The store's UTC offset in hours (e.g. `-7.0`, `5.5`), read from the
  /// WordPress REST root. WooCommerce interprets report/order date filters in
  /// this timezone, so callers use it to build correct "today/this week"
  /// windows regardless of where the admin's device is. Returns null if the
  /// field is missing.
  Future<double?> fetchStoreGmtOffset() async {
    await _loadCredentials();
    try {
      // The WP REST root is public. Do NOT send the WooCommerce key/secret as
      // Basic Auth here — those creds only authenticate on /wc/v3 & /wc-analytics
      // routes, and a failed auth makes WordPress reject the whole request with
      // 401 even for this public index.
      final response = await _traced(
        'fetchStoreGmtOffset',
        () => _dio.get('$_baseUrl/wp-json'),
      );
      final data = response.data as Map<String, dynamic>;
      final raw = data['gmt_offset'];
      final parsed = raw == null ? null : double.tryParse(raw.toString());
      if (parsed != null) return parsed;
    } catch (e) {
      // Public root may be locked down by a security plugin — fall through to
      // deriving the offset from an order below.
      AppLog.cache('WooCommerce',
          'fetchStoreGmtOffset(/wp-json) failed ($e) → deriving from an order');
    }

    // Fallback: every order exposes both store-local `date_created` and UTC
    // `date_created_gmt`; their difference is the store's UTC offset. Uses the
    // already-authenticated WC orders route, so it works even when /wp-json is
    // closed.
    try {
      final orders = await getOrders(page: 1, perPage: 1);
      if (orders.isEmpty) return null;
      final o = orders.first as Map<String, dynamic>;
      final local = DateTime.tryParse(o['date_created']?.toString() ?? '');
      final gmt = DateTime.tryParse(o['date_created_gmt']?.toString() ?? '');
      if (local == null || gmt == null) return null;
      // Round to the nearest minute to absorb the seconds drift between the two
      // timestamps, then express as fractional hours (e.g. 5.5 for +05:30).
      final minutes = (local.difference(gmt).inSeconds / 60).round();
      return minutes / 60.0;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<dynamic>> getProducts({int page = 1, int perPage = 20, String? searchTerm}) async {
    await _loadCredentials();
    try {
      final Map<String, dynamic> params = {'page': page, 'per_page': perPage};
      if (searchTerm != null && searchTerm.isNotEmpty) {
        params['search'] = searchTerm;
      }
      
      final response = await _traced(
        'getProducts(page:$page)',
        () => _dio.get(
          '$_baseUrl/wp-json/wc/v3/products',
          queryParameters: _urlParams(params),
          options: Options(headers: _basicAuthHeader()),
        ),
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<dynamic>> getOrders({int page = 1, int perPage = 20}) async {
    await _loadCredentials();
    try {
      final response = await _traced(
        'getOrders(page:$page)',
        () => _dio.get(
          '$_baseUrl/wp-json/wc/v3/orders',
          queryParameters: _urlParams({'page': page, 'per_page': perPage}),
          options: Options(headers: _basicAuthHeader()),
        ),
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<dynamic>> getOrdersByDateRange({
    required String after,
    required String before,
    int page = 1,
    int perPage = 10,
  }) async {
    await _loadCredentials();
    try {
      final response = await _traced(
        'getOrdersByDateRange',
        () => _dio.get(
          '$_baseUrl/wp-json/wc/v3/orders',
          queryParameters: _urlParams({
            'after': after,
            'before': before,
            'page': page,
            'per_page': perPage,
            'orderby': 'date',
            'order': 'desc',
          }),
          options: Options(headers: _basicAuthHeader()),
        ),
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<int> getOrdersTotalCount({String? after, String? before}) async {
    await _loadCredentials();
    try {
      final params = _urlParams({'page': 1, 'per_page': 1});
      if (after != null) params['after'] = after;
      if (before != null) params['before'] = before;

      final response = await _traced(
        'getOrdersTotalCount',
        () => _dio.get(
          '$_baseUrl/wp-json/wc/v3/orders',
          queryParameters: params,
          options: Options(headers: _basicAuthHeader()),
        ),
      );
      final total = response.headers.value('x-wp-total');
      return int.tryParse(total ?? '0') ?? 0;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<int> getProductsTotalCount() async {
    await _loadCredentials();
    try {
      final response = await _traced(
        'getProductsTotalCount',
        () => _dio.get(
          '$_baseUrl/wp-json/wc/v3/products',
          queryParameters: _urlParams({'page': 1, 'per_page': 1}),
          options: Options(headers: _basicAuthHeader()),
        ),
      );
      final total = response.headers.value('x-wp-total');
      return int.tryParse(total ?? '0') ?? 0;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<List<dynamic>> getSalesReport({
    String? dateMin,
    String? dateMax,
    String? period,
  }) async {
    await _loadCredentials();
    try {
      final params = _urlParams({});
      if (dateMin != null) params['date_min'] = dateMin;
      if (dateMax != null) params['date_max'] = dateMax;
      if (period != null) params['period'] = period;

      final response = await _traced(
        'getSalesReport',
        () => _dio.get(
          '$_baseUrl/wp-json/wc/v3/reports/sales',
          queryParameters: params,
          options: Options(headers: _basicAuthHeader()),
        ),
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    await _loadCredentials();
    try {
      final response = await _dio.post(
        '$_baseUrl/wp-json/wc/v3/products',
        data: data,
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateProduct(int id, Map<String, dynamic> data) async {
    await _loadCredentials();
    try {
      final response = await _dio.put(
        '$_baseUrl/wp-json/wc/v3/products/$id',
        data: data,
        options: Options(headers: _basicAuthHeader()),
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> deleteProduct(int id) async {
    await _loadCredentials();
    try {
      await _dio.delete(
        '$_baseUrl/wp-json/wc/v3/products/$id',
        queryParameters: {'force': true},
        options: Options(headers: _basicAuthHeader()),
      );
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<Map<String, dynamic>> getRevenueStats({
    String? after,
    String? before,
    String? interval,
    int? perPage,
  }) async {
    await _loadCredentials();
    try {
      final Map<String, dynamic> params = {};
      if (after != null) params['after'] = after;
      if (before != null) params['before'] = before;
      if (interval != null) params['interval'] = interval;
      // The stats `intervals` array is itself paginated (default per_page=10).
      // For hourly (24) / daily-in-month (31) / monthly-in-year (12) ranges the
      // default truncates the series, leaving the later buckets empty. Request
      // enough rows to cover the whole window (max allowed is 100).
      if (perPage != null) params['per_page'] = perPage;

      final response = await _traced(
        'getRevenueStats(interval:${interval ?? '-'})',
        () => _dio.get(
          '$_baseUrl/wp-json/wc-analytics/reports/revenue/stats',
          queryParameters: _urlParams(params),
          options: Options(headers: _basicAuthHeader()),
        ),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Returns `{productId: firstImageUrl}` for the given [productIds], sourced
  /// from the products endpoint the same way the All Products screen is (i.e.
  /// `images[0].src`). Used to backfill Top Products thumbnails when the
  /// analytics report omits images in `extended_info`. Batched to respect the
  /// products endpoint's per-page cap; only `id,images` are requested.
  Future<Map<int, String>> getProductImages(List<int> productIds) async {
    final result = <int, String>{};
    if (productIds.isEmpty) return result;
    await _loadCredentials();
    const batchSize = 100;
    try {
      for (var i = 0; i < productIds.length; i += batchSize) {
        final end = (i + batchSize) > productIds.length
            ? productIds.length
            : (i + batchSize);
        final batch = productIds.sublist(i, end);
        final response = await _traced(
          'getProductImages(${batch.length})',
          () => _dio.get(
            '$_baseUrl/wp-json/wc/v3/products',
            queryParameters: _urlParams({
              'include': batch.join(','),
              'per_page': batch.length,
              '_fields': 'id,images',
            }),
            options: Options(headers: _basicAuthHeader()),
          ),
        );
        for (final p in (response.data as List)) {
          if (p is! Map) continue;
          final id = int.tryParse(p['id']?.toString() ?? '');
          final images = p['images'];
          if (id == null || images is! List || images.isEmpty) continue;
          final first = images.first;
          final src = first is Map ? first['src']?.toString() : null;
          if (src != null && src.isNotEmpty) result[id] = src;
        }
      }
      return result;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  /// Analytics products report — items_sold/net_revenue per product for a date
  /// range. Used by the product-performance "Top Products" ranking. Pass
  /// [extendedInfo] to get the product name/image/price in `extended_info`.
  Future<List<dynamic>> getProductsReport({
    String? after,
    String? before,
    String orderBy = 'items_sold',
    String order = 'desc',
    int page = 1,
    int perPage = 100,
    bool extendedInfo = true,
  }) async {
    await _loadCredentials();
    try {
      final Map<String, dynamic> params = {
        'order_by': orderBy,
        'order': order,
        'page': page,
        'per_page': perPage,
        'extended_info': extendedInfo,
      };
      if (after != null) params['after'] = after;
      if (before != null) params['before'] = before;

      final response = await _traced(
        'getProductsReport(orderBy:$orderBy,page:$page)',
        () => _dio.get(
          '$_baseUrl/wp-json/wc-analytics/reports/products',
          queryParameters: _urlParams(params),
          options: Options(headers: _basicAuthHeader()),
        ),
      );
      return response.data as List<dynamic>;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }
}