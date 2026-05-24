import 'package:dio/dio.dart';
import '../../../core/services/reach_ship_service.dart';
import '../models/models.dart';

class ReachShipRepository {
  ReachShipService? _reachShipService;
  final Future<ReachShipService> _serviceInitializer;

  ReachShipRepository({
    required Future<ReachShipService> reachShipService,
    Dio? dio,
  }) : _serviceInitializer = reachShipService;

  /// Ensure the ReachShip service is initialized
  Future<ReachShipService> _ensureService() async {
    _reachShipService ??= await _serviceInitializer;
    return _reachShipService!;
  }

  /// Get shipping rates for a shipment
  Future<List<ShippingRate>> getRates({
    required Address fromAddress,
    required Address toAddress,
    required List<Package> packages,
    List<String>? carrierIds,
    List<String>? serviceTypes,
  }) async {
    try {
      final service = await _ensureService();
      final response = await service.getRates(
        shipTo: toAddress.toJson(),
        shipFrom: fromAddress.toJson(),
        packages: packages.map((p) => p.toJson()).toList(),
      );

      final rates =
          (response['rates'] as List<dynamic>? ?? [])
              .map(
                (rate) => ShippingRate.fromJson(rate as Map<String, dynamic>),
              )
              .toList();
      return rates;
    } catch (e) {
      throw Exception('Error getting rates: $e');
    }
  }

  /// Create a shipment
  Future<Shipment> createShipment({
    required Address fromAddress,
    required Address toAddress,
    required List<Package> packages,
    required String carrier,
    String? orderId,
    Map<String, dynamic>? metadata,
    DateTime? shipDate,
  }) async {
    try {
      final service = await _ensureService();
      final response = await service.createShipment(
        carrier: {'name': carrier},
        shipTo: toAddress.toJson(),
        shipFrom: fromAddress.toJson(),
        packages: packages.map((p) => p.toJson()).toList(),
        shipDate: (shipDate ?? DateTime.now()).toIso8601String(),
      );

      return Shipment.fromJson(response);
    } catch (e) {
      throw Exception('Error creating shipment: $e');
    }
  }

  // Note: ReachShip API does not provide a direct endpoint to get shipment by ID
  // This method is removed as it's not supported by the API

