class ReachShipConstants {
  // API base URLs

  static const String sandboxBaseUrl = 'https://api.reachship.com/sandbox/v1';
  static const String productionBaseUrl =
      'https://api.reachship.com/production/v1';

  // Authentication Endpoints
  static const String tokenEndpoint = '/oauth/token';

  // Shipping Endpoints
  static const String ratesEndpoint = '/rates';
  static const String printLabelEndpoint = '/print-label';
  static const String deleteShipmentsEndpoint = '/delete-shipments';
  static const String schedulePickupEndpoint = '/schedule-pickup';
  static const String cancelPickupEndpoint = '/cancel-pickup';
  static const String trackShipmentEndpoint = '/track-shipment';
  static const String saveCarrierCredentialsEndpoint =
      '/save-carrier-credentials';
  static const String updateCarrierCredentialsEndpoint =
      '/update-carrier-credentials';
  static const String getCarrierCredentialsSummaryEndpoint =
      '/get-carrier-credentials-summary';
  static const String deleteCarrierCredentialsEndpoint =
      '/delete-carrier-credentials';
  static const String addressValidationEndpoint = '/address/validate';
}
