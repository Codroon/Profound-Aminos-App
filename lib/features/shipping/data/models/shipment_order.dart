import 'package:woo_management_app/features/reach_ship/models/address.dart';

/// ShipmentOrder model for WooCommerce orders with tracking info
class ShipmentOrder {
  final int id;
  final String status;
  final DateTime dateCreated;
  final DateTime? dateShipped;
  final String customerName;
  final Address toAddress;
  final Address? fromAddress;
  final List<ShipmentItem> items;
  final String? trackingNumber;
  final String? carrier;
  final String? service;
  final double total;
  final double shippingCost;
  final String? labelUrl;

  ShipmentOrder({
    required this.id,
    required this.status,
    required this.dateCreated,
    this.dateShipped,
    required this.customerName,
    required this.toAddress,
    this.fromAddress,
    required this.items,
    this.trackingNumber,
    this.carrier,
    this.service,
    required this.total,
    required this.shippingCost,
    this.labelUrl,
  });

  factory ShipmentOrder.fromWooCommerceJson(Map<String, dynamic> json) {
    // Parse tracking info from meta_data
    String? trackingNumber;
    String? carrier;
    DateTime? dateShipped;

    final metaData = json['meta_data'] as List<dynamic>?;
    if (metaData != null) {
      for (final meta in metaData) {
        if (meta['key'] == '_wc_shipment_tracking_items') {
          final trackingItems = meta['value'];
          if (trackingItems is List && trackingItems.isNotEmpty) {
            final firstTracking = trackingItems[0];
            trackingNumber = firstTracking['tracking_number']?.toString();
            carrier = firstTracking['tracking_provider']?.toString();
            final shipped = firstTracking['date_shipped']?.toString();
            if (shipped != null) {
              dateShipped = DateTime.tryParse(shipped);
            }
          }
        }
      }
    }

    // Parse shipping address
    final shipping = json['shipping'] as Map<String, dynamic>?;
    final toAddress = Address(
      name: '${shipping?['first_name'] ?? ''} ${shipping?['last_name'] ?? ''}'.trim(),
      street1: shipping?['address_1'] ?? '',
      street2: shipping?['address_2'],
      city: shipping?['city'] ?? '',
      state: shipping?['state'] ?? '',
      postalCode: shipping?['postcode'] ?? '',
      country: shipping?['country'] ?? 'US',
      phone: shipping?['phone'],
    );

    // Parse line items
    final lineItems = json['line_items'] as List<dynamic>? ?? [];
    final items = lineItems.map((item) => ShipmentItem.fromJson(item)).toList();

    // Parse shipping cost
    final shippingLines = json['shipping_lines'] as List<dynamic>? ?? [];
    final double shippingCost = shippingLines.isNotEmpty
        ? (double.tryParse(shippingLines[0]['total']?.toString() ?? '0') ?? 0.0)
        : 0.0;

    // Determine shipment status based on order status and tracking
    final orderStatus = json['status']?.toString() ?? 'pending';
    final shipmentStatus = _determineShipmentStatus(orderStatus, trackingNumber, dateShipped);

    return ShipmentOrder(
      id: json['id'] as int,
      status: shipmentStatus,
      dateCreated: DateTime.parse(json['date_created'] as String),
      dateShipped: dateShipped,
      customerName: '${shipping?['first_name'] ?? ''} ${shipping?['last_name'] ?? ''}'.trim(),
      toAddress: toAddress,
      items: items,
      trackingNumber: trackingNumber,
      carrier: carrier,
      service: shippingLines.isNotEmpty ? shippingLines[0]['method_title']?.toString() : null,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0,
      shippingCost: shippingCost,
    );
  }

  static String _determineShipmentStatus(String orderStatus, String? trackingNumber, DateTime? dateShipped) {
    if (orderStatus == 'completed') return 'delivered';
    if (orderStatus == 'cancelled') return 'cancelled';
    if (trackingNumber != null && dateShipped != null) return 'in_transit';
    if (orderStatus == 'processing') return 'pending';
    return 'pending';
  }

  /// Serialize for local caching (SharedPreferences). Mirrors [fromCacheJson].
  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'status': status,
      'date_created': dateCreated.toIso8601String(),
      'date_shipped': dateShipped?.toIso8601String(),
      'customer_name': customerName,
      'to_address': toAddress.toJson(),
      'from_address': fromAddress?.toJson(),
      'items': items.map((i) => i.toCacheJson()).toList(),
      'tracking_number': trackingNumber,
      'carrier': carrier,
      'service': service,
      'total': total,
      'shipping_cost': shippingCost,
      'label_url': labelUrl,
    };
  }

  /// Rebuild from cached JSON produced by [toCacheJson].
  factory ShipmentOrder.fromCacheJson(Map<String, dynamic> json) {
    return ShipmentOrder(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'pending',
      dateCreated: DateTime.parse(json['date_created'] as String),
      dateShipped: json['date_shipped'] != null
          ? DateTime.tryParse(json['date_shipped'] as String)
          : null,
      customerName: json['customer_name'] as String? ?? '',
      toAddress: Address.fromJson(
          (json['to_address'] as Map?)?.cast<String, dynamic>() ?? {}),
      fromAddress: json['from_address'] != null
          ? Address.fromJson(
              (json['from_address'] as Map).cast<String, dynamic>())
          : null,
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => ShipmentItem.fromCacheJson(
              (i as Map).cast<String, dynamic>()))
          .toList(),
      trackingNumber: json['tracking_number'] as String?,
      carrier: json['carrier'] as String?,
      service: json['service'] as String?,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      shippingCost: (json['shipping_cost'] as num?)?.toDouble() ?? 0,
      labelUrl: json['label_url'] as String?,
    );
  }

  String get displayId => '#${id.toString().padLeft(4, '0')}';

  int get totalItems => items.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get hasTracking => trackingNumber?.isNotEmpty ?? false;

  /// True when there is at least a shipping method to display.
  bool get hasShipmentInfo =>
      (service?.isNotEmpty ?? false) ||
      (carrier?.isNotEmpty ?? false) ||
      (trackingNumber?.isNotEmpty ?? false) ||
      dateShipped != null;
}

class ShipmentItem {
  final int id;
  final String name;
  final int quantity;
  final double price;
  final double weight;

  ShipmentItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    this.weight = 0.5,
  });

  factory ShipmentItem.fromJson(Map<String, dynamic> json) {
    return ShipmentItem(
      id: json['id'] as int,
      name: json['name']?.toString() ?? 'Unknown Product',
      quantity: json['quantity'] as int? ?? 1,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      weight: 0.5,
    );
  }

  Map<String, dynamic> toCacheJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory ShipmentItem.fromCacheJson(Map<String, dynamic> json) {
    return ShipmentItem(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Unknown Product',
      quantity: json['quantity'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}