  /// Get list of shipments
  Future<List<Shipment>> getShipments({
    int? limit,
    int? offset,
    String? status,
    String? orderId,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    try {
      final service = await _ensureService();
      final response = await service.getShipments(
        limit: limit,
        offset: offset,
        status: status,
        orderId: orderId,
        createdAfter: createdAfter,
        createdBefore: createdBefore,
      );

      final shipments =
          (response['shipments'] as List<dynamic>? ?? [])
              .map(
                (shipment) =>
                    Shipment.fromJson(shipment as Map<String, dynamic>),
              )
              .toList();
      return shipments;
    } catch (e) {
      throw Exception('Error getting shipments: $e');
    }
  }

  // Note: Label generation is handled during shipment creation via createShipment
  // This separate method is removed as it's not supported by the API

  /// Delete shipments
  Future<bool> deleteShipments({
    required String carrierName,
    List<String>? shipmentIds,
    List<String>? trackingIds,
    List<String>? orderIds,
    String? accountName,
  }) async {
    try {
      final service = await _ensureService();
      await service.deleteShipments(
        carrierName: carrierName,
        shipmentIds: shipmentIds,
        trackingIds: trackingIds,
        orderIds: orderIds,
        accountName: accountName,
      );
      return true;
    } catch (e) {
      throw Exception('Error deleting shipments: $e');
    }
  }

  /// Schedule pickup
  Future<Map<String, dynamic>> schedulePickup({
    required String carrierName,
    required DateTime pickupDate,
    required Address pickupAddress,
    String? instructions,
    List<String>? shipmentIds,
  }) async {
    try {
      final service = await _ensureService();
      
      // Transform parameters to match ReachShip API format
      final shipper = pickupAddress.toJson();
      final carrier = {'name': carrierName};
      final pickupWindow = {
        'pickup_date': pickupDate.toIso8601String().split('T')[0],
        'ready_time': '09:00',
        'close_time': '17:00',
      };
      final packages = <Map<String, dynamic>>[];
      final trackingIds = shipmentIds ?? <String>[];
      
      final response = await service.schedulePickup(
        shipper: shipper,
        carrier: carrier,
        pickupWindow: pickupWindow,
        packages: packages,
        trackingIds: trackingIds,
        pickupOptions: instructions != null ? {'instructions': instructions} : null,
      );
      return response;
    } catch (e) {
      throw Exception('Error scheduling pickup: $e');
    }
  }

  /// Cancel pickup
  Future<bool> cancelPickup(String carrierName, {String? accountName}) async {
    try {
      final service = await _ensureService();
      await service.cancelPickup(
        carrierName: carrierName,
        accountName: accountName,
      );
      return true;
    } catch (e) {
      throw Exception('Error cancelling pickup: $e');
    }
  }

  /// Track shipment
  Future<Map<String, dynamic>> trackShipment({
    required String carrierName,
    required String trackingNumber,
    String? accountName,
  }) async {
    try {
      final service = await _ensureService();
      final response = await service.trackShipment(
        carrierName: carrierName,
        trackingNumber: trackingNumber,
        accountName: accountName,
      );
      return response;
    } catch (e) {
      throw Exception('Error tracking shipment: $e');
    }
  }

  // Note: ReachShip API does not provide address validation endpoint
  // This method is removed as it's not supported by the API

  /// Get carriers
  Future<List<Map<String, dynamic>>> getCarriers() async {
    try {
      final service = await _ensureService();
      final response = await service.getCarrierCredentialsSummary();
      return (response['carriers'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Error getting carriers: $e');
    }
  }

  /// Save carrier credentials
  Future<bool> saveCarrierCredentials({
    required String carrierName,
    required Map<String, dynamic> credentials,
    String? accountName,
  }) async {
    try {
      final service = await _ensureService();
      await service.saveCarrierCredentials(
        carrier: carrierName,
        accountName: accountName ?? 'default',
        credentials: credentials,
      );
      return true;
    } catch (e) {
      throw Exception('Error saving carrier credentials: $e');
    }
  }

  /// Update carrier credentials
  Future<bool> updateCarrierCredentials({
    required String carrierName,
    required Map<String, dynamic> credentials,
    String? accountName,
  }) async {
    try {
      final service = await _ensureService();
      await service.updateCarrierCredentials(
        carrier: carrierName,
        accountName: accountName ?? 'default',
        credentials: credentials,
      );
      return true;
    } catch (e) {
      throw Exception('Error updating carrier credentials: $e');
    }
  }

  /// Delete carrier credentials
  Future<bool> deleteCarrierCredentials({
    required String carrierName,
    String? accountName,
  }) async {
    try {
      final service = await _ensureService();
      await service.deleteCarrierCredentials(
        carrier: carrierName,
        accountName: accountName ?? 'default',
      );
      return true;
    } catch (e) {
      throw Exception('Error deleting carrier credentials: $e');
    }
  }

  // Note: ReachShip API does not provide a direct shipment cancellation endpoint
  // Shipments can be deleted using deleteShipments method instead

  // Note: ReachShip API does not provide shipment update functionality
  // This method is removed as it's not supported by the API

  // Note: Labels are generated during shipment creation via createShipment
  // This separate method is removed as it's not supported by the API

  // Note: Tracking is handled via trackShipment method with carrier and tracking number
  // This method is removed as it relied on the unsupported getShipment endpoint

  /// Get carrier services
  Future<List<Map<String, dynamic>>> getCarrierServices({
    required String carrierName,
  }) async {
    try {
      final service = await _ensureService();
      final response = await service.getCarrierCredentialsSummary();

      // Extract services for the specific carrier
      final carriers = response['carriers'] as List<dynamic>? ?? [];
      final carrier = carriers.firstWhere(
        (c) => c['name'] == carrierName,
        orElse: () => {'services': []},
      );

      return List<Map<String, dynamic>>.from(carrier['services'] ?? []);
    } catch (e) {
      throw Exception('Error getting carrier services: $e');
    }
  }

}
