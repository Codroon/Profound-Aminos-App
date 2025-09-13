import 'package:equatable/equatable.dart';
import '../models/models.dart';

abstract class ReachShipEvent extends Equatable {
  const ReachShipEvent();

  @override
  List<Object?> get props => [];
}

// Shipping Rates Events
class GetShippingRatesEvent extends ReachShipEvent {
  final Address fromAddress;
  final Address toAddress;
  final List<Package> packages;
  final Map<String, dynamic>? options;

  const GetShippingRatesEvent({
    required this.fromAddress,
    required this.toAddress,
    required this.packages,
    this.options,
  });

  @override
  List<Object?> get props => [fromAddress, toAddress, packages, options];
}

// Shipment Events
class CreateShipmentEvent extends ReachShipEvent {
  final String orderId;
  final Address fromAddress;
  final Address toAddress;
  final List<Package> packages;
  final String rateId;
  final String carrier;
  final Map<String, dynamic>? metadata;

  const CreateShipmentEvent({
    required this.orderId,
    required this.fromAddress,
    required this.toAddress,
    required this.packages,
    required this.rateId,
    required this.carrier,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        orderId,
        fromAddress,
        toAddress,
        packages,
        rateId,
        carrier,
        metadata,
      ];
}

class GetShipmentEvent extends ReachShipEvent {
  final String shipmentId;

  const GetShipmentEvent({required this.shipmentId});

  @override
  List<Object?> get props => [shipmentId];
}

class GetShipmentsEvent extends ReachShipEvent {
  final int? page;
  final int? limit;
  final Map<String, dynamic>? filters;

  const GetShipmentsEvent({
    this.page,
    this.limit,
    this.filters,
  });

  @override
  List<Object?> get props => [page, limit, filters];
}

class UpdateShipmentEvent extends ReachShipEvent {
  final String shipmentId;
  final Map<String, dynamic> updates;

  const UpdateShipmentEvent({
    required this.shipmentId,
    required this.updates,
  });

  @override
  List<Object?> get props => [shipmentId, updates];
}

class CancelShipmentEvent extends ReachShipEvent {
  final String shipmentId;
  final String? reason;

  const CancelShipmentEvent({
    required this.shipmentId,
    this.reason,
  });

  @override
  List<Object?> get props => [shipmentId, reason];
}

class DeleteShipmentEvent extends ReachShipEvent {
  final String shipmentId;

  const DeleteShipmentEvent({
    required this.shipmentId,
  });

  @override
  List<Object?> get props => [shipmentId];
}

// Label Events
class GenerateLabelEvent extends ReachShipEvent {
  final String shipmentId;
  final String? format; // pdf, png, zpl
  final String? size; // 4x6, 8.5x11

  const GenerateLabelEvent({
    required this.shipmentId,
    this.format,
    this.size,
  });

  @override
  List<Object?> get props => [shipmentId, format, size];
}

class GetLabelEvent extends ReachShipEvent {
  final String shipmentId;

  const GetLabelEvent({required this.shipmentId});

  @override
  List<Object?> get props => [shipmentId];
}

// Tracking Events
class TrackShipmentEvent extends ReachShipEvent {
  final String trackingNumber;
  final String? carrier;

  const TrackShipmentEvent({
    required this.trackingNumber,
    this.carrier,
  });

  @override
  List<Object?> get props => [trackingNumber, carrier];
}

class GetTrackingUpdatesEvent extends ReachShipEvent {
  final String shipmentId;

  const GetTrackingUpdatesEvent({required this.shipmentId});

  @override
  List<Object?> get props => [shipmentId];
}

// Pickup Events
class SchedulePickupEvent extends ReachShipEvent {
  final String carrierName;
  final Address pickupAddress;
  final DateTime pickupDate;
  final String timeWindow;
  final List<String> shipmentIds;
  final String? instructions;

  const SchedulePickupEvent({
    required this.carrierName,
    required this.pickupAddress,
    required this.pickupDate,
    required this.timeWindow,
    required this.shipmentIds,
    this.instructions,
  });

  @override
  List<Object?> get props => [
        carrierName,
        pickupAddress,
        pickupDate,
        timeWindow,
        shipmentIds,
        instructions,
      ];
}

class CancelPickupEvent extends ReachShipEvent {
  final String pickupId;
  final String? reason;

  const CancelPickupEvent({
    required this.pickupId,
    this.reason,
  });

  @override
  List<Object?> get props => [pickupId, reason];
}

// Address Validation Events
class ValidateAddressEvent extends ReachShipEvent {
  final Address address;

  const ValidateAddressEvent({required this.address});

  @override
  List<Object?> get props => [address];
}

// Carrier Events
class GetCarriersEvent extends ReachShipEvent {
  const GetCarriersEvent();
}

class GetCarrierServicesEvent extends ReachShipEvent {
  final String carrierId;

  const GetCarrierServicesEvent({required this.carrierId});

  @override
  List<Object?> get props => [carrierId];
}

// Reset/Clear Events
class ClearReachShipStateEvent extends ReachShipEvent {
  const ClearReachShipStateEvent();
}

class ResetReachShipErrorEvent extends ReachShipEvent {
  const ResetReachShipErrorEvent();
}