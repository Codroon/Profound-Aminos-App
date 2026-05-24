import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotificationPreferenceService {
  static const String _keyOrdersCreate = 'pref_orders_create';
  static const String _keyOrdersUpdate = 'pref_orders_update';
  static const String _keyOrdersRefund = 'pref_orders_refund';

  static const String _keyShipmentCreate = 'pref_shipment_create';
  static const String _keyShipmentUpdate = 'pref_shipment_update';
  static const String _keyShipmentDelivered = 'pref_shipment_delivered';

  static const String _keyGorgiasCreate = 'pref_gorgias_create';
  static const String _keyGorgiasUpdate = 'pref_gorgias_update';
  static const String _keyGorgiasMessage = 'pref_gorgias_message';

  /// Check if a push notification is enabled by user settings based on combined type, title, and body matching.
  static Future<bool> isNotificationEnabled({
    required String type,
    required String title,
    required String body,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final lowerType = type.toLowerCase().trim();
      final lowerTitle = title.toLowerCase().trim();
      final lowerBody = body.toLowerCase().trim();

      debugPrint('[NotificationPreferenceService] Filtering notification: type="$type", title="$title", body="$body"');

      // Helper helper to check matches across all three fields
      bool matches(String term1, [String? term2, String? term3]) {
        bool matchField(String field) {
          if (!field.contains(term1)) return false;
          if (term2 != null && !field.contains(term2)) return false;
          if (term3 != null && !field.contains(term3)) return false;
          return true;
        }
        return matchField(lowerType) || matchField(lowerTitle) || matchField(lowerBody);
      }

      // 1. Orders
      if (matches('order') || matches('refund')) {
        if (matches('order', 'create') || matches('order', 'new') || matches('order', 'placed') || matches('order', 'receiv')) {
          final isEnabled = prefs.getBool(_keyOrdersCreate) ?? true;
          debugPrint('-> Order Create: $isEnabled');
          return isEnabled;
        }
        if (matches('order', 'refund') || matches('order', 'cancel') || matches('refund')) {
          final isEnabled = prefs.getBool(_keyOrdersRefund) ?? true;
          debugPrint('-> Order Refund: $isEnabled');
          return isEnabled;
        }
        // Fallback for general status changes/updates
        if (matches('order', 'update') || matches('order', 'status') || matches('order', 'process') || matches('order', 'complet') || matches('order', 'shipped')) {
          final isEnabled = prefs.getBool(_keyOrdersUpdate) ?? true;
          debugPrint('-> Order Update: $isEnabled');
          return isEnabled;
        }
      }

      // 2. Shipments / Tracking
      if (matches('shipment') || matches('tracking') || matches('shipping')) {
        if (matches('deliver') || matches('arriv')) {
          final isEnabled = prefs.getBool(_keyShipmentDelivered) ?? true;
          debugPrint('-> Shipment Delivered: $isEnabled');
          return isEnabled;
        }
        if (matches('update') || matches('transit') || matches('depart') || matches('in_transit')) {
          final isEnabled = prefs.getBool(_keyShipmentUpdate) ?? true;
          debugPrint('-> Shipment Update: $isEnabled');
          return isEnabled;
        }
        if (matches('create') || matches('new') || matches('label') || matches('initi')) {
          final isEnabled = prefs.getBool(_keyShipmentCreate) ?? true;
          debugPrint('-> Shipment Create: $isEnabled');
          return isEnabled;
        }
      }

      // 3. Gorgias Helpdesk
      if (matches('ticket') || matches('message') || matches('gorgias') || matches('support') || matches('chat')) {
        if (matches('message') || matches('repl') || matches('chat') || matches('respond')) {
          final isEnabled = prefs.getBool(_keyGorgiasMessage) ?? true;
          debugPrint('-> Gorgias Message: $isEnabled');
          return isEnabled;
        }
        if (matches('ticket', 'create') || matches('ticket', 'new') || matches('ticket', 'open')) {
          final isEnabled = prefs.getBool(_keyGorgiasCreate) ?? true;
          debugPrint('-> Gorgias Ticket Create: $isEnabled');
          return isEnabled;
        }
        if (matches('ticket', 'update') || matches('ticket', 'assign') || matches('ticket', 'status') || matches('ticket', 'close')) {
          final isEnabled = prefs.getBool(_keyGorgiasUpdate) ?? true;
          debugPrint('-> Gorgias Ticket Update: $isEnabled');
          return isEnabled;
        }
      }

      // 4. Default Fallback String Matches for absolute keys
      switch (lowerType) {
        case 'order_created':
        case 'order_create':
          return prefs.getBool(_keyOrdersCreate) ?? true;
        case 'order_updated':
        case 'order_update':
          return prefs.getBool(_keyOrdersUpdate) ?? true;
        case 'order_refunded':
        case 'order_refund':
          return prefs.getBool(_keyOrdersRefund) ?? true;
        case 'shipment_created':
        case 'shipment_create':
          return prefs.getBool(_keyShipmentCreate) ?? true;
        case 'tracking_updated':
        case 'tracking_update':
          return prefs.getBool(_keyShipmentUpdate) ?? true;
        case 'tracking_delivered':
        case 'tracking_deliver':
          return prefs.getBool(_keyShipmentDelivered) ?? true;
        case 'ticket_created':
        case 'ticket_create':
          return prefs.getBool(_keyGorgiasCreate) ?? true;
        case 'ticket_updated':
        case 'ticket_update':
          return prefs.getBool(_keyGorgiasUpdate) ?? true;
        case 'message_created':
        case 'message_create':
          return prefs.getBool(_keyGorgiasMessage) ?? true;
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  /// Backward compatibility helper for pure types
  static Future<bool> isEnabled(String type) async {
    return isNotificationEnabled(type: type, title: '', body: '');
  }
}
