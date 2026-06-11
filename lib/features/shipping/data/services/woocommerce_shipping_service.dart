import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:woo_management_app/core/network/app_http_client.dart';
import 'package:woo_management_app/core/services/crediential_storage_service.dart';
import 'package:woo_management_app/core/utils/app_logger.dart';
import 'package:woo_management_app/core/utils/store_time.dart';
import '../models/shipment_order.dart';

/// Service to fetch shipping data from WooCommerce API
class WooCommerceShippingService {
  static const String _apiPath = '/wp-json/wc/v3';

  /// Network timeout — requests that exceed this fail fast so loading states
  /// resolve and callers can fall back to cached data instead of hanging.
  static const Duration _timeout = Duration(seconds: 30);

  /// One shared platform-native client (NSURLSession on iOS → HTTP/2, so all
  /// parallel calls multiplex over one connection instead of starving the
  /// dart:io connection pool).
  static final http.Client _client = createAppHttpClient();

  // Coalesces concurrent stats requests (home dashboard + shipping tab both
  // ask at startup) into a single in-flight fetch — keyed by date range so
  // each time period coalesces independently.
  static final Map<String, Future<ShipmentStats>> _statsInFlight = {};

  // In-memory credential cache — avoids repeated Keychain reads
  static Map<String, String>? _credCache;
  static DateTime? _credCachedAt;

  // In-memory stats cache — avoids re-fetching on every screen visit.
  // Keyed by date range so each selected period is cached independently.
  static final Map<String, ShipmentStats> _statsCache = {};
  static final Map<String, DateTime> _statsCachedAt = {};
  static const _statsTtl = Duration(minutes: 5);

  /// Cache/in-flight key for a stats date range.
  static String _statsKey(DateTime? after, DateTime? before) =>
      '${after?.toIso8601String() ?? '-'}|${before?.toIso8601String() ?? '-'}';

  static Future<Map<String, String>?> _getCredentials() async {
    if (_credCache != null &&
        _credCachedAt != null &&
        DateTime.now().difference(_credCachedAt!).inMinutes < 30) {
      return _credCache;
    }
    final storage = CredentialStorageService();
    final credentials = await storage.getCredentials();
    final baseUrl = credentials['wooUrl'];
    final consumerKey = credentials['wooKey'];
    final consumerSecret = credentials['wooSecret'];
    if (baseUrl == null || consumerKey == null || consumerSecret == null) {
      return null;
    }
    _credCache = {
      'base_url': baseUrl,
      'consumer_key': consumerKey,
      'consumer_secret': consumerSecret,
    };
    _credCachedAt = DateTime.now();
    return _credCache;
  }

  /// Clear credential cache (call after credential update)
  static void clearCredentialCache() {
    _credCache = null;
    _credCachedAt = null;
  }

  /// Clear stats cache (call to force refresh)
  static void clearStatsCache() {
    _statsCache.clear();
    _statsCachedAt.clear();
  }

