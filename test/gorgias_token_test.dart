import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../lib/core/services/crediential_storage_service.dart';
import '../lib/core/services/gorgias_debug_service.dart';

void main() {
  // Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Gorgias Token Analysis', () {
    test('Analyze token format and structure', () async {
      // Mock token for testing - replace with actual token format analysis
      const mockToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      
      print('=== GORGIAS TOKEN ANALYSIS ===');
      print('Token length: ${mockToken.length}');
      print('Token format: ${_analyzeTokenFormat(mockToken)}');
      
      // Check if it's a JWT token
      if (_isJWTToken(mockToken)) {
        print('Token type: JWT');
        final parts = mockToken.split('.');
        print('JWT parts count: ${parts.length}');
        
        if (parts.length == 3) {
          try {
            // Decode header
            final header = _decodeJWTPart(parts[0]);
            print('JWT Header: $header');
            
            // Decode payload (be careful with sensitive data)
            final payload = _decodeJWTPart(parts[1]);
            print('JWT Payload keys: ${payload.keys.toList()}');
            
            // Check expiration
            if (payload.containsKey('exp')) {
              final exp = payload['exp'] as int;
              final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
              final now = DateTime.now();
              print('Token expires: $expDate');
              print('Token expired: ${now.isAfter(expDate)}');
            }
          } catch (e) {
            print('Error decoding JWT: $e');
          }
        }
      } else {
        print('Token type: Bearer/API Key');
        print('Token starts with: ${mockToken.substring(0, 10)}...');
      }
    });
    
    test('Test Gorgias API token validation', () async {
      // This test will use actual stored credentials
      print('\n=== GORGIAS API VALIDATION TEST ===');
      
      try {
        final debugResult = await GorgiasDebugService.debugGorgiasCredentials();
        
        print('Debug results:');
        debugResult.forEach((key, value) {
          print('  $key: $value');
        });
        
        // Analyze the specific error
        if (debugResult['responseStatus'] == 401) {
          final responseBody = debugResult['responseBody'] as String?;
          if (responseBody != null) {
            try {
              final errorData = json.decode(responseBody);
              print('\nError analysis:');
              print('  Error message: ${errorData['error']['msg']}');
              
              if (errorData['error']['msg'].contains('Invalid input segments length')) {
                print('  Issue: Token format is invalid');
                print('  Recommendation: Check token structure and encoding');
              }
            } catch (e) {
              print('  Could not parse error response: $e');
            }
          }
        }
      } catch (e) {
        print('Test failed: $e');
      }
    });
    
    test('Test token refresh mechanism', () async {
      print('\n=== TOKEN REFRESH TEST ===');
      
      try {
        final credentialStorage = CredentialStorageService();
        final beforeRefresh = await credentialStorage.getCredentials();
        
        print('Before refresh:');
        print('  Token: ${beforeRefresh['gorgiasToken']?.substring(0, 20)}...');
        print('  Subdomain: ${beforeRefresh['gorgiasSub']}');
        
        // Simulate refresh (this just reloads from storage)
        await Future.delayed(Duration(milliseconds: 100));
        
        final afterRefresh = await credentialStorage.getCredentials();
        
        print('After refresh:');
        print('  Token: ${afterRefresh['gorgiasToken']?.substring(0, 20)}...');
        print('  Subdomain: ${afterRefresh['gorgiasSub']}');
        
        final tokenChanged = beforeRefresh['gorgiasToken'] != afterRefresh['gorgiasToken'];
        print('  Token changed: $tokenChanged');
        
        if (!tokenChanged) {
          print('  Issue: Token refresh is not actually updating the token');
          print('  Recommendation: Implement proper token refresh from Gorgias OAuth');
        }
      } catch (e) {
        print('Refresh test failed: $e');
      }
    });
    
    test('Manual API call test', () async {
      print('\n=== MANUAL API CALL TEST ===');
      
      try {
        final credentialStorage = CredentialStorageService();
        final credentials = await credentialStorage.getCredentials();
        
        final token = credentials['gorgiasToken'];
        final subdomain = credentials['gorgiasSub'];
        final username = credentials['gorgiasUserName'];
        
        if (token?.isNotEmpty == true && subdomain?.isNotEmpty == true && username?.isNotEmpty == true) {
          // Test different endpoints
          final endpoints = [
            '/account',
            '/tickets?per_page=1',
            '/users/me',
          ];
          
          // Gorgias uses Basic Authentication: base64encode(USERNAME:API_KEY)
          final credentials_encoded = base64Encode(utf8.encode('$username:$token'));
          
          for (final endpoint in endpoints) {
            final url = 'https://$subdomain.gorgias.com/api$endpoint';
            print('\nTesting: $url');
            
            try {
              final response = await http.get(
                Uri.parse(url),
                headers: {
                  'Authorization': 'Basic $credentials_encoded',
                  'Accept': 'application/json',
                  'User-Agent': 'WooManagementApp/1.0',
                },
              );
              
              print('  Status: ${response.statusCode}');
              print('  Headers: ${response.headers}');
              
              if (response.statusCode != 200) {
                print('  Error body: ${response.body}');
                
                // Try to parse error
                try {
                  final errorData = json.decode(response.body);
                  if (errorData['error'] != null) {
                    print('  Parsed error: ${errorData['error']}');
                  }
                } catch (e) {
                  print('  Could not parse error response');
                }
              } else {
                print('  ✅ Success!');
              }
            } catch (e) {
              print('  ❌ Exception: $e');
            }
          }
        } else {
          print('Missing credentials - cannot test');
        }
      } catch (e) {
        print('Manual test failed: $e');
      }
    });
  });
}

// Helper functions
String _analyzeTokenFormat(String token) {
  if (token.contains('.')) {
    final parts = token.split('.');
    return 'Dot-separated (${parts.length} parts)';
  } else if (token.startsWith('Bearer ')) {
    return 'Bearer prefixed';
  } else if (RegExp(r'^[a-zA-Z0-9+/=]+$').hasMatch(token)) {
    return 'Base64-like';
  } else if (RegExp(r'^[a-fA-F0-9]+$').hasMatch(token)) {
    return 'Hexadecimal';
  } else {
    return 'Unknown format';
  }
}

bool _isJWTToken(String token) {
  return token.split('.').length == 3;
}

Map<String, dynamic> _decodeJWTPart(String part) {
  // Add padding if needed
  String padded = part;
  while (padded.length % 4 != 0) {
    padded += '=';
  }
  
  final decoded = base64Url.decode(padded);
  final jsonString = utf8.decode(decoded);
  return json.decode(jsonString);
}