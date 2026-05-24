import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/models/shipment_order.dart';
import '../data/services/woocommerce_shipping_service.dart';
import 'shipping_event.dart';
import 'shipping_state.dart';

/// BLoC for managing shipping/shipment data
class ShippingBloc extends Bloc<ShippingEvent, ShippingState> {
  List<ShipmentOrder>? _allShipments;
  ShipmentStats? _stats;

  ShippingBloc() : super(const ShippingInitial()) {
    on<FetchShipments>(_onFetchShipments);
    on<FetchShipmentStats>(_onFetchShipmentStats);
    on<RefreshShipments>(_onRefreshShipments);
    on<FilterShipmentsByStatus>(_onFilterByStatus);
    on<FilterShipmentsByDate>(_onFilterByDate);
    on<SearchShipments>(_onSearchShipments);
    on<SelectShipment>(_onSelectShipment);
    on<ClearSelectedShipment>(_onClearSelectedShipment);
  }

  /// Handle fetching shipments
  Future<void> _onFetchShipments(
    FetchShipments event,
    Emitter<ShippingState> emit,
  ) async {
    try {
      emit(const ShippingLoading());

      final shipments = await WooCommerceShippingService.fetchShipments(
        status: event.status,
        after: event.after,
        before: event.before,
        page: event.page,
        perPage: event.perPage,
      );

      final stats = await WooCommerceShippingService.getShipmentStats();

      _allShipments = shipments;
      _stats = stats;

      emit(ShipmentsLoaded(
        shipments: shipments,
        stats: stats,
        filterStatus: event.status,
        filterStartDate: event.after,
        filterEndDate: event.before,
      ));

      developer.log(
        'Fetched ${shipments.length} shipments',
        name: 'ShippingBloc',
      );
    } catch (e) {
      developer.log('Error fetching shipments: $e', name: 'ShippingBloc');
      emit(ShippingError('Failed to load shipments: $e'));
    }
  }

  /// Handle fetching just the stats (for dashboard cards)
  Future<void> _onFetchShipmentStats(
    FetchShipmentStats event,
    Emitter<ShippingState> emit,
  ) async {
    try {
      if (state is! ShipmentsLoaded) {
        emit(const ShippingLoading());
      }

      final stats = await WooCommerceShippingService.getShipmentStats();
      _stats = stats;

      // If we already have shipments, update stats only
      if (state is ShipmentsLoaded) {
        final current = state as ShipmentsLoaded;
        emit(current.copyWith(stats: stats));
      } else {
        emit(ShippingStatsLoaded(stats));
      }

      developer.log(
        'Stats - Pending: ${stats.pending}, Transit: ${stats.inTransit}, '
        'Delivered: ${stats.delivered}, Total: ${stats.total}',
        name: 'ShippingBloc',
      );
    } catch (e) {
      developer.log('Error fetching stats: $e', name: 'ShippingBloc');
      emit(ShippingError('Failed to load shipment stats: $e'));
    }
  }

  /// Handle refresh
  Future<void> _onRefreshShipments(
    RefreshShipments event,
    Emitter<ShippingState> emit,
  ) async {
    if (state is ShipmentsLoaded) {
      final current = state as ShipmentsLoaded;
      add(FetchShipments(
        status: current.filterStatus,
        after: current.filterStartDate,
        before: current.filterEndDate,
      ));
    } else {
      add(const FetchShipments());
    }
  }

  /// Handle status filter
  void _onFilterByStatus(
    FilterShipmentsByStatus event,
    Emitter<ShippingState> emit,
  ) {
    if (state is ShipmentsLoaded) {
      final current = state as ShipmentsLoaded;
      emit(current.copyWith(filterStatus: event.status));
    }
  }

  /// Handle date filter
  void _onFilterByDate(
    FilterShipmentsByDate event,
    Emitter<ShippingState> emit,
  ) {
    if (state is ShipmentsLoaded) {
      final current = state as ShipmentsLoaded;
      emit(current.copyWith(
        filterStartDate: event.startDate,
        filterEndDate: event.endDate,
      ));
    }
  }

  /// Handle search
  void _onSearchShipments(
    SearchShipments event,
    Emitter<ShippingState> emit,
  ) {
    if (state is ShipmentsLoaded) {
      final current = state as ShipmentsLoaded;
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  /// Handle selecting a shipment
  void _onSelectShipment(
    SelectShipment event,
    Emitter<ShippingState> emit,
  ) {
    if (event.shipment != null) {
      emit(ShipmentDetailsLoaded(event.shipment!));
    }
  }

  /// Handle clearing selection
  void _onClearSelectedShipment(
    ClearSelectedShipment event,
    Emitter<ShippingState> emit,
  ) {
    if (_allShipments != null && _stats != null) {
      emit(ShipmentsLoaded(
        shipments: _allShipments!,
        stats: _stats!,
      ));
    } else {
      emit(const ShippingInitial());
    }
  }
}
