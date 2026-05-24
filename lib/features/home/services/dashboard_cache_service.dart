import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

class DashboardCacheService {
  static const String _cacheKey = 'dashboard_cache';
  static const String _timestampKey = 'dashboard_cache_timestamp';
  
  // Cache duration - 7 days
  static const Duration _cacheValidity = Duration(days: 7);
  
  /// Save dashboard data to local storage
  static Future<void> saveCache(DashboardCacheData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(data.toJson());
      await prefs.setString(_cacheKey, jsonData);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
      developer.log('Dashboard data cached successfully', name: 'DashboardCache');
    } catch (e) {
      developer.log('Failed to cache dashboard data: $e', name: 'DashboardCache');
    }
  }
  
  /// Load cached dashboard data if available and valid
  static Future<DashboardCacheData?> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      final timestamp = prefs.getInt(_timestampKey);
      
      if (jsonString == null || timestamp == null) {
        developer.log('No cached dashboard data found', name: 'DashboardCache');
        return null;
      }
      
      // Check if cache is still valid
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final age = DateTime.now().difference(cacheTime);
      
      if (age > _cacheValidity) {
        developer.log('Dashboard cache expired (age: $age)', name: 'DashboardCache');
        await clearCache();
        return null;
      }
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      developer.log('Dashboard cache loaded (age: $age)', name: 'DashboardCache');
      return DashboardCacheData.fromJson(jsonData);
    } catch (e) {
      developer.log('Failed to load dashboard cache: $e', name: 'DashboardCache');
      return null;
    }
  }
  
  /// Clear the cache
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_timestampKey);
      developer.log('Dashboard cache cleared', name: 'DashboardCache');
    } catch (e) {
      developer.log('Failed to clear dashboard cache: $e', name: 'DashboardCache');
    }
  }
  
  /// Check if cache exists and is valid
  static Future<bool> hasValidCache() async {
    final cache = await loadCache();
    return cache != null;
  }
}

/// Data model for cached dashboard data
class DashboardCacheData {
  final int totalProductCount;
  final double revenue;
  final int thisMonthOrderCount;
  final int totalOrderCount;
  final String currentMonthLabel;
  final List<dynamic> recentOrders;
  final DateTime cachedAt;
  // Gorgias ticket stats
  final int? gorgiasOpenTickets;
  final int? gorgiasClosedTickets;
  final int? gorgiasTotalTickets;
  // Shipping stats
  final int? shippingPending;
  final int? shippingInTransit;
  final int? shippingDelivered;
  final int? shippingTotal;

  DashboardCacheData({
    required this.totalProductCount,
    required this.revenue,
    required this.thisMonthOrderCount,
    required this.totalOrderCount,
    required this.currentMonthLabel,
    required this.recentOrders,
    required this.cachedAt,
    this.gorgiasOpenTickets,
    this.gorgiasClosedTickets,
    this.gorgiasTotalTickets,
    this.shippingPending,
    this.shippingInTransit,
    this.shippingDelivered,
    this.shippingTotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'totalProductCount': totalProductCount,
      'revenue': revenue,
      'thisMonthOrderCount': thisMonthOrderCount,
      'totalOrderCount': totalOrderCount,
      'currentMonthLabel': currentMonthLabel,
      'recentOrders': recentOrders,
      'cachedAt': cachedAt.toIso8601String(),
      'gorgiasOpenTickets': gorgiasOpenTickets,
      'gorgiasClosedTickets': gorgiasClosedTickets,
      'gorgiasTotalTickets': gorgiasTotalTickets,
      'shippingPending': shippingPending,
      'shippingInTransit': shippingInTransit,
      'shippingDelivered': shippingDelivered,
      'shippingTotal': shippingTotal,
    };
  }

  factory DashboardCacheData.fromJson(Map<String, dynamic> json) {
    return DashboardCacheData(
      totalProductCount: json['totalProductCount'] as int,
      revenue: json['revenue'] as double,
      thisMonthOrderCount: json['thisMonthOrderCount'] as int,
      totalOrderCount: json['totalOrderCount'] as int,
      currentMonthLabel: json['currentMonthLabel'] as String,
      recentOrders: json['recentOrders'] as List<dynamic>,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      gorgiasOpenTickets: json['gorgiasOpenTickets'] as int?,
      gorgiasClosedTickets: json['gorgiasClosedTickets'] as int?,
      gorgiasTotalTickets: json['gorgiasTotalTickets'] as int?,
      shippingPending: json['shippingPending'] as int?,
      shippingInTransit: json['shippingInTransit'] as int?,
      shippingDelivered: json['shippingDelivered'] as int?,
      shippingTotal: json['shippingTotal'] as int?,
    );
  }
}
