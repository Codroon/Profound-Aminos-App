import 'address.dart';
import 'package.dart';
import 'shipping_rate.dart';

enum ShipmentStatus {
  pending,
  created,
  confirmed,
  labelGenerated,
  inTransit,
  outForDelivery,
  delivered,
  exception,
  returned,
  cancelled,
}

class Shipment {
  final String id;
  final String? orderId;
  final Address fromAddress;
  final Address toAddress;
  final List<Package> packages;
  final ShippingRate selectedRate;
  final ShipmentStatus status;
  final String? trackingNumber;
  final String? labelUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;
  final List<TrackingEvent>? trackingEvents;

  const Shipment({
    required this.id,
    this.orderId,
    required this.fromAddress,
    required this.toAddress,
    required this.packages,
    required this.selectedRate,
    required this.status,
    this.trackingNumber,
    this.labelUrl,
    required this.createdAt,
    this.updatedAt,
    this.metadata,
    this.trackingEvents,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id'] as String? ?? '',
      orderId: json['order_id'] as String?,
      fromAddress: Address.fromJson(json['from_address'] as Map<String, dynamic>? ?? {}),
      toAddress: Address.fromJson(json['to_address'] as Map<String, dynamic>? ?? {}),
      packages: (json['packages'] as List<dynamic>?)
          ?.map((e) => Package.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      selectedRate: ShippingRate.fromJson(json['selected_rate'] as Map<String, dynamic>? ?? {}),
      status: _parseStatus(json['status'] as String?),
      trackingNumber: json['tracking_number'] as String?,
      labelUrl: json['label_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      trackingEvents: (json['tracking_events'] as List<dynamic>?)
          ?.map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static ShipmentStatus _parseStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return ShipmentStatus.pending;
      case 'created':
        return ShipmentStatus.created;
      case 'confirmed':
        return ShipmentStatus.confirmed;
      case 'label_generated':
      case 'labelgenerated':
        return ShipmentStatus.labelGenerated;
      case 'in_transit':
      case 'intransit':
        return ShipmentStatus.inTransit;
      case 'out_for_delivery':
      case 'outfordelivery':
        return ShipmentStatus.outForDelivery;
      case 'delivered':
        return ShipmentStatus.delivered;
      case 'exception':
        return ShipmentStatus.exception;
      case 'returned':
        return ShipmentStatus.returned;
      case 'cancelled':
        return ShipmentStatus.cancelled;
      default:
        return ShipmentStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (orderId != null) 'order_id': orderId,
      'from_address': fromAddress.toJson(),
      'to_address': toAddress.toJson(),
      'packages': packages.map((e) => e.toJson()).toList(),
      'selected_rate': selectedRate.toJson(),
      'status': status.name,
      if (trackingNumber != null) 'tracking_number': trackingNumber,
      if (labelUrl != null) 'label_url': labelUrl,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (trackingEvents != null) 
        'tracking_events': trackingEvents!.map((e) => e.toJson()).toList(),
    };
  }

  Shipment copyWith({
    String? id,
    String? orderId,
    Address? fromAddress,
    Address? toAddress,
    List<Package>? packages,
    ShippingRate? selectedRate,
    ShipmentStatus? status,
    String? trackingNumber,
    String? labelUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
    List<TrackingEvent>? trackingEvents,
  }) {
    return Shipment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      fromAddress: fromAddress ?? this.fromAddress,
      toAddress: toAddress ?? this.toAddress,
      packages: packages ?? this.packages,
      selectedRate: selectedRate ?? this.selectedRate,
      status: status ?? this.status,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      labelUrl: labelUrl ?? this.labelUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
      trackingEvents: trackingEvents ?? this.trackingEvents,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ShipmentStatus.pending:
        return 'Pending';
      case ShipmentStatus.created:
        return 'Created';
      case ShipmentStatus.confirmed:
        return 'Confirmed';
      case ShipmentStatus.labelGenerated:
        return 'Label Generated';
      case ShipmentStatus.inTransit:
        return 'In Transit';
      case ShipmentStatus.outForDelivery:
        return 'Out for Delivery';
      case ShipmentStatus.delivered:
        return 'Delivered';
      case ShipmentStatus.exception:
        return 'Exception';
      case ShipmentStatus.returned:
        return 'Returned';
      case ShipmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  String toString() {
    return 'Shipment(id: $id, orderId: $orderId, status: $status, trackingNumber: $trackingNumber, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Shipment &&
        other.id == id &&
        other.orderId == orderId &&
        other.status == status &&
        other.trackingNumber == trackingNumber;
  }

  @override
  int get hashCode {
    return Object.hash(id, orderId, status, trackingNumber);
  }
}

class TrackingEvent {
  final String status;
  final String description;
  final DateTime timestamp;
  final String? location;

  const TrackingEvent({
    required this.status,
    required this.description,
    required this.timestamp,
    this.location,
  });

  factory TrackingEvent.fromJson(Map<String, dynamic> json) {
    return TrackingEvent(
      status: json['status'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      location: json['location'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      if (location != null) 'location': location,
    };
  }

  @override
  String toString() {
    return 'TrackingEvent(status: $status, description: $description, timestamp: $timestamp, location: $location)';
  }
}