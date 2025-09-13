// ignore_for_file: public_member_api_docs
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'crediential_storage_service.dart';
import '../../features/reach_ship/utils/country_code_mapper.dart';

/// Choose environment
enum ReachShipEnv { sandbox, production }

/// Credentials + endpoints container
class ReachShipConfig {
  final ReachShipEnv env;
  final String clientId;
  final String clientSecret;

  final String baseUrl;

  final String oauthPath;

  const ReachShipConfig({
    required this.env,
    required this.clientId,
    required this.clientSecret,
    required this.baseUrl,
    this.oauthPath = '/oauth/token',
  });
}

/// Lightweight token cache
class _Token {
  final String accessToken;
  final DateTime expiresAt;

  _Token({required this.accessToken, required this.expiresAt});

  bool get isExpired =>
      DateTime.now().isAfter(expiresAt.subtract(const Duration(seconds: 30)));
}

/// Base exception
class ReachShipException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  ReachShipException(this.message, {this.statusCode, this.data});

  @override
  String toString() =>
      'ReachShipException($statusCode): $message ${data != null ? ' | $data' : ''}';
}

class UnauthorizedException extends ReachShipException {
  UnauthorizedException(super.msg, {super.statusCode, super.data});
}

class RateLimitException extends ReachShipException {
  final Duration? retryAfter;
  RateLimitException(
    super.msg, {
    this.retryAfter,
    super.statusCode,
    super.data,
  });
}

class NetworkException extends ReachShipException {
  NetworkException(super.msg, {super.statusCode, super.data});
}

/// Core service
class ReachShipService {
  final ReachShipConfig config;
  final http.Client _client;
  _Token? _token;

  /// Tuning
  final Duration timeout;
  final int maxRetries;

  ReachShipService(
    this.config, {
    http.Client? client,
    this.timeout = const Duration(seconds: 25),
    this.maxRetries = 2,
  }) : _client = client ?? http.Client();