  /// Fetch all orders with shipping info
  static Future<List<ShipmentOrder>> fetchShipments({
    int page = 1,
    int perPage = 100,
    String? status,
    DateTime? after,
    DateTime? before,
  }) async {
    try {
      final credentials = await _getCredentials();
      if (credentials == null) {
        throw Exception('WooCommerce credentials not found');
      }

      final queryParams = <String, String>{
        'consumer_key': credentials['consumer_key']!,
        'consumer_secret': credentials['consumer_secret']!,
        'per_page': perPage.toString(),
        'page': page.toString(),
        'orderby': 'date',
        'order': 'desc',
      };

      if (status != null) queryParams['status'] = status;
      // Stamp the store's UTC offset so WooCommerce filters in the store's
      // timezone, not the device's (the boundaries are store wall-clock).
      if (after != null) queryParams['after'] = StoreTime.toApiString(after);
      if (before != null) queryParams['before'] = StoreTime.toApiString(before);

      final baseUrl = credentials['base_url']!;
      final uri = Uri.parse('$baseUrl$_apiPath/orders').replace(
        queryParameters: queryParams,
      );

      final sw = Stopwatch()..start();
      AppLog.net('WooShipping',
          'fetchShipments(status:${status ?? '-'}, perPage:$perPage) → request START');

      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final shipments = jsonList
            .map((json) => ShipmentOrder.fromWooCommerceJson(json))
            .toList();
        AppLog.ok('WooShipping',
            'fetchShipments → ${shipments.length} orders in ${sw.elapsedMilliseconds}ms');
        return shipments;
      } else {
        throw Exception('Failed to fetch shipments: ${response.statusCode}');
      }
    } on TimeoutException {
      AppLog.timeout('WooShipping', 'fetchShipments → TIMEOUT after 30s');
      throw Exception('Request timed out while fetching shipments');
    } catch (e) {
      AppLog.error('WooShipping', 'fetchShipments → FAILED: $e');
      throw Exception('Failed to fetch shipments: $e');
    }
  }

  /// Fetch ALL orders matching the filters by walking every page (not capped
  /// at a single page of 100). Bounded by [maxPages] as a runaway safety net.
  static Future<List<ShipmentOrder>> fetchAllShipments({
    String? status,
    DateTime? after,
    DateTime? before,
    int perPage = 100,
    int maxPages = 50,
  }) async {
    final all = <ShipmentOrder>[];
    final sw = Stopwatch()..start();
    for (var page = 1; page <= maxPages; page++) {
      final batch = await fetchShipments(
        status: status,
        after: after,
        before: before,
        page: page,
        perPage: perPage,
      );
      all.addAll(batch);
      if (batch.length < perPage) break; // last page reached
    }
    AppLog.ok('WooShipping',
        'fetchAllShipments(status:${status ?? '-'}) → ${all.length} total orders in ${sw.elapsedMilliseconds}ms');
    return all;
  }

  /// Get total count of orders for a specific status via header (lightweight).
  /// Optionally scoped to a date range via [after]/[before].
  static Future<int> getOrderCountForStatus(
    String status, {
    DateTime? after,
    DateTime? before,
  }) async {
    try {
      final credentials = await _getCredentials();
      if (credentials == null) return 0;

      final queryParams = <String, String>{
        'consumer_key': credentials['consumer_key']!,
        'consumer_secret': credentials['consumer_secret']!,
        'status': status,
        'per_page': '1',
      };
      // Stamp the store's UTC offset so WooCommerce filters in the store's
      // timezone, not the device's (the boundaries are store wall-clock).
      if (after != null) queryParams['after'] = StoreTime.toApiString(after);
      if (before != null) queryParams['before'] = StoreTime.toApiString(before);

      final baseUrl = credentials['base_url']!;
      final uri = Uri.parse('$baseUrl$_apiPath/orders').replace(
        queryParameters: queryParams,
      );

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final totalStr = response.headers['x-wp-total'];
        if (totalStr != null) return int.tryParse(totalStr) ?? 0;
      }
      return 0;
    } on TimeoutException {
      AppLog.timeout('WooShipping', 'getOrderCountForStatus($status) → TIMEOUT after 30s');
      return 0;
    } catch (e) {
      AppLog.error('WooShipping', 'getOrderCountForStatus($status) → FAILED: $e');
      return 0;
    }
  }

  /// Get shipment statistics for dashboard cards.
  /// All 5 API calls run in parallel; result is cached for 5 minutes.
  /// Concurrent callers share a single in-flight request.
  /// Optionally scoped to a date range via [after]/[before].
  static Future<ShipmentStats> getShipmentStats({
    bool forceRefresh = false,
    DateTime? after,
    DateTime? before,
  }) async {
    final key = _statsKey(after, before);

    final cachedAt = _statsCachedAt[key];
    if (!forceRefresh &&
        _statsCache[key] != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _statsTtl) {
      AppLog.cache('WooShipping', 'getShipmentStats → returning in-memory cached stats');
      return _statsCache[key]!;
    }

    // Join an already-running fetch instead of starting another fan-out.
    final inFlight = _statsInFlight[key];
    if (inFlight != null) {
      AppLog.cache('WooShipping', 'getShipmentStats → joining in-flight request');
      return inFlight;
    }

    final future = _computeShipmentStats(after: after, before: before);
    _statsInFlight[key] = future;
    try {
      final stats = await future;
      _statsCache[key] = stats;
      _statsCachedAt[key] = DateTime.now();
      return stats;
    } finally {
      _statsInFlight.remove(key);
    }
  }

  static Future<ShipmentStats> _computeShipmentStats({
    DateTime? after,
    DateTime? before,
  }) async {
    try {
      // Pre-fetch credentials once so all parallel calls hit the memory cache
      final creds = await _getCredentials();
      if (creds == null) throw Exception('WooCommerce credentials not found');

      // All 5 operations run in parallel. Active orders are fetched across ALL
      // pages so in-transit isn't undercounted when there are >100 of them.
      final results = await Future.wait([
        getOrderCountForStatus('completed', after: after, before: before),
        getOrderCountForStatus('pending', after: after, before: before),
        getOrderCountForStatus('processing', after: after, before: before),
        getOrderCountForStatus('cancelled', after: after, before: before),
        fetchAllShipments(status: 'processing,pending', after: after, before: before),
      ]);

      final completedCount  = results[0] as int;
      final pendingCount    = results[1] as int;
      final processingCount = results[2] as int;
      final cancelledCount  = results[3] as int;
      final activeShipments = results[4] as List<ShipmentOrder>;

      int inTransit = 0;
      for (final shipment in activeShipments) {
        if (shipment.status == 'in_transit') inTransit++;
      }

      int pending = pendingCount + processingCount - inTransit;
      if (pending < 0) pending = 0;

      final total = pending + inTransit + completedCount;

      final stats = ShipmentStats(
        pending: pending,
        inTransit: inTransit,
        delivered: completedCount,
        cancelled: cancelledCount,
        total: total,
      );

      AppLog.ok('WooShipping',
          'getShipmentStats computed — pending:$pending transit:$inTransit '
          'delivered:$completedCount total:$total');

      return stats;
    } catch (e) {
      AppLog.error('WooShipping', 'getShipmentStats → FAILED: $e');
      rethrow;
    }
  }

  /// Fetch a single order by ID
  static Future<ShipmentOrder?> fetchShipmentById(int orderId) async {
    try {
      final credentials = await _getCredentials();
      if (credentials == null) throw Exception('WooCommerce credentials not found');

      final baseUrl = credentials['base_url']!;
      final uri = Uri.parse('$baseUrl$_apiPath/orders/$orderId').replace(
        queryParameters: {
          'consumer_key': credentials['consumer_key']!,
          'consumer_secret': credentials['consumer_secret']!,
        },
      );

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ShipmentOrder.fromWooCommerceJson(json);
      } else {
        AppLog.error('WooShipping',
            'fetchShipmentById($orderId) → HTTP ${response.statusCode}');
        return null;
      }
    } on TimeoutException {
      AppLog.timeout('WooShipping', 'fetchShipmentById($orderId) → TIMEOUT after 30s');
      return null;
    } catch (e) {
      AppLog.error('WooShipping', 'fetchShipmentById($orderId) → FAILED: $e');
      return null;
    }
  }
}

/// Statistics for shipment dashboard
class ShipmentStats {
  final int pending;
  final int inTransit;
  final int delivered;
  final int cancelled;
  final int total;

  ShipmentStats({
    required this.pending,
    required this.inTransit,
    required this.delivered,
    required this.cancelled,
    required this.total,
  });
}
