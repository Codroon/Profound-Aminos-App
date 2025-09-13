import 'dart:convert';
import 'package:http/http.dart' as http;
import 'crediential_storage_service.dart';

class GorgiasDebugService {
  static Future<Map<String, dynamic>> debugGorgiasCredentials() async {
    print('[GorgiasDebug] Starting credential debug...');
    
    final debugInfo = <String, dynamic>{};
    
    try {
      final credentialStorage = CredentialStorageService();
      final credentials = await credentialStorage.getCredentials();
      
      final token = credentials['gorgiasToken'];
      final subdomain = credentials['gorgiasSub'];
      final username = credentials['gorgiasUserName'];
      
      debugInfo['tokenExists'] = token?.isNotEmpty == true;
      debugInfo['tokenLength'] = token?.length ?? 0;
      debugInfo['subdomain'] = subdomain;
      debugInfo['username'] = username;
      
      print('[GorgiasDebug] Token exists: ${debugInfo['tokenExists']}');
      print('[GorgiasDebug] Token length: ${debugInfo['tokenLength']}');
      print('[GorgiasDebug] Full token: $token');
      print('[GorgiasDebug] Subdomain: $subdomain');
      print('[GorgiasDebug] Username: $username');
      
      if (token?.isNotEmpty == true && subdomain?.isNotEmpty == true && username?.isNotEmpty == true) {
        // Test the token with a simple API call using Basic Authentication
        final url = 'https://$subdomain.gorgias.com/api/account';
        debugInfo['testUrl'] = url;
        
        print('[GorgiasDebug] Testing token with URL: $url');
        
        // Gorgias uses Basic Authentication: base64encode(USERNAME:API_KEY)
        final credentials_encoded = base64Encode(utf8.encode('$username:$token'));
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Basic $credentials_encoded',
            'Accept': 'application/json',
          },
        );
        
        debugInfo['responseStatus'] = response.statusCode;
        debugInfo['responseHeaders'] = response.headers;
        
        print('[GorgiasDebug] Response status: ${response.statusCode}');
        print('[GorgiasDebug] Response headers: ${response.headers}');
        
        if (response.statusCode == 200) {
          debugInfo['tokenValid'] = true;
          print('[GorgiasDebug] ✅ Token is valid!');
          final data = json.decode(response.body);
          debugInfo['accountName'] = data['name'] ?? 'Unknown';
          print('[GorgiasDebug] Account info: ${debugInfo['accountName']}');
        } else {
          debugInfo['tokenValid'] = false;
          debugInfo['errorMessage'] = 'Token validation failed';
          debugInfo['responseBody'] = response.body;
          
          print('[GorgiasDebug] ❌ Token validation failed');
          print('[GorgiasDebug] Response body: ${response.body}');
          
          if (response.statusCode == 401) {
            debugInfo['errorType'] = 'unauthorized';
            print('[GorgiasDebug] 401 Unauthorized - Token is expired or invalid');
          } else if (response.statusCode == 403) {
            debugInfo['errorType'] = 'forbidden';
            print('[GorgiasDebug] 403 Forbidden - Token lacks required permissions');
          }
        }
      } else {
        debugInfo['tokenValid'] = false;
        debugInfo['errorMessage'] = 'Missing credentials';
        debugInfo['tokenEmpty'] = token?.isEmpty ?? true;
        debugInfo['subdomainEmpty'] = subdomain?.isEmpty ?? true;
        
        print('[GorgiasDebug] ❌ Missing credentials');
        print('[GorgiasDebug] Token empty: ${token?.isEmpty ?? true}');
        print('[GorgiasDebug] Subdomain empty: ${subdomain?.isEmpty ?? true}');
      }
    } catch (e) {
      debugInfo['tokenValid'] = false;
      debugInfo['errorMessage'] = 'Exception during debug';
      debugInfo['exception'] = e.toString();
      print('[GorgiasDebug] ❌ Exception during debug: $e');
    }
    
    return debugInfo;
  }
  
  static Future<void> testGorgiasTicketsEndpoint() async {
    print('[GorgiasDebug] Testing tickets endpoint...');
    
    try {
      final credentialStorage = CredentialStorageService();
      final credentials = await credentialStorage.getCredentials();
      
      final token = credentials['gorgiasToken'];
      final subdomain = credentials['gorgiasSub'];
      final username = credentials['gorgiasUserName'];
      
      if (token?.isNotEmpty == true && subdomain?.isNotEmpty == true && username?.isNotEmpty == true) {
        final url = 'https://$subdomain.gorgias.com/api/tickets?limit=1';
        
        print('[GorgiasDebug] Testing tickets URL: $url');
        
        // Gorgias uses Basic Authentication: base64encode(USERNAME:API_KEY)
        final credentials_encoded = base64Encode(utf8.encode('$username:$token'));
        
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Basic $credentials_encoded',
            'Accept': 'application/json',
          },
        );
        
        print('[GorgiasDebug] Tickets response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          print('[GorgiasDebug] ✅ Tickets endpoint accessible!');
          final data = json.decode(response.body);
          final meta = data['meta'] ?? {};
          print('[GorgiasDebug] Total tickets: ${meta['total_count'] ?? 'Unknown'}');
        } else {
          print('[GorgiasDebug] ❌ Tickets endpoint failed');
          print('[GorgiasDebug] Response body: ${response.body}');
        }
      }
    } catch (e) {
      print('[GorgiasDebug] ❌ Exception during tickets test: $e');
    }
  }
}