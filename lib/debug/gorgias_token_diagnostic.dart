import 'dart:convert';
import 'package:http/http.dart' as http;

/// Simple diagnostic script to analyze Gorgias token issues
/// Run this with: dart run lib/debug/gorgias_token_diagnostic.dart
void main() async {
  print('=== GORGIAS TOKEN DIAGNOSTIC ===\n');
  
  // Test with the actual token from the error log
  // Based on the error "Invalid input segments length", this suggests JWT parsing issues
  await analyzeTokenIssue();
  
  // Test different token formats
  await testTokenFormats();
  
  // Test API endpoints
  await testGorgiasEndpoints();
}

/// Analyze the specific token issue from the error logs
Future<void> analyzeTokenIssue() async {
  print('1. ANALYZING TOKEN ISSUE');
  print('Error from logs: "Invalid input segments length"');
  print('This typically indicates:');
  print('  - JWT token has incorrect number of segments (should be 3)');
  print('  - Token is malformed or corrupted');
  print('  - Token encoding issues');
  print('');
  
  // Simulate the token issue
  final testTokens = [
    'invalid.token', // 2 segments - should fail
    'header.payload.signature.extra', // 4 segments - should fail
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c', // Valid JWT
    'simple_api_key_format', // Non-JWT format
  ];
  
  for (int i = 0; i < testTokens.length; i++) {
    final token = testTokens[i];
    print('Testing token ${i + 1}: ${token.length} chars');
    
    final segments = token.split('.');
    print('  Segments: ${segments.length}');
    
    if (segments.length == 3) {
      print('  Format: Valid JWT structure');
      try {
        // Try to decode the header
        _decodeBase64Url(segments[0]);
        print('  Header decoded: ✅');
        
        _decodeBase64Url(segments[1]);
        print('  Payload decoded: ✅');
      } catch (e) {
        print('  Decoding failed: ❌ $e');
      }
    } else {
      print('  Format: Invalid JWT (${segments.length} segments)');
      print('  This would cause "Invalid input segments length" error');
    }
    print('');
  }
}

/// Test different token formats that Gorgias might accept
Future<void> testTokenFormats() async {
  print('2. TESTING TOKEN FORMATS');
  
  final formats = {
    'JWT (3 segments)': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
    'API Key (64 chars)': 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2',
    'API Key (32 chars)': 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
    'Malformed JWT (2 segments)': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ',
  };
  
  formats.forEach((name, token) {
    print('$name:');
    print('  Length: ${token.length}');
    print('  Segments: ${token.split('.').length}');
    print('  Format: ${_analyzeTokenFormat(token)}');
    print('');
  });
}

/// Test Gorgias API endpoints with different approaches
Future<void> testGorgiasEndpoints() async {
  print('3. TESTING GORGIAS API ENDPOINTS');
  print('Note: Using test subdomain and token');
  
  const testSubdomain = 'profoundaminos'; // From the error logs
  const testToken = 'test_token_64_chars_long_aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'; // Mock token
  
  final endpoints = [
    '/account',
    '/tickets?per_page=1',
    '/users/me',
  ];
  
  for (final endpoint in endpoints) {
    final url = 'https://$testSubdomain.gorgias.com/api$endpoint';
    print('Testing: $endpoint');
    print('  URL: $url');
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $testToken',
          'Accept': 'application/json',
          'User-Agent': 'WooManagementApp/1.0',
        },
      ).timeout(Duration(seconds: 10));
      
      print('  Status: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        print('  Response: ${response.body}');
        
        // Check for the specific error
        if (response.body.contains('Invalid input segments length')) {
          print('  ❌ Found the exact error!');
          print('  Issue: Token format is causing JWT parsing failure');
        }
      }
    } catch (e) {
      print('  ❌ Request failed: $e');
    }
    print('');
  }
}

/// Analyze token format
String _analyzeTokenFormat(String token) {
  if (token.contains('.')) {
    final parts = token.split('.');
    if (parts.length == 3) {
      return 'JWT (3 segments)';
    } else {
      return 'Malformed JWT (${parts.length} segments)';
    }
  } else if (RegExp(r'^[a-fA-F0-9]+$').hasMatch(token)) {
    return 'Hexadecimal';
  } else if (RegExp(r'^[a-zA-Z0-9+/=]+$').hasMatch(token)) {
    return 'Base64-like';
  } else {
    return 'Unknown format';
  }
}

/// Decode base64url (JWT format)
String _decodeBase64Url(String input) {
  String padded = input;
  while (padded.length % 4 != 0) {
    padded += '=';
  }
  
  // Replace URL-safe characters
  padded = padded.replaceAll('-', '+').replaceAll('_', '/');
  
  final decoded = base64.decode(padded);
  return utf8.decode(decoded);
}