  /// Factory constructor that loads credentials from storage with fallback
  static Future<ReachShipService> withCredentials(
    CredentialStorageService credentialService, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 25),
    int maxRetries = 2,
  }) async {
    final credentials = await credentialService.getCredentials();

    var clientId = credentials['reachShipClientId'] ?? '';
    var clientSecret = credentials['reachShipClientSecret'] ?? '';
    var envString = credentials['reachShipEnv'] ?? 'sandbox';

    print('[ReachShipService] Debug - Loading credentials from storage:');
    print('[ReachShipService] ClientId: $clientId');
    print('[ReachShipService] ClientSecret: ${clientSecret.isNotEmpty ? '***${clientSecret.substring(clientSecret.length - 4)}' : 'EMPTY'}');
    print('[ReachShipService] Environment: $envString');

    // Fallback to hardcoded credentials if stored credentials are empty or invalid
    if (clientId.isEmpty || clientSecret.isEmpty) {
      print('[ReachShipService] Using fallback credentials due to missing stored credentials');
      
      if (envString.toLowerCase().contains('prod') || envString.toLowerCase().contains('production')) {
        // Production fallback credentials
        clientId = 'VpDMVB1z7Tyqgw6zeZruZ0yXPt3OoTRcIi';
        clientSecret = 'hJeN9YRO5UZPxXiSzFOOXbOHdHbd3WZ0';
        envString = 'production';
        print('[ReachShipService] Using production fallback credentials');
      } else {
        // Sandbox fallback credentials (default)
        clientId = 'w2iuTRwQyoE9TPZLW1GU7FijeApM6VShDk';
        clientSecret = 'iZbXqR9NTQIkti5OEij9MAg3Spa9labJ';
        envString = 'sandbox';
        print('[ReachShipService] Using sandbox fallback credentials');
      }
    }

    final env =
        envString.toLowerCase() == 'production'
            ? ReachShipEnv.production
            : ReachShipEnv.sandbox;

    final baseUrl = env == ReachShipEnv.production
        ? 'https://api.reachship.com/production/v1'
        : 'https://api.reachship.com/sandbox/v1';

    final config = ReachShipConfig(
      env: env,
      clientId: clientId,
      clientSecret: clientSecret,
      baseUrl: baseUrl,
    );

    return ReachShipService(
      config,
      client: client,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  // -------------------------
  // OAuth
  // -------------------------
  Future<void> _ensureToken() async {
    if (_token != null && !_token!.isExpired) return;

    // ReachShip OAuth uses GET with query parameters (working method)
    final uri = Uri.parse(
      '${config.baseUrl}${config.oauthPath}'
      '?grant_type=client_credentials'
      '&client_id=${config.clientId}'
      '&client_secret=${config.clientSecret}',
    );
    
    final res = await _client
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(timeout);

    final decoded = _safeDecode(res.body);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final accessToken = decoded['access_token'] as String?;
      final expiresIn = (decoded['expires_in'] ?? 3600) as int;
      if (accessToken == null) {
        throw ReachShipException(
          'OAuth response missing access_token',
          statusCode: res.statusCode,
          data: decoded,
        );
      }
      _token = _Token(
        accessToken: accessToken,
        expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      );
      return;
    }

    if (res.statusCode == 401) {
      throw UnauthorizedException(
        decoded['error_description'] ??
            decoded['message'] ??
            'Invalid client credentials',
        statusCode: res.statusCode,
        data: decoded,
      );
    }

    throw ReachShipException(
      decoded['message'] ?? 'OAuth failed',
      statusCode: res.statusCode,
      data: decoded,
    );
  }

  // -------------------------
  // Public API: Rates
  // -------------------------

  /// Get real-time shipping rates.
  ///
  /// According to ReachShip API, the payload should contain:
  /// - shipment object with ship_to, ship_from, and packages arrays
  /// - optional rates_options object
  Future<Map<String, dynamic>> getRates({
    required Map<String, dynamic> shipTo,
    required Map<String, dynamic> shipFrom,
    required List<Map<String, dynamic>> packages,
    Map<String, dynamic>? ratesOptions,
  }) async {
    // Transform packages to match ReachShip API format
    final transformedPackages = packages.map((package) {
      // Convert weight unit to ReachShip API format (only KG or LB allowed)
      String weightUnit = 'KG'; // default
      final originalWeightUnit = (package['weight_unit'] as String?)?.toLowerCase() ?? 'kg';
      if (originalWeightUnit == 'lb' || originalWeightUnit == 'lbs' || originalWeightUnit == 'pound' || originalWeightUnit == 'pounds') {
        weightUnit = 'LB';
      } else if (originalWeightUnit == 'kg' || originalWeightUnit == 'kgs' || originalWeightUnit == 'kilogram' || originalWeightUnit == 'kilograms') {
        weightUnit = 'KG';
      }

      // Convert dimension unit to ReachShip API format
      String dimensionUnit = 'CM'; // default
      final originalDimensionUnit = (package['dimension_unit'] as String?)?.toLowerCase() ?? 'cm';
      if (originalDimensionUnit == 'in' || originalDimensionUnit == 'inch' || originalDimensionUnit == 'inches') {
        dimensionUnit = 'IN';
      } else if (originalDimensionUnit == 'cm' || originalDimensionUnit == 'centimeter' || originalDimensionUnit == 'centimeters') {
        dimensionUnit = 'CM';
      } else if (originalDimensionUnit == 'ft' || originalDimensionUnit == 'foot' || originalDimensionUnit == 'feet') {
        dimensionUnit = 'FT';
      } else if (originalDimensionUnit == 'm' || originalDimensionUnit == 'meter' || originalDimensionUnit == 'meters') {
        dimensionUnit = 'M';
      }

      return {
        'weight': {
          'value': package['weight'],
          'unit': weightUnit,
        },
        'dimensions': {
          'length': package['length'],
          'width': package['width'],
          'height': package['height'],
          'unit': dimensionUnit,
        },
        if (package['description'] != null) 'description': package['description'],
        if (package['declared_value'] != null) 'declared_value': package['declared_value'],
      };
    }).toList();

    // Transform addresses to match ReachShip API format
    final transformedShipTo = {
      if (shipTo['name'] != null) 'name': shipTo['name'],
      if (shipTo['company'] != null) 'company': shipTo['company'],
      'address_line_1': shipTo['street1'],
      if (shipTo['street2'] != null) 'address_line_2': shipTo['street2'],
      'city_locality': shipTo['city'],
      'state_province': shipTo['state'],
      'postal_code': shipTo['postal_code'],
      'country_code': CountryCodeMapper.getCountryCode(shipTo['country'] ?? ''),
      if (shipTo['phone'] != null) 'phone': shipTo['phone'],
      if (shipTo['email'] != null) 'email': shipTo['email'],
    };

    final transformedShipFrom = {
      if (shipFrom['name'] != null) 'name': shipFrom['name'],
      if (shipFrom['company'] != null) 'company': shipFrom['company'],
      'address_line_1': shipFrom['street1'],
      if (shipFrom['street2'] != null) 'address_line_2': shipFrom['street2'],
      'city_locality': shipFrom['city'],
      'state_province': shipFrom['state'],
      'postal_code': shipFrom['postal_code'],
      'country_code': CountryCodeMapper.getCountryCode(shipFrom['country'] ?? ''),
      if (shipFrom['phone'] != null) 'phone': shipFrom['phone'],
      if (shipFrom['email'] != null) 'email': shipFrom['email'],
    };

    final payload = {
      'shipment': {
        'ship_to': transformedShipTo,
        'ship_from': transformedShipFrom,
        'packages': transformedPackages,
      },
      if (ratesOptions != null) 'rates_options': ratesOptions,
    };

    return await _request(method: 'POST', path: '/rates', body: payload);
  }

  // -------------------------
  // Public API: Shipments
  // -------------------------

  /// Create a shipment and print label
  ///
  /// According to ReachShip API, uses /print-label endpoint with carrier and shipment objects
  Future<Map<String, dynamic>> createShipment({
    required Map<String, dynamic> carrier,
    required Map<String, dynamic> shipTo,
    required Map<String, dynamic> shipFrom,
    required List<Map<String, dynamic>> packages,
    required String shipDate,
    Map<String, dynamic>? additionalOptions,
    Map<String, dynamic>? order,
    Map<String, dynamic>? orderAndPickup,
    Map<String, dynamic>? label,
  }) async {
    final payload = {
      'carrier': carrier,
      'shipment': {
        'ship_to': shipTo,
        'ship_from': shipFrom,
        'ship_date': shipDate,
        'packages': packages,
      },
      if (additionalOptions != null) 'additional_options': additionalOptions,
      if (order != null) 'order': order,
      if (orderAndPickup != null) 'order_and_pickup': orderAndPickup,
      if (label != null) 'label': label,
    };

    return await _request(method: 'POST', path: '/print-label', body: payload);
  }



  /// Get list of shipments with optional filters
  /// Note: ReachShip API doesn't provide a direct endpoint to list all shipments.
  /// This method returns an empty list as a placeholder until a proper solution is implemented.
  Future<Map<String, dynamic>> getShipments({
    int? limit,
    int? offset,
    String? status,
    String? orderId,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    // ReachShip API doesn't have a /shipments endpoint for listing shipments
    // This is a temporary implementation that returns empty results
    // In a real implementation, you would need to:
    // 1. Store shipment data locally after creation
    // 2. Use a different API endpoint if available
    // 3. Implement a custom backend to track shipments
    
    return {
      'shipments': <Map<String, dynamic>>[],
      'total': 0,
      'page': offset ?? 0,
      'limit': limit ?? 50,
    };
  }



  // -------------------------
  // Public API: Tracking
  // -------------------------

  /// Track shipment by carrier and tracking number
  /// According to ReachShip API, uses POST method with carrier_name and tracking_number
  Future<Map<String, dynamic>> trackShipment({
    required String carrierName,
    required String trackingNumber,
    String? accountName,
  }) async {
    final payload = {
      'carrier_name': carrierName,
      'tracking_number': trackingNumber,
      if (accountName != null) 'account_name': accountName,
    };

    return await _request(
      method: 'POST',
      path: '/track-shipment',
      body: payload,
    );
  }

  /// Legacy method for backward compatibility - now uses the correct API
  @Deprecated('Use trackShipment with carrierName and trackingNumber instead')
  Future<Map<String, dynamic>> trackByNumber(String trackingNumber) async {
    // This method is deprecated as ReachShip requires carrier_name
    throw ReachShipException(
      'trackByNumber is deprecated. Use trackShipment with carrierName and trackingNumber instead.',
    );
  }

  // -------------------------
  // Public API: Manifest Management
  // -------------------------

  /// Create manifest for shipments
  /// According to ReachShip API, uses carrier and manifest_options format
  Future<Map<String, dynamic>> createManifest({
    required Map<String, dynamic> carrier,
    required Map<String, dynamic> manifestOptions,
  }) async {
    final payload = {
      'carrier': carrier,
      'manifest_options': manifestOptions,
    };

    return await _request(
      method: 'POST',
      path: '/create-manifest',
      body: payload,
    );
  }

  /// Recover shipment URL
  /// According to ReachShip API, recovers a shipment label URL
  Future<Map<String, dynamic>> recoverShipmentUrl({
    required String url,
  }) async {
    final payload = {
      'url': url,
    };

    return await _request(
      method: 'POST',
      path: '/recover-shipment-url',
      body: payload,
    );
  }

  // -------------------------
  // Public API: Shipment Management
  // -------------------------

  /// Delete multiple shipments
  /// According to ReachShip API, uses POST method with carrier_name and shipment_ids
  Future<Map<String, dynamic>> deleteShipments({
    required String carrierName,
    List<String>? shipmentIds,
    List<String>? trackingIds,
    List<String>? orderIds,
    String? accountName,
  }) async {
    final payload = {
      'carrier_name': carrierName,
      if (shipmentIds != null && shipmentIds.isNotEmpty) 'shipment_ids': shipmentIds,
      if (trackingIds != null && trackingIds.isNotEmpty) 'tracking_ids': trackingIds,
      if (orderIds != null && orderIds.isNotEmpty) 'order_ids': orderIds,
      if (accountName != null) 'account_name': accountName,
    };

    return await _request(
      method: 'POST',
      path: '/delete-shipments',
      body: payload,
    );
  }

  // -------------------------
  // Public API: Carrier Credentials
  // -------------------------

  /// Save carrier credentials
  /// According to ReachShip API, uses specific carrier credential format
  Future<Map<String, dynamic>> saveCarrierCredentials({
    required String carrier,
    required String accountName,
    required Map<String, dynamic> credentials,
  }) async {
    final payload = {
      'carrier': carrier,
      'account_name': accountName,
      ...credentials, // Spread the carrier-specific credentials
    };

    return await _request(
      method: 'POST',
      path: '/save-carrier-credentials',
      body: payload,
    );
  }

  /// Get carrier credentials summary
  /// According to ReachShip API, uses GET method
  Future<Map<String, dynamic>> getCarrierCredentialsSummary() async {
    return await _request(
      method: 'GET',
      path: '/get-carrier-credentials-summary',
    );
  }

  /// Update carrier credentials
  /// According to ReachShip API, uses POST method with same format as save
  Future<Map<String, dynamic>> updateCarrierCredentials({
    required String carrier,
    required String accountName,
    required Map<String, dynamic> credentials,
  }) async {
    final payload = {
      'carrier': carrier,
      'account_name': accountName,
      ...credentials, // Spread the carrier-specific credentials
    };

    return await _request(
      method: 'POST',
      path: '/update-carrier-credentials',
      body: payload,
    );
  }

  /// Delete carrier credentials
  /// According to ReachShip API, uses POST method
  Future<Map<String, dynamic>> deleteCarrierCredentials({
    required String carrier,
    required String accountName,
    String? alternativePrimaryAccountName,
  }) async {
    final payload = {
      'carrier': carrier,
      'account_name': accountName,
      if (alternativePrimaryAccountName != null) 
        'alternative_primary_account_name': alternativePrimaryAccountName,
    };

    return await _request(
      method: 'POST',
      path: '/delete-carrier-credentials',
      body: payload,
    );
  }

  // -------------------------
  // Public API: Pickups
  // -------------------------

  /// Schedule a pickup
  /// According to ReachShip API, uses specific format with shipper, carrier, pickup_window, etc.
  Future<Map<String, dynamic>> schedulePickup({
    required Map<String, dynamic> shipper,
    required Map<String, dynamic> carrier,
    required Map<String, dynamic> pickupWindow,
    required List<Map<String, dynamic>> packages,
    required List<String> trackingIds,
    String? destinationCountryCode,
    Map<String, dynamic>? pickupOptions,
    Map<String, dynamic>? auspostMypostCreatePickup,
    Map<String, dynamic>? uspsCreatePickup,
  }) async {
    final payload = {
      'shipper': shipper,
      'carrier': carrier,
      'pickup_window': pickupWindow,
      'packages': packages,
      'tracking_ids': trackingIds,
      if (destinationCountryCode != null) 'destination_country_code': destinationCountryCode,
      if (pickupOptions != null) 'pickup_options': pickupOptions,
      if (auspostMypostCreatePickup != null) 'auspost_mypost_create_pickup': auspostMypostCreatePickup,
      if (uspsCreatePickup != null) 'usps_create_pickup': uspsCreatePickup,
    };

    return await _request(method: 'POST', path: '/schedule-pickup', body: payload);
  }

  /// Cancel a pickup
  /// According to ReachShip API, uses POST method with carrier-specific details
  Future<Map<String, dynamic>> cancelPickup({
    required String carrierName,
    String? accountName,
    Map<String, dynamic>? dhlExpress,
    Map<String, dynamic>? usps,
    Map<String, dynamic>? ups,
    Map<String, dynamic>? fedex,
  }) async {
    final payload = {
      'carrier_name': carrierName,
      if (accountName != null) 'account_name': accountName,
      if (dhlExpress != null) 'dhl_express': dhlExpress,
      if (usps != null) 'usps': usps,
      if (ups != null) 'ups': ups,
      if (fedex != null) 'fedex': fedex,
    };

    return await _request(method: 'POST', path: '/cancel-pickup', body: payload);
  }



  // -------------------------
  // Helpers (HTTP + Auth + Retry)
  // -------------------------
  Map<String, String> _authHeaders({Map<String, String>? extra}) {
    final map = <String, String>{
      'Authorization': 'Bearer ${_token?.accessToken ?? ''}',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (extra != null) map.addAll(extra);
    return map;
  }

  Future<Map<String, dynamic>> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? query,
    Map<String, String>? headers,
  }) async {
    await _ensureToken();

    final uri = Uri.parse(
      '${config.baseUrl}$path',
    ).replace(queryParameters: {if (query != null) ...query});

    final reqHeaders = _authHeaders(extra: headers);

    final http.Response res = await _withRetry(() async {
      switch (method.toUpperCase()) {
        case 'GET':
          return _client.get(uri, headers: reqHeaders).timeout(timeout);
        case 'POST':
          return _client
              .post(uri, headers: reqHeaders, body: jsonEncode(body ?? {}))
              .timeout(timeout);
        case 'PUT':
          return _client
              .put(uri, headers: reqHeaders, body: jsonEncode(body ?? {}))
              .timeout(timeout);
        case 'DELETE':
          return _client
              .delete(uri, headers: reqHeaders, body: jsonEncode(body ?? {}))
              .timeout(timeout);
        default:
          throw ReachShipException('Unsupported method: $method');
      }
    });

    // Parse
    Map<String, dynamic> decoded;
    try {
      decoded = _safeDecode(res.body);
    } catch (_) {
      decoded = {'raw': res.body};
    }

    // Success
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    // Errors
    if (res.statusCode == 401) {
      // Token may be expired or invalid → force refresh once
      _token = null;
      if (method.toUpperCase() == 'GET') {
        // Try once more after refresh for idempotent GET
        await _ensureToken();
        return _request(
          method: method,
          path: path,
          body: body,
          query: query,
          headers: headers,
        );
      }
      throw UnauthorizedException(
        decoded['message'] ?? 'Unauthorized',
        statusCode: res.statusCode,
        data: decoded,
      );
    }

    if (res.statusCode == 429) {
      final retryAfter = _parseRetryAfter(res.headers['retry-after']);
      throw RateLimitException(
        decoded['message'] ?? 'Rate limited',
        statusCode: res.statusCode,
        data: decoded,
        retryAfter: retryAfter,
      );
    }

    throw ReachShipException(
      decoded['message'] ?? 'Request failed',
      statusCode: res.statusCode,
      data: decoded,
    );
  }

  Future<http.Response> _withRetry(Future<http.Response> Function() fn) async {
    int attempt = 0;
    Object? lastErr;
    while (attempt <= maxRetries) {
      try {
        final res = await fn();
        if (_isTransient(res.statusCode)) {
          // Backoff on 429/5xx
          final delay = _backoff(attempt);
          await Future.delayed(delay);
          attempt++;
          continue;
        }
        return res;
      } on TimeoutException catch (e) {
        lastErr = e;
        if (attempt == maxRetries) rethrow;
        await Future.delayed(_backoff(attempt));
        attempt++;
      } on http.ClientException catch (e) {
        lastErr = e;
        if (attempt == maxRetries) rethrow;
        await Future.delayed(_backoff(attempt));
        attempt++;
      } catch (e) {
        lastErr = e;
        if (attempt == maxRetries) rethrow;
        await Future.delayed(_backoff(attempt));
        attempt++;
      }
    }
    throw NetworkException('Network error: $lastErr');
  }

  static bool _isTransient(int? status) {
    if (status == null) return false;
    return status == 429 || (status >= 500 && status < 600);
  }

  static Duration _backoff(int attempt) =>
      Duration(milliseconds: 400 * (attempt + 1) * (attempt + 1));

  static Map<String, dynamic> _safeDecode(String body) {
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': body};
    }
  }

  static Duration? _parseRetryAfter(String? header) {
    if (header == null) return null;
    // Can be seconds or HTTP-date
    final secs = int.tryParse(header);
    if (secs != null) return Duration(seconds: secs);
    // Not handling HTTP-date flavor to keep it simple.
    return null;
  }

  /// Get access token (for backward compatibility)
  /// This method ensures a valid token is available and returns it
  Future<String> getAccessToken() async {
    await _ensureToken();
    return _token?.accessToken ?? '';
  }

  void dispose() {
    _client.close();
  }
}
