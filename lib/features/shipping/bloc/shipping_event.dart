import 'package:equatable/equatable.dart';
import '../data/models/shipment_order.dart';

abstract class ShippingEvent extends Equatable {
  const ShippingEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch all shipments with filters
class FetchShipments extends ShippingEvent {
  final String? status;
  final DateTime? after;
  final DateTime? before;
  final int page;
  final int perPage;

  const FetchShipments({
    this.status,
    this.after,
    this.before,
    this.page = 1,
    this.perPage = 100,
  });

  @override
  List<Object?> get props => [status, after, before, page, perPage];
}

/// Fetch shipment statistics for dashboard
class FetchShipmentStats extends ShippingEvent {
  const FetchShipmentStats();
}

/// Refresh shipments data
class RefreshShipments extends ShippingEvent {
  const RefreshShipments();
}

/// Filter shipments by status
class FilterShipmentsByStatus extends ShippingEvent {
  final String? status;

  const FilterShipmentsByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

/// Filter shipments by date range
class FilterShipmentsByDate extends ShippingEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const FilterShipmentsByDate({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

/// Search shipments
class SearchShipments extends ShippingEvent {
  final String query;

  const SearchShipments(this.query);

  @override
  List<Object?> get props => [query];
}

/// Select a shipment to view details
class SelectShipment extends ShippingEvent {
  final ShipmentOrder? shipment;

  const SelectShipment(this.shipment);

  @override
  List<Object?> get props => [shipment];
}

/// Clear selected shipment
class ClearSelectedShipment extends ShippingEvent {
  const ClearSelectedShipment();
}
