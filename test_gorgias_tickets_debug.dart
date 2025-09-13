import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('=== Comprehensive Gorgias API Test ===');
  
  // Hardcoded credentials from the logs
  final token = '9968e8ff2d32c79cd81a5dffb50f80348d';
  final subdomain = 'profoundaminos';
  final username = 'justin@profoundaminos.com';
  
  print('Token: $token');
  print('Subdomain: $subdomain');
  print('Username: $username');
  
  final credentials = base64Encode(utf8.encode('$username:$token'));
  print('Base64 credentials: $credentials');
  
  final headers = {
    'Authorization': 'Basic $credentials',
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  
  // Test 1: /account endpoint (this should work)
  print('\n--- Test 1: /account endpoint ---');
  await testEndpoint('https://$subdomain.gorgias.com/api/account', headers);
  
  // Test 2: /tickets endpoint with minimal params
  print('\n--- Test 2: /tickets endpoint (minimal) ---');
  await testEndpoint('https://$subdomain.gorgias.com/api/tickets', headers);
  
  // Test 3: /tickets endpoint with limit=1 (new pagination)
  print('\n--- Test 3: /tickets endpoint (limit=1) ---');
  await testEndpoint('https://$subdomain.gorgias.com/api/tickets?limit=1', headers);
  
  // Test 4: /tickets endpoint with limit=20 (updated from old page/per_page)
  print('\n--- Test 4: /tickets endpoint (limit=20) ---');
  await testEndpoint('https://$subdomain.gorgias.com/api/tickets?limit=20', headers);
  
  // Test 5: /customers endpoint (to check general API access)
  print('\n--- Test 5: /customers endpoint ---');
  await testEndpoint('https://$subdomain.gorgias.com/api/customers?limit=1', headers);
  
  print('\n=== Test Complete ===');
}

Future<void> testEndpoint(String url, Map<String, String> headers) async {
  try {
    print('URL: $url');
    final response = await http.get(Uri.parse(url), headers: headers);
    
    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');
    
    if (response.body.length > 500) {
      print('Response (truncated): ${response.body.substring(0, 500)}...');
    } else {
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
  }
}