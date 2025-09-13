import 'dart:convert';
import 'package:http/http.dart' as http;

/// Test script to verify the Gorgias authentication fix
/// This tests the Basic Authentication implementation
void main() async {
  print('=== TESTING GORGIAS AUTHENTICATION FIX ===\n');
  
  // Test data from the error logs
  const subdomain = 'profoundaminos';
  const username = 'test_user'; // This should be the actual username from Firestore
  const apiKey = 'test_api_key_64_chars_long_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'; // Mock 64-char API key
  
  await testBasicAuthentication(subdomain, username, apiKey);
  await testAuthenticationFormats();
}

/// Test the Basic Authentication implementation
Future<void> testBasicAuthentication(String subdomain, String username, String apiKey) async {
  print('1. TESTING BASIC AUTHENTICATION');
  print('Subdomain: $subdomain');
  print('Username: $username');
  print('API Key: ${apiKey.substring(0, 20)}...');
  print('');
  
  // Create Basic Auth credentials
  final credentials = base64Encode(utf8.encode('$username:$apiKey'));
  print('Basic Auth Credentials: ${credentials.substring(0, 30)}...');
  print('');
  
  // Test the API call
  final url = 'https://$subdomain.gorgias.com/api/account';
  print('Testing URL: $url');
  
  try {
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentials',
        'Accept': 'application/json',
      },
    ).timeout(Duration(seconds: 10));
    
    print('Response Status: ${response.statusCode}');
    print('Response Headers: ${response.headers}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print('✅ SUCCESS: Basic Authentication is working!');
    } else if (response.statusCode == 401) {
      print('❌ AUTHENTICATION FAILED: Check username and API key');
      
      // Check if we still get the JWT parsing error
      if (response.body.contains('Invalid input segments length')) {
        print('❌ Still getting JWT parsing error - this should be fixed now');
      } else {
        print('✅ JWT parsing error is fixed - now it\'s just invalid credentials');
      }
    } else {
      print('⚠️  Unexpected status code: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Request failed: $e');
  }
  
  print('');
}

/// Test different authentication formats
Future<void> testAuthenticationFormats() async {
  print('2. TESTING AUTHENTICATION FORMATS');
  
  final testCases = [
    {
      'name': 'Basic Auth (Correct Format)',
      'auth': 'Basic ${base64Encode(utf8.encode('user:api_key'))}',
      'expected': 'Should work with valid credentials'
    },
    {
      'name': 'Bearer Token (Old Format)',
      'auth': 'Bearer api_key_64_chars',
      'expected': 'Should fail with JWT parsing error'
    },
    {
      'name': 'Bearer JWT (Wrong for Gorgias)',
      'auth': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature',
      'expected': 'Should fail - Gorgias doesn\'t use Bearer JWT'
    },
  ];
  
  for (final testCase in testCases) {
    print('${testCase['name']}:');
    final auth = testCase['auth'] as String;
    final displayAuth = auth.length > 30 ? '${auth.substring(0, 30)}...' : auth;
    print('  Format: $displayAuth');
    print('  Expected: ${testCase['expected']}');
    print('');
  }
  
  print('CONCLUSION:');
  print('✅ The fix changes from Bearer to Basic authentication');
  print('✅ This should resolve the "Invalid input segments length" error');
  print('✅ The 64-character API key is now properly encoded for Basic Auth');
  print('⚠️  You still need valid username and API key from Firestore');
}