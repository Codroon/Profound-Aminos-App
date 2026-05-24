import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../repository/reach_ship_repository.dart';
import '../models/models.dart';
import 'reach_ship_event.dart';
import 'reach_ship_state.dart';

class ReachShipBloc extends Bloc<ReachShipEvent, ReachShipState> {
  final ReachShipRepository _repository;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  ReachShipBloc({
    required ReachShipRepository repository,
    required Connectivity connectivity,
  }) : _repository = repository,
       _connectivity = connectivity,
       super(const ReachShipInitial()) {
    // Register event handlers
    on<GetShippingRatesEvent>(_onGetShippingRates);
    on<CreateShipmentEvent>(_onCreateShipment);
    on<GetShipmentEvent>(_onGetShipment);
    on<GetShipmentsEvent>(_onGetShipments);
    on<UpdateShipmentEvent>(_onUpdateShipment);
    on<CancelShipmentEvent>(_onCancelShipment);
    on<GenerateLabelEvent>(_onGenerateLabel);
    on<GetLabelEvent>(_onGetLabel);
    on<TrackShipmentEvent>(_onTrackShipment);
    on<GetTrackingUpdatesEvent>(_onGetTrackingUpdates);
    on<SchedulePickupEvent>(_onSchedulePickup);
    on<CancelPickupEvent>(_onCancelPickup);
    on<ValidateAddressEvent>(_onValidateAddress);
    on<GetCarriersEvent>(_onGetCarriers);
    on<GetCarrierServicesEvent>(_onGetCarrierServices);
    on<ClearReachShipStateEvent>(_onClearState);
    on<ResetReachShipErrorEvent>(_onResetError);

    // Monitor connectivity
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        // ignore: invalid_use_of_visible_for_testing_member
        emit(
          const ReachShipError(
            message: 'No internet connection available',
            errorCode: 'NO_INTERNET',
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _connectivitySubscription?.cancel();
    return super.close();
  }

  // Helper method to check connectivity
  Future<bool> _hasInternetConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    final hasConnection = connectivityResult != ConnectivityResult.none;
    developer.log(
      'Internet connectivity check: $hasConnection',
      name: 'ReachShipBloc',
      level: hasConnection ? 800 : 900,
    );
    return hasConnection;
  }

  // Helper method to handle errors
  ReachShipState _handleError(
    dynamic error,
    StackTrace stackTrace,
    String operation,
  ) {
    String message;
    String? errorCode;

    if (error is Exception) {
      message = error.toString().replaceFirst('Exception: ', '');
    } else {
      message = 'An unexpected error occurred during $operation';
    }

    // Extract error code if available
    if (message.contains('|')) {
      final parts = message.split('|');
      if (parts.length >= 2) {
        errorCode = parts[0].trim();
        message = parts[1].trim();
      }
    }

    switch (operation) {
      case 'shipping rates':
        return ShippingRatesError(
          message: message,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 'shipment':
        return ShipmentError(
          message: message,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 'label':
        return LabelError(
          message: message,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 'tracking':
        return TrackingError(
          message: message,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 'pickup':
        return PickupError(
          message: message,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 'address validation':
        return AddressValidationError(
          message: message,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        );
      case 'carrier':
        return CarrierError(
          message: message,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        );
      default:
        return ReachShipError(
          message: message,
          errorCode: errorCode,
          error: error,
          stackTrace: stackTrace,
        );
    }
  }

  // Event Handlers
  Future<void> _onGetShippingRates(
    GetShippingRatesEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (!await _hasInternetConnection()) {
      emit(
        const ShippingRatesError(
          message: 'No internet connection available',
          errorCode: 'NO_INTERNET',
        ),
      );
      return;
    }

    emit(const ShippingRatesLoading());

    try {
      developer.log(
        'Getting shipping rates from ${event.fromAddress.city} to ${event.toAddress.city}',
        name: 'ReachShipBloc',
        level: 800,
      );

      final rates = await _repository.getRates(
        fromAddress: event.fromAddress,
        toAddress: event.toAddress,
        packages: event.packages,
        carrierIds: event.options?['carrierIds'],
        serviceTypes: event.options?['serviceTypes'],
      );

      developer.log(
        'Successfully retrieved ${rates.length} shipping rates',
        name: 'ReachShipBloc',
        level: 800,
      );

      emit(
        ShippingRatesLoaded(
          rates: rates,
          fromAddress: event.fromAddress,
          toAddress: event.toAddress,
          packages: event.packages,
        ),
      );
    } catch (error, stackTrace) {
      developer.log(
        'Error getting shipping rates: $error',
        name: 'ReachShipBloc',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      emit(_handleError(error, stackTrace, 'shipping rates'));
    }
  }

  Future<void> _onCreateShipment(
    CreateShipmentEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (!await _hasInternetConnection()) {
      emit(
        const ShipmentError(
          message: 'No internet connection available',
          errorCode: 'NO_INTERNET',
        ),
      );
      return;
    }

    emit(const ShipmentLoading());

    try {
      developer.log(
        'Creating shipment with rate ID: ${event.rateId}',
        name: 'ReachShipBloc',
        level: 800,
      );

      final shipment = await _repository.createShipment(
        fromAddress: event.fromAddress,
        toAddress: event.toAddress,
        packages: event.packages,
        carrier: event.carrier,
        orderId: event.orderId,
        metadata: event.metadata,
      );

      developer.log(
        'Successfully created shipment: ${shipment.id}',
        name: 'ReachShipBloc',
        level: 800,
      );

      emit(ShipmentCreated(shipment: shipment));
    } catch (error, stackTrace) {
      developer.log(
        'Error creating shipment: $error',
        name: 'ReachShipBloc',
        error: error,
        stackTrace: stackTrace,
        level: 1000,
      );
      emit(_handleError(error, stackTrace, 'shipment'));
    }
  }

  // Note: GetShipment functionality removed as ReachShip API doesn't support it
  Future<void> _onGetShipment(
    GetShipmentEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    emit(
      const ShipmentError(
        message: 'Get shipment by ID is not supported by ReachShip API',
        errorCode: 'NOT_SUPPORTED',
      ),
    );
  }

  Future<void> _onGetShipments(
    GetShipmentsEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (!await _hasInternetConnection()) {
      emit(
        const ShipmentError(
          message: 'No internet connection available',
          errorCode: 'NO_INTERNET',
        ),
      );
      return;
    }

    emit(const ShipmentLoading());

    try {
      final shipments = await _repository.getShipments(
        limit: event.limit,
        offset:
            event.page != null ? (event.page! - 1) * (event.limit ?? 20) : null,
        status: event.filters?['status'],
        orderId: event.filters?['orderId'],
        createdAfter: event.filters?['createdAfter'],
        createdBefore: event.filters?['createdBefore'],
      );

      emit(
        ShipmentsLoaded(
          shipments: shipments,
          totalCount: shipments.length,
          currentPage: event.page ?? 1,
          hasMore: shipments.length == (event.limit ?? 20),
        ),
      );
    } catch (error, stackTrace) {
      emit(_handleError(error, stackTrace, 'shipment'));
    }
  }

  // Note: UpdateShipment functionality removed as ReachShip API doesn't support it
  Future<void> _onUpdateShipment(
    UpdateShipmentEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    emit(
      const ShipmentError(
        message: 'Update shipment is not supported by ReachShip API',
        errorCode: 'NOT_SUPPORTED',
      ),
    );
  }

  // Note: CancelShipment functionality removed as ReachShip API doesn't support it
  // Use deleteShipments instead
  Future<void> _onCancelShipment(
    CancelShipmentEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    emit(
      const ShipmentError(
        message: 'Cancel shipment is not supported. Use delete shipments instead.',
        errorCode: 'NOT_SUPPORTED',
      ),
    );
  }

  Future<void> _onGenerateLabel(
    GenerateLabelEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    emit(
      const LabelError(
        message: 'Label generation is handled during shipment creation',
        errorCode: 'NOT_SUPPORTED',
      ),
    );
  }

  // Note: GetLabel functionality removed as ReachShip API doesn't support it
  Future<void> _onGetLabel(
    GetLabelEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    emit(
      const LabelError(
        message: 'Get label is not supported. Labels are generated during shipment creation.',
        errorCode: 'NOT_SUPPORTED',
      ),
    );
  }

  Future<void> _onTrackShipment(
    TrackShipmentEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (!await _hasInternetConnection()) {
      emit(
        const TrackingError(
          message: 'No internet connection available',
          errorCode: 'NO_INTERNET',
        ),
      );
      return;
    }

    emit(const TrackingLoading());

    try {
      final events = await _repository.trackShipment(
        carrierName: event.carrier ?? '',
        trackingNumber: event.trackingNumber,
      );

      emit(
        TrackingLoaded(
          trackingNumber: event.trackingNumber,
          events:
              (events as List<dynamic>)
                  .map((e) => TrackingEvent.fromJson(e as Map<String, dynamic>))
                  .toList(),
          carrier: event.carrier,
          status:
              events.isNotEmpty ? (events as List<dynamic>).last.status : null,
        ),
      );
    } catch (error, stackTrace) {
      emit(_handleError(error, stackTrace, 'tracking'));
    }
  }

  // Note: GetTrackingUpdates functionality removed as ReachShip API doesn't support it
  // Use trackShipment with carrier and tracking number instead
  Future<void> _onGetTrackingUpdates(
    GetTrackingUpdatesEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    emit(
      const TrackingError(
        message: 'Get tracking updates by shipment ID is not supported. Use track shipment with carrier and tracking number.',
        errorCode: 'NOT_SUPPORTED',
      ),
    );
  }

  Future<void> _onSchedulePickup(
    SchedulePickupEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (!await _hasInternetConnection()) {
      emit(
        const PickupError(
          message: 'No internet connection available',
          errorCode: 'NO_INTERNET',
        ),
      );
      return;
    }

    emit(const PickupScheduling());

    try {
      final result = await _repository.schedulePickup(
        carrierName: event.carrierName,
        pickupAddress: event.pickupAddress,
        pickupDate: event.pickupDate,
        shipmentIds: event.shipmentIds,
        instructions: event.instructions,
      );

      emit(
        PickupScheduled(
          pickupId: result['pickupId'] as String,
          pickupDate: event.pickupDate,
          timeWindow: event.timeWindow,
          pickupAddress: event.pickupAddress,
        ),
      );
    } catch (error, stackTrace) {
      emit(_handleError(error, stackTrace, 'pickup'));
    }
  }

  Future<void> _onCancelPickup(
    CancelPickupEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (!await _hasInternetConnection()) {
      emit(
        const PickupError(
          message: 'No internet connection available',
          errorCode: 'NO_INTERNET',
        ),
      );
      return;
    }

    emit(const ReachShipLoading(message: 'Cancelling pickup...'));

    try {
      final success = await _repository.cancelPickup(
        event.pickupId,
        // event.reason,
      );
      if (success) {
        emit(
          PickupCancelled(
            pickupId: event.pickupId,
            message: event.reason ?? '',
          ),
        );
      } else {
        emit(
          const PickupError(
            message: 'Failed to cancel pickup',
            errorCode: 'CANCEL_FAILED',
          ),
        );
      }
    } catch (error, stackTrace) {
      emit(_handleError(error, stackTrace, 'pickup'));
    }
  }

  // Note: ValidateAddress functionality removed as ReachShip API doesn't support it
  Future<void> _onValidateAddress(
    ValidateAddressEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    emit(
      const AddressValidationError(
        message: 'Address validation is not supported by ReachShip API',
        errorCode: 'NOT_SUPPORTED',
      ),
    );
  }

  Future<void> _onGetCarriers(
    GetCarriersEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (!await _hasInternetConnection()) {
      emit(
        const CarrierError(
          message: 'No internet connection available',
          errorCode: 'NO_INTERNET',
        ),
      );
      return;
    }

    emit(const ReachShipLoading(message: 'Loading carriers...'));

    try {
      final carriers = await _repository.getCarriers();
      emit(CarriersLoaded(carriers: carriers));
    } catch (error, stackTrace) {
      emit(_handleError(error, stackTrace, 'carrier'));
    }
  }

  Future<void> _onGetCarrierServices(
    GetCarrierServicesEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (!await _hasInternetConnection()) {
      emit(
        const CarrierError(
          message: 'No internet connection available',
          errorCode: 'NO_INTERNET',
        ),
      );
      return;
    }

    emit(const ReachShipLoading(message: 'Loading carrier services...'));

    try {
      final services = await _repository.getCarrierServices(
        carrierName: event.carrierId,
      );
      emit(
        CarrierServicesLoaded(carrierId: event.carrierId, services: services),
      );
    } catch (error, stackTrace) {
      emit(_handleError(error, stackTrace, 'carrier'));
    }
  }

  Future<void> _onClearState(
    ClearReachShipStateEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    emit(const ReachShipInitial());
  }

  Future<void> _onResetError(
    ResetReachShipErrorEvent event,
    Emitter<ReachShipState> emit,
  ) async {
    if (state is ReachShipError) {
      emit(const ReachShipInitial());
    }
  }
}
