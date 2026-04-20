import 'package:equatable/equatable.dart';
import '../models/models.dart';

abstract class ReachShipState extends Equatable {
  const ReachShipState();

  @override
  List<Object?> get props => [];
}

// Initial State
class ReachShipInitial extends ReachShipState {
  const ReachShipInitial();
}

// Loading States
class ReachShipLoading extends ReachShipState {
  final String? message;

  const ReachShipLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class ShippingRatesLoading extends ReachShipState {
  const ShippingRatesLoading();
}

class ShipmentLoading extends ReachShipState {
  const ShipmentLoading();
}

class LabelGenerating extends ReachShipState {
  const LabelGenerating();
}

class TrackingLoading extends ReachShipState {
  const TrackingLoading();
}

class PickupScheduling extends ReachShipState {
  const PickupScheduling();
}

class AddressValidating extends ReachShipState {
  const AddressValidating();
}

// Success States
class ShippingRatesLoaded extends ReachShipState {
  final List<ShippingRate> rates;
  final Address fromAddress;
  final Address toAddress;
  final List<Package> packages;

  const ShippingRatesLoaded({
    required this.rates,
    required this.fromAddress,
    required this.toAddress,
    required this.packages,
  });

  @override
  List<Object?> get props => [rates, fromAddress, toAddress, packages];
}

class ShipmentCreated extends ReachShipState {
  final Shipment shipment;

  const ShipmentCreated({required this.shipment});

  @override
  List<Object?> get props => [shipment];
}

class ShipmentLoaded extends ReachShipState {
  final Shipment shipment;

  const ShipmentLoaded({required this.shipment});

  @override
  List<Object?> get props => [shipment];
}

class ShipmentsLoaded extends ReachShipState {
  final List<Shipment> shipments;
  final int totalCount;
  final int currentPage;
  final bool hasMore;

  const ShipmentsLoaded({
    required this.shipments,
    required this.totalCount,
    required this.currentPage,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [shipments, totalCount, currentPage, hasMore];
}

class ShipmentUpdated extends ReachShipState {
  final Shipment shipment;

  const ShipmentUpdated({required this.shipment});

  @override
  List<Object?> get props => [shipment];
}

class ShipmentCancelled extends ReachShipState {
  final String shipmentId;
  final String message;

  const ShipmentCancelled({
    required this.shipmentId,
    required this.message,
  });

  @override
  List<Object?> get props => [shipmentId, message];
}

class ShipmentDeleted extends ReachShipState {
  final String shipmentId;
  final String message;

  const ShipmentDeleted({
    required this.shipmentId,
    required this.message,
  });

  @override
  List<Object?> get props => [shipmentId, message];
}

class LabelGenerated extends ReachShipState {
  final String shipmentId;
  final String labelUrl;
  final String format;
  final String size;

  const LabelGenerated({
    required this.shipmentId,
    required this.labelUrl,
    required this.format,
    required this.size,
  });

  @override
  List<Object?> get props => [shipmentId, labelUrl, format, size];
}

class LabelLoaded extends ReachShipState {
  final String shipmentId;
  final String labelUrl;

  const LabelLoaded({
    required this.shipmentId,
    required this.labelUrl,
  });

  @override
  List<Object?> get props => [shipmentId, labelUrl];
}

class TrackingLoaded extends ReachShipState {
  final String trackingNumber;
  final List<TrackingEvent> events;
  final String? carrier;
  final String? status;

  const TrackingLoaded({
    required this.trackingNumber,
    required this.events,
    this.carrier,
    this.status,
  });

  @override
  List<Object?> get props => [trackingNumber, events, carrier, status];
}

class TrackingUpdatesLoaded extends ReachShipState {
  final String shipmentId;
  final List<TrackingEvent> events;

  const TrackingUpdatesLoaded({
    required this.shipmentId,
    required this.events,
  });

  @override
  List<Object?> get props => [shipmentId, events];
}

class PickupScheduled extends ReachShipState {
  final String pickupId;
  final DateTime pickupDate;
  final String timeWindow;
  final Address pickupAddress;

  const PickupScheduled({
    required this.pickupId,
    required this.pickupDate,
    required this.timeWindow,
    required this.pickupAddress,
  });

  @override
  List<Object?> get props => [pickupId, pickupDate, timeWindow, pickupAddress];
}

class PickupCancelled extends ReachShipState {
  final String pickupId;
  final String message;

  const PickupCancelled({
    required this.pickupId,
    required this.message,
  });

  @override
  List<Object?> get props => [pickupId, message];
}

class AddressValidated extends ReachShipState {
  final Address originalAddress;
  final Address validatedAddress;
  final bool isValid;
  final List<String>? suggestions;

  const AddressValidated({
    required this.originalAddress,
    required this.validatedAddress,
    required this.isValid,
    this.suggestions,
  });

  @override
  List<Object?> get props => [originalAddress, validatedAddress, isValid, suggestions];
}

class CarriersLoaded extends ReachShipState {
  final List<Map<String, dynamic>> carriers;

  const CarriersLoaded({required this.carriers});

  @override
  List<Object?> get props => [carriers];
}

class CarrierServicesLoaded extends ReachShipState {
  final String carrierId;
  final List<Map<String, dynamic>> services;

  const CarrierServicesLoaded({
    required this.carrierId,
    required this.services,
  });

  @override
  List<Object?> get props => [carrierId, services];
}

// Error States
class ReachShipError extends ReachShipState {
  final String message;
  final String? errorCode;
  final dynamic error;
  final StackTrace? stackTrace;

  const ReachShipError({
    required this.message,
    this.errorCode,
    this.error,
    this.stackTrace,
  });

  @override
  List<Object?> get props => [message, errorCode, error, stackTrace];
}

class ShippingRatesError extends ReachShipError {
  const ShippingRatesError({
    required super.message,
    super.errorCode,
    super.error,
    super.stackTrace,
  });
}

class ShipmentError extends ReachShipError {
  const ShipmentError({
    required super.message,
    super.errorCode,
    super.error,
    super.stackTrace,
  });
}

class LabelError extends ReachShipError {
  const LabelError({
    required super.message,
    super.errorCode,
    super.error,
    super.stackTrace,
  });
}

class TrackingError extends ReachShipError {
  const TrackingError({
    required super.message,
    super.errorCode,
    super.error,
    super.stackTrace,
  });
}

class PickupError extends ReachShipError {
  const PickupError({
    required super.message,
    super.errorCode,
    super.error,
    super.stackTrace,
  });
}

class AddressValidationError extends ReachShipError {
  const AddressValidationError({
    required super.message,
    super.errorCode,
    super.error,
    super.stackTrace,
  });
}

class CarrierError extends ReachShipError {
  const CarrierError({
    required super.message,
    super.errorCode,
    super.error,
    super.stackTrace,
  });
}