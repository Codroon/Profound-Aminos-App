import 'dart:convert';
import 'package:http/http.dart' as http;

import 'crediential_storage_service.dart';

class ApiService {
  final Map<String, String> creds;

  ApiService(this.creds);

  String _basicAuth(String user, String pass) {
    final str = '$user:$pass';
    return 'Basic ${base64Encode(utf8.encode(str))}';
  }

  Future<bool> testWooCommerce() async {
    final url = '${creds['wooUrl']}/wp-json/wc/v3/orders';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _basicAuth(creds['wooKey']!, creds['wooSecret']!),
        },
      );
      print('[WooCommerce] Status: ${res.statusCode}, Body: ${res.body}');
      if (res.statusCode != 200) {
        print('[WooCommerce] Credential issue: Key/Secret/URL may be invalid.');
      }
      return res.statusCode == 200;
    } catch (e) {
      print('[WooCommerce] Exception: ${e.toString()}');
      return false;
    }
  }

  Future<bool> testWordPress() async {
    if ((creds['wpUser']?.isEmpty ?? true) ||
        (creds['wpPass']?.isEmpty ?? true)) {
      print(
        '[WordPress] Skipping test: Username or App Password not provided.',
      );
      return true;
    }
    final url = '${creds['wooUrl']}/wp-json/wp/v2/users/me';
    try {
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _basicAuth(creds['wpUser']!, creds['wpPass']!),
        },
      );
      print('[WordPress] Status: ${res.statusCode}, Body: ${res.body}');
      if (res.statusCode != 200) {
        print(
          '[WordPress] Credential issue: Username/App Password/URL may be invalid.',
        );
      }
      return res.statusCode == 200;
    } catch (e) {
      print('[WordPress] Exception: ${e.toString()}');
      return false;
    }
  }

  Future<bool> testGorgias() async {
    if ((creds['gorgiasToken']?.isEmpty ?? true) ||
        (creds['gorgiasSub']?.isEmpty ?? true) ||
        (creds['gorgiasUserName']?.isEmpty ?? true)) {
      print('[Gorgias] Skipping test: Token, Subdomain, or Username not provided.');
      return true;
    }
    final url = 'https://${creds['gorgiasSub']}.gorgias.com/api/tickets';
    try {
      // Gorgias uses Basic Authentication: base64encode(USERNAME:API_KEY)
      final username = creds['gorgiasUserName'] ?? '';
      final apiKey = creds['gorgiasToken'] ?? '';
      final credentials = base64Encode(utf8.encode('$username:$apiKey'));
      
      final res = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Basic $credentials',
          'Accept': 'application/json',
        },
      );
      print('[Gorgias] Status: ${res.statusCode}, Body: ${res.body}');
      if (res.statusCode != 200) {
        print('[Gorgias] Credential issue: Username/Token/Subdomain may be invalid.');
      }
      return res.statusCode == 200;
    } catch (e) {
      print('[Gorgias] Exception: ${e.toString()}');
      return false;
    }
  }

  // Gorgias API request method with automatic token refresh
  Future<Map<String, dynamic>> makeGorgiasRequest({
    required String endpoint,
    required String method,
    Map<String, String>? queryParams,
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    // Validate required credentials
    final token = creds['gorgiasToken'];
    final subdomain = creds['gorgiasSub'];
    final username = creds['gorgiasUserName'];
    
    if (token?.isEmpty ?? true) {
      return {
        'success': false,
        'message': 'Gorgias API token is missing. Please configure your Gorgias credentials.',
        'data': null,
      };
    }
    
    if (subdomain?.isEmpty ?? true) {
      return {
        'success': false,
        'message': 'Gorgias subdomain is missing. Please configure your Gorgias credentials.',
        'data': null,
      };
    }
    
    if (username?.isEmpty ?? true) {
      return {
        'success': false,
        'message': 'Gorgias username is missing. Please configure your Gorgias credentials.',
        'data': null,
      };
    }

    try {
      // Build URL
      var url = 'https://${creds['gorgiasSub']}.gorgias.com/api$endpoint';

      // Add query parameters
      if (queryParams != null && queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map(
              (e) =>
                  '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
            )
            .join('&');
        url += '?$queryString';
      }

      // Prepare headers - Gorgias uses Basic Authentication
      // Format: Authorization: Basic base64encode(USERNAME:API_KEY)
      final username = creds['gorgiasUserName'] ?? '';
      final apiKey = creds['gorgiasToken'] ?? '';
      print('[GorgiasAPI] Username: $username');
      print('[GorgiasAPI] Token: $apiKey');
      print('[GorgiasAPI] Token length: ${apiKey.length}');
      final credentials = base64Encode(utf8.encode('$username:$apiKey'));
      print('[GorgiasAPI] Base64 credentials: $credentials');
      
      final headers = {
        'Authorization': 'Basic $credentials',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

      // Debug logging
      print('[GorgiasAPI] Making request to: $url');
      print('[GorgiasAPI] Headers: $headers');
      print('[GorgiasAPI] Method: ${method.toUpperCase()}');
      
      // Make request
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? json.encode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          return {
            'success': false,
            'message': 'Unsupported HTTP method: $method',
            'data': null,
          };
      }

      // Debug response
      print('[GorgiasAPI] Response status: ${response.statusCode}');
      print('[GorgiasAPI] Response body: ${response.body}');
      
      // Parse response
      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (e) {
        responseData = {'message': response.body};
      }

      // Check status code
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': 'Request successful',
          'data': responseData,
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401 && !isRetry) {
        // Token expired or invalid, try to refresh credentials
        print('[Gorgias] 401 error detected, attempting to refresh credentials...');
        
        try {
          // Reload credentials from storage
          final credentialStorage = CredentialStorageService();
          final freshCredentials = await credentialStorage.getCredentials();
          
          // Update current credentials
          freshCredentials.forEach((key, value) {
            if (value != null && value.isNotEmpty) {
              creds[key] = value;
            }
          });
          
          print('[Gorgias] Credentials refreshed, retrying request...');
          
          // Retry the request once with fresh credentials
          return await makeGorgiasRequest(
            endpoint: endpoint,
            method: method,
            queryParams: queryParams,
            body: body,
            isRetry: true,
          );
        } catch (refreshError) {
          print('[Gorgias] Failed to refresh credentials: $refreshError');
          return {
            'success': false,
            'message': 'Authentication failed. Please check your Gorgias token and try logging in again.',
            'data': responseData,
            'statusCode': response.statusCode,
          };
        }
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Request failed with status ${response.statusCode}',
          'data': responseData,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': null,
      };
    }
  }

  static Future<void> getReachShipToken() async {
    const clientId = 'w2iuTRwQyoE9TPZLW1GU7FijeApM6VShDk';
    const clientSecret = 'iZbXqR9NTQIkti5OEij9MAg3Spa9labJ';

    final url = Uri.parse(
      'https://api.reachship.com/sandbox/v1/oauth/token'
      '?grant_type=client_credentials'
      '&client_id=$clientId'
      '&client_secret=$clientSecret',
    );

    try {
      final res = await http.get(url, headers: {'Accept': 'application/json'});

      print('[ReachShip Auth] Status: ${res.statusCode}');
      print('[ReachShip Auth] Body: ${res.body}');
    } catch (e) {
      print('[ReachShip Auth] Exception: $e');
    }
  }

  static Future<void> getProReachShipToken() async {
    const clientId = 'VpDMVB1z7Tyqgw6zeZruZ0yXPt3OoTRcIi';
    const clientSecret = 'hJeN9YRO5UZPxXiSzFOOXbOHdHbd3WZ0';

    final url = Uri.parse(
      'https://api.reachship.com/production/v1/oauth/token'
      '?grant_type=client_credentials'
      '&client_id=$clientId'
      '&client_secret=$clientSecret',
    );

    try {
      final res = await http.get(url, headers: {'Accept': 'application/json'});

      print('[ReachShip Auth] Status: ${res.statusCode}');
      print('[ReachShip Auth] Body: ${res.body}');
    } catch (e) {
      print('[ReachShip Auth] Exception: $e');
    }
  }

  /// Temporary method to set working ReachShip credentials for testing
  Future<void> setTestReachShipCredentials() async {
    final testCreds = {
      'reachShipClientId': 'w2iuTRwQyoE9TPZLW1GU7FijeApM6VShDk',
      'reachShipClientSecret': 'iZbXqR9NTQIkti5OEij9MAg3Spa9labJ',
      'reachShipEnv': 'sandbox',
    };

    final storage = CredentialStorageService();
    await storage.saveCredentials(testCreds);
    print('[ReachShip] Test credentials saved to storage');

    // Verify credentials were saved correctly
    final savedCreds = await storage.getCredentials();
    print(
      '[ReachShip] Verification - ClientId: ${savedCreds['reachShipClientId']}',
    );
    print(
      '[ReachShip] Verification - Environment: ${savedCreds['reachShipEnv']}',
    );
  }

  Future<bool> testReachShip() async {
    var clientId = creds['reachShipClientId'];
    var clientSecret = creds['reachShipClientSecret'];
    var env = (creds['reachShipEnv'] ?? 'sandbox').toString().toLowerCase();

    print('[ReachShip] Debug - Stored credentials:');
    print('[ReachShip] ClientId: $clientId');
    print('[ReachShip] ClientSecret: $clientSecret');
    print('[ReachShip] Environment: $env');

    // Use fallback credentials if stored credentials are missing or empty
    if (clientId == null ||
        clientId.isEmpty ||
        clientSecret == null ||
        clientSecret.isEmpty) {
      print('[ReachShip] Using fallback credentials due to missing stored credentials');
      
      if (env.contains('prod') || env.contains('production')) {
        // Production fallback credentials
        clientId = 'VpDMVB1z7Tyqgw6zeZruZ0yXPt3OoTRcIi';
        clientSecret = 'hJeN9YRO5UZPxXiSzFOOXbOHdHbd3WZ0';
        env = 'production';
        print('[ReachShip] Using production fallback credentials');
      } else {
        // Sandbox fallback credentials (default)
        clientId = 'w2iuTRwQyoE9TPZLW1GU7FijeApM6VShDk';
        clientSecret = 'iZbXqR9NTQIkti5OEij9MAg3Spa9labJ';
        env = 'sandbox';
        print('[ReachShip] Using sandbox fallback credentials');
      }
    }

    final baseUrl =
        (env.contains('prod') || env.contains('production'))
            ? 'https://api.reachship.com/production/v1'
            : 'https://api.reachship.com/sandbox/v1';

    final basicAuth = base64Encode(utf8.encode('$clientId:$clientSecret'));

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/oauth/token'),
        headers: {
          'Authorization': 'Basic $basicAuth',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: 'grant_type=client_credentials',
      );
      print('[ReachShip] Status: ${res.statusCode}, Body: ${res.body}');
      return res.statusCode == 200;
    } catch (e) {
      print('[ReachShip] Exception: ${e.toString()}');
      return false;
    }
  }

  // Store the access token for reuse
  static String? _cachedAccessToken;
  static DateTime? _tokenExpiry;

  /// Get ReachShip access token using existing working methods
  static Future<String?> getReachShipAccessToken() async {
    // Check if we have a valid cached token
    if (_cachedAccessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    // Use the existing working method to get token
    const clientId = 'w2iuTRwQyoE9TPZLW1GU7FijeApM6VShDk';
    const clientSecret = 'iZbXqR9NTQIkti5OEij9MAg3Spa9labJ';

    final url = Uri.parse(
      'https://api.reachship.com/sandbox/v1/oauth/token'
      '?grant_type=client_credentials'
      '&client_id=$clientId'
      '&client_secret=$clientSecret',
    );

    try {
      final res = await http.get(url, headers: {'Accept': 'application/json'});

      print('[ReachShip AccessToken] Status: ${res.statusCode}');
      print('[ReachShip AccessToken] Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        _cachedAccessToken = data['access_token'];
        // Cache token for 1 hour (typical expiry time)
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        return _cachedAccessToken;
      } else {
        print('[ReachShip] Token error: ${res.statusCode} - ${res.body}');
        return null;
      }
    } catch (e) {
      print('[ReachShip] Token exception: ${e.toString()}');
      return null;
    }
  }

  /// Test ReachShip rates API using cached token
  static Future<Map<String, dynamic>> testReachShipRates() async {
    try {
      // Get access token using the cached method
      final accessToken = await getReachShipAccessToken();
      
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Failed to get access token',
          'data': null,
        };
      }

      // Sample shipment data for testing rates
      final testShipment = {
        'from': {
          'name': 'Test Sender',
          'company': 'Test Company',
          'address_line_1': '123 Test Street',
          'city': 'New York',
          'state': 'NY',
          'postal_code': '10001',
          'country': 'US',
        },
        'to': {
          'name': 'Test Recipient',
          'company': 'Test Recipient Company',
          'address_line_1': '456 Test Avenue',
          'city': 'Los Angeles',
          'state': 'CA',
          'postal_code': '90210',
          'country': 'US',
        },
        'packages': [
          {
            'weight': 1.5,
            'weight_unit': 'lb',
            'length': 10,
            'width': 8,
            'height': 6,
            'dimension_unit': 'in',
          },
        ],
      };

      final res = await http.post(
        Uri.parse('https://api.reachship.com/sandbox/v1/rates'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(testShipment),
      );

      print('[ReachShip Rates] Status: ${res.statusCode}');
      print('[ReachShip Rates] Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'success': true,
          'message': 'Rates retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get rates: ${res.statusCode}',
          'data': json.decode(res.body),
        };
      }
    } catch (e) {
      print('[ReachShip Rates] Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Exception: ${e.toString()}',
        'data': null,
      };
    }
  }

  /// Get ReachShip packages using cached token
  static Future<Map<String, dynamic>> getReachShipPackages() async {
    try {
      final accessToken = await getReachShipAccessToken();
      
      if (accessToken == null) {
        return {
          'success': false,
          'message': 'Failed to get access token',
          'data': null,
        };
      }

      final res = await http.get(
        Uri.parse('https://api.reachship.com/sandbox/v1/packages'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      );

      print('[ReachShip Packages] Status: ${res.statusCode}');
      print('[ReachShip Packages] Body: ${res.body}');

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          'success': true,
          'message': 'Packages retrieved successfully',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get packages: ${res.statusCode}',
          'data': json.decode(res.body),
        };
      }
    } catch (e) {
      print('[ReachShip Packages] Exception: ${e.toString()}');
      return {
        'success': false,
        'message': 'Exception: ${e.toString()}',
        'data': null,
      };
    }
  }
}
