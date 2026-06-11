import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:woo_management_app/core/utils/app_logger.dart';
import '../data/models/shipment_order.dart';
import '../data/services/woocommerce_shipping_service.dart';
import '../services/shipping_cache_service.dart';
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

  /// Fetch shipments and stats. Cache-first stale-while-revalidate:
  /// 1. If there's nothing on screen yet, show the persisted disk cache
  ///    instantly (no shimmer) and only show shimmer when no cache exists.
  /// 2. Then fetch fresh data from the network in the background and swap it
  ///    in. On failure, keep whatever is already shown.
  Future<void> _onFetchShipments(
    FetchShipments event,
    Emitter<ShippingState> emit,
  ) async {
    final isUnfiltered = event.status == null &&
        event.after == null &&
        event.before == null;

    // ── Step 1: show something immediately ────────────────────────────────
    final alreadyHasData = state is ShipmentsLoaded;
    if (!alreadyHasData && !event.forceRefresh && isUnfiltered) {
      final cached = await ShippingCacheService.load();
      if (cached != null) {
        _allShipments = cached.shipments;
        _stats = cached.stats;
        emit(ShipmentsLoaded(shipments: cached.shipments, stats: cached.stats));
        AppLog.cache('Shipping',
            'Served from disk cache instantly (age: ${_age(cached.cachedAt)}) '
            '→ refreshing in background');
      }
    }

    // Only show the shimmer when there's genuinely nothing to display.
    if (state is! ShipmentsLoaded) {
      emit(const ShippingLoading());
    }

    // ── Step 2: fetch fresh data ──────────────────────────────────────────
    final sw = Stopwatch()..start();
    AppLog.net('Shipping', 'Background refresh START (fetching from network)');
    try {
      final results = await Future.wait([
        // The dashboard only shows a handful of recent shipments, so fetch a
        // single page (the full list lives on the All Shipments screen).
        WooCommerceShippingService.fetchShipments(
          status: event.status,
          after: event.after,
          before: event.before,
          page: event.page,
          perPage: event.perPage,
        ),
        WooCommerceShippingService.getShipmentStats(
          forceRefresh: event.forceRefresh,
          after: event.after,
          before: event.before,
        ),
      ]);

      final shipments = results[0] as List<ShipmentOrder>;
      final stats = results[1] as ShipmentStats;

      _allShipments = shipments;
      _stats = stats;

      emit(ShipmentsLoaded(
        shipments: shipments,
        stats: stats,
        filterStatus: event.status,
        filterStartDate: event.after,
        filterEndDate: event.before,
      ));

      // Persist to disk so the next cold start is instant.
      if (isUnfiltered) {
        await ShippingCacheService.save(stats: stats, shipments: shipments);
      }

      AppLog.ok('Shipping',
          'Refresh DONE in ${sw.elapsedMilliseconds}ms — '
          '${shipments.length} shipments, pending:${stats.pending} '
          'transit:${stats.inTransit} delivered:${stats.delivered} total:${stats.total}');
    } catch (e) {
      // Keep cached/old data on screen if we have it; only surface an error
      // when there's nothing to show.
      if (state is ShipmentsLoaded) {
        AppLog.error('Shipping',
            'Background refresh FAILED in ${sw.elapsedMilliseconds}ms (keeping cached data): $e');
      } else {
        AppLog.error('Shipping',
            'Refresh FAILED in ${sw.elapsedMilliseconds}ms (no cache to fall back on): $e');
        emit(ShippingError('Failed to load shipments: $e'));
      }
    }
  }

  String _age(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return '${d.inSeconds}s';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inDays < 1) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  /// Fetch just the stats — returns from cache instantly if fresh
  Future<void> _onFetchShipmentStats(
    FetchShipmentStats event,
    Emitter<ShippingState> emit,
  ) async {
    final sw = Stopwatch()..start();
    AppLog.net('Shipping', 'Stats background refresh START');
    try {
      if (state is! ShipmentsLoaded) {
        emit(const ShippingLoading());
      }

      final stats = await WooCommerceShippingService.getShipmentStats(
        after: event.after,
        before: event.before,
      );
      _stats = stats;

      if (state is ShipmentsLoaded) {
        final current = state as ShipmentsLoaded;
        emit(current.copyWith(stats: stats));
      } else {
        emit(ShippingStatsLoaded(stats));
      }

      AppLog.ok('Shipping',
          'Stats DONE in ${sw.elapsedMilliseconds}ms — pending:${stats.pending} '
          'transit:${stats.inTransit} delivered:${stats.delivered} total:${stats.total}');
    } catch (e) {
      AppLog.error('Shipping',
          'Stats refresh FAILED in ${sw.elapsedMilliseconds}ms: $e');
      // Don't blow away existing data over a stats failure.
      if (state is! ShipmentsLoaded) {
        emit(ShippingError('Failed to load shipment stats: $e'));
      }
    }
  }

  /// Handle refresh — force-clears stats cache so fresh data is fetched
  Future<void> _onRefreshShipments(
    RefreshShipments event,
    Emitter<ShippingState> emit,
  ) async {
    AppLog.refresh('Shipping', 'Pull-to-refresh triggered → forcing fresh fetch');
    WooCommerceShippingService.clearStatsCache();
    if (state is ShipmentsLoaded) {
      final current = state as ShipmentsLoaded;
      add(FetchShipments(
        status: current.filterStatus,
        after: current.filterStartDate,
        before: current.filterEndDate,
        forceRefresh: true,
      ));
    } else {
      add(const FetchShipments(forceRefresh: true));
    }
  }

  void _onFilterByStatus(FilterShipmentsByStatus event, Emitter<ShippingState> emit) {
    if (state is ShipmentsLoaded) {
      final current = state as ShipmentsLoaded;
      emit(current.copyWith(filterStatus: event.status));
    }
  }

  void _onFilterByDate(FilterShipmentsByDate event, Emitter<ShippingState> emit) {
    if (state is ShipmentsLoaded) {
      final current = state as ShipmentsLoaded;
      emit(current.copyWith(
        filterStartDate: event.startDate,
        filterEndDate: event.endDate,
      ));
    }
  }

  void _onSearchShipments(SearchShipments event, Emitter<ShippingState> emit) {
    if (state is ShipmentsLoaded) {
      final current = state as ShipmentsLoaded;
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  void _onSelectShipment(SelectShipment event, Emitter<ShippingState> emit) {
    if (event.shipment != null) {
      emit(ShipmentDetailsLoaded(event.shipment!));
    }
  }

  void _onClearSelectedShipment(ClearSelectedShipment event, Emitter<ShippingState> emit) {
    if (_allShipments != null && _stats != null) {
      emit(ShipmentsLoaded(shipments: _allShipments!, stats: _stats!));
    } else {
      emit(const ShippingInitial());
    }
  }
}
