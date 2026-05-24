import 'package:equatable/equatable.dart';
import '../data/models/shipment_order.dart';
import '../data/services/woocommerce_shipping_service.dart';

abstract class ShippingState extends Equatable {
  const ShippingState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ShippingInitial extends ShippingState {
  const ShippingInitial();
}

/// Loading state - fetching data
class ShippingLoading extends ShippingState {
  const ShippingLoading();
}

/// Shipments loaded successfully
class ShipmentsLoaded extends ShippingState {
  final List<ShipmentOrder> shipments;
  final ShipmentStats stats;
  final String? filterStatus;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;
  final String? searchQuery;

  const ShipmentsLoaded({
    required this.shipments,
    required this.stats,
    this.filterStatus,
    this.filterStartDate,
    this.filterEndDate,
    this.searchQuery,
  });

  ShipmentsLoaded copyWith({
    List<ShipmentOrder>? shipments,
    ShipmentStats? stats,
    String? filterStatus,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
    String? searchQuery,
  }) {
    return ShipmentsLoaded(
      shipments: shipments ?? this.shipments,
      stats: stats ?? this.stats,
      filterStatus: filterStatus ?? this.filterStatus,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      filterEndDate: filterEndDate ?? this.filterEndDate,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        shipments,
        stats,
        filterStatus,
        filterStartDate,
        filterEndDate,
        searchQuery,
      ];
}

/// Stats loaded (for dashboard cards)
class ShippingStatsLoaded extends ShippingState {
  final ShipmentStats stats;

  const ShippingStatsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

/// Single shipment selected with details
class ShipmentDetailsLoaded extends ShippingState {
  final ShipmentOrder shipment;

  const ShipmentDetailsLoaded(this.shipment);

  @override
  List<Object?> get props => [shipment];
}

/// Error state
class ShippingError extends ShippingState {
  final String message;

  const ShippingError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Helper to get filtered shipments
extension ShipmentsLoadedExtension on ShipmentsLoaded {
  List<ShipmentOrder> get filteredShipments {
    var filtered = shipments;

    // Apply status filter
    if (filterStatus != null && filterStatus!.isNotEmpty) {
      filtered = filtered.where((s) => s.status == filterStatus).toList();
    }

    // Apply date range filter
    if (filterStartDate != null) {
      filtered = filtered
          .where((s) =>
              s.dateCreated.isAfter(filterStartDate!) ||
              s.dateCreated.isAtSameMomentAs(filterStartDate!))
          .toList();
    }
    if (filterEndDate != null) {
      filtered = filtered
          .where((s) =>
              s.dateCreated.isBefore(filterEndDate!) ||
              s.dateCreated.isAtSameMomentAs(filterEndDate!))
          .toList();
    }

    // Apply search query
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      filtered = filtered.where((s) {
        return s.displayId.toLowerCase().contains(query) ||
            s.customerName.toLowerCase().contains(query) ||
            (s.trackingNumber?.toLowerCase().contains(query) ?? false) ||
            (s.carrier?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    return filtered;
  }
}
