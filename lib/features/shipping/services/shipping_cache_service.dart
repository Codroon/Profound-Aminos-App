import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/app_logger.dart';
import '../data/models/shipment_order.dart';
import '../data/services/woocommerce_shipping_service.dart';

/// Persistent (disk-backed) cache for the shipping dashboard so the screen can
/// render instantly on cold start while fresh data loads in the background —
/// mirroring the dashboard's DashboardCacheService.
class ShippingCacheService {
  static const String _key = 'shipping_dashboard_cache';

  /// How long cached data is considered usable for display. Data is always
  /// refreshed in the background regardless; this just bounds staleness.
  static const Duration _validity = Duration(days: 7);

  static Future<void> save({
    required ShipmentStats stats,
    required List<ShipmentOrder> shipments,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = {
        'cachedAt': DateTime.now().toIso8601String(),
        'stats': {
          'pending': stats.pending,
          'inTransit': stats.inTransit,
          'delivered': stats.delivered,
          'cancelled': stats.cancelled,
          'total': stats.total,
        },
        // Only persist the few shipments the dashboard actually shows.
        'shipments':
            shipments.take(10).map((s) => s.toCacheJson()).toList(),
      };
      await prefs.setString(_key, jsonEncode(payload));
      AppLog.cache('Shipping', 'Saved cache (${shipments.length} shipments)');
    } catch (e) {
      AppLog.error('Shipping', 'Failed to save cache: $e');
    }
  }

  static Future<ShippingCacheData?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;

      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.parse(map['cachedAt'] as String);
      if (DateTime.now().difference(cachedAt) > _validity) {
        await clear();
        return null;
      }

      final statsMap = (map['stats'] as Map).cast<String, dynamic>();
      final stats = ShipmentStats(
        pending: statsMap['pending'] as int? ?? 0,
        inTransit: statsMap['inTransit'] as int? ?? 0,
        delivered: statsMap['delivered'] as int? ?? 0,
        cancelled: statsMap['cancelled'] as int? ?? 0,
        total: statsMap['total'] as int? ?? 0,
      );

      final shipments = (map['shipments'] as List<dynamic>? ?? [])
          .map((s) =>
              ShipmentOrder.fromCacheJson((s as Map).cast<String, dynamic>()))
          .toList();

      return ShippingCacheData(
        stats: stats,
        shipments: shipments,
        cachedAt: cachedAt,
      );
    } catch (e) {
      AppLog.error('Shipping', 'Failed to load cache: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class ShippingCacheData {
  final ShipmentStats stats;
  final List<ShipmentOrder> shipments;
  final DateTime cachedAt;

  ShippingCacheData({
    required this.stats,
    required this.shipments,
    required this.cachedAt,
  });
}
