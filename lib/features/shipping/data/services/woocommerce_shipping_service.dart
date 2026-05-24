import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:woo_management_app/core/services/crediential_storage_service.dart';
import '../models/shipment_order.dart';

/// Service to fetch shipping data from WooCommerce API
class WooCommerceShippingService {
  static const String _apiPath = '/wp-json/wc/v3';

  /// Get WooCommerce credentials and base URL from secure storage
  static Future<Map<String, String>?> _getCredentials() async {
    final storage = CredentialStorageService();
    final credentials = await storage.getCredentials();
    
    final baseUrl = credentials['wooUrl'];
    final consumerKey = credentials['wooKey'];
    final consumerSecret = credentials['wooSecret'];
    
    if (baseUrl == null || consumerKey == null || consumerSecret == null) {
      return null;
    }
    
    return {
      'base_url': baseUrl,
      'consumer_key': consumerKey,
      'consumer_secret': consumerSecret,
    };
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

      // Build query parameters
      final queryParams = <String, String>{
        'consumer_key': credentials['consumer_key']!,
        'consumer_secret': credentials['consumer_secret']!,
        'per_page': perPage.toString(),
        'page': page.toString(),
        'orderby': 'date',
        'order': 'desc',
      };

      // Add status filter if provided (e.g., 'processing,completed')
      if (status != null) {
        queryParams['status'] = status;
      }

      // Add date filters
      if (after != null) {
        queryParams['after'] = after.toIso8601String();
      }
      if (before != null) {
        queryParams['before'] = before.toIso8601String();
      }

      final baseUrl = credentials['base_url']!;
      final uri = Uri.parse('$baseUrl$_apiPath/orders').replace(
        queryParameters: queryParams,
      );

      developer.log('Fetching shipments from: $uri', name: 'WooCommerceShipping');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final shipments = jsonList
            .map((json) => ShipmentOrder.fromWooCommerceJson(json))
            .toList();
        
        developer.log(
          'Fetched ${shipments.length} shipments',
          name: 'WooCommerceShipping',
        );
        
        return shipments;
      } else {
        developer.log(
          'Error fetching shipments: ${response.statusCode} - ${response.body}',
          name: 'WooCommerceShipping',
        );
        throw Exception('Failed to fetch shipments: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Exception fetching shipments: $e', name: 'WooCommerceShipping');
      throw Exception('Failed to fetch shipments: $e');
    }
  }

  /// Get total count of orders for a specific status
  static Future<int> getOrderCountForStatus(String status) async {
    try {
      final credentials = await _getCredentials();
      if (credentials == null) return 0;

      final baseUrl = credentials['base_url']!;
      final uri = Uri.parse('$baseUrl$_apiPath/orders').replace(
        queryParameters: {
          'consumer_key': credentials['consumer_key']!,
          'consumer_secret': credentials['consumer_secret']!,
          'status': status,
          'per_page': '1', // Extremely lightweight request, just to get total count header
        },
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final totalStr = response.headers['x-wp-total'];
        if (totalStr != null) {
          return int.tryParse(totalStr) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      developer.log('Error getting order count for $status: $e', name: 'WooCommerceShipping');
      return 0;
    }
  }

  /// Get shipment statistics for dashboard cards
  static Future<ShipmentStats> getShipmentStats() async {
    try {
      // 1. Get true lifetime total counts via API headers
      final completedCount = await getOrderCountForStatus('completed');
      final pendingCount = await getOrderCountForStatus('pending');
      final processingCount = await getOrderCountForStatus('processing');
      final cancelledCount = await getOrderCountForStatus('cancelled');

      // 2. Fetch current processing/pending orders (up to 100) to check for transit status
      final activeShipments = await fetchShipments(
        status: 'processing,pending',
        perPage: 100,
      );

      int inTransit = 0;
      for (final shipment in activeShipments) {
        if (shipment.status == 'in_transit') {
          inTransit++;
        }
      }

      // Remaining processing + pending that are not in transit
      int pending = pendingCount + processingCount - inTransit;
      if (pending < 0) pending = 0;

      final total = pending + inTransit + completedCount;

      return ShipmentStats(
        pending: pending,
        inTransit: inTransit,
        delivered: completedCount,
        cancelled: cancelledCount,
        total: total,
      );
    } catch (e) {
      developer.log('Error getting shipment stats: $e', name: 'WooCommerceShipping');
      rethrow;
    }
  }

  /// Fetch a single order by ID
  static Future<ShipmentOrder?> fetchShipmentById(int orderId) async {
    try {
      final credentials = await _getCredentials();
      if (credentials == null) {
        throw Exception('WooCommerce credentials not found');
      }

      final baseUrl = credentials['base_url']!;
      final uri = Uri.parse('$baseUrl$_apiPath/orders/$orderId').replace(
        queryParameters: {
          'consumer_key': credentials['consumer_key']!,
          'consumer_secret': credentials['consumer_secret']!,
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ShipmentOrder.fromWooCommerceJson(json);
      } else {
        developer.log(
          'Error fetching order $orderId: ${response.statusCode}',
          name: 'WooCommerceShipping',
        );
        return null;
      }
    } catch (e) {
      developer.log('Exception fetching order $orderId: $e', name: 'WooCommerceShipping');
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
