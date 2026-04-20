import 'dart:convert';

/// Simple token format checker that doesn't depend on Flutter
/// This will help us understand the token format issue
void main() async {
  print('=== GORGIAS TOKEN FORMAT ANALYSIS ===\n');
  
  // Based on the error logs, we know:
  // 1. Token length: 64 characters
  // 2. Error: "Invalid input segments length"
  // 3. Subdomain: profoundaminos
  
  print('From the error logs we know:');
  print('  Token length: 64 characters');
  print('  Error: "Invalid input segments length"');
  print('  Subdomain: profoundaminos');
  print('');
  
  // Analyze what this error means
  print('ANALYSIS:');
  print('"Invalid input segments length" typically means:');
  print('  1. Gorgias expects a JWT token (3 segments: header.payload.signature)');
  print('  2. The current token is NOT in JWT format');
  print('  3. A 64-character token suggests it\'s an API key, not a JWT');
  print('');
  
  // Test different token formats
  await testTokenFormats();
  
  // Provide solution
  print('SOLUTION:');
  print('The issue is that the stored token is likely an API key format,');
  print('but Gorgias API expects a JWT (JSON Web Token) format.');
  print('');
  print('To fix this:');
  print('1. Check how the token is obtained from Firestore');
  print('2. Verify the token format in Firestore');
  print('3. If it\'s an API key, convert it to JWT format');
  print('4. Or obtain a proper JWT token from Gorgias OAuth flow');
}

Future<void> testTokenFormats() async {
  print('TOKEN FORMAT EXAMPLES:');
  
  // Example of what we likely have (64-char API key)
  final apiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5z6a7b8c9d0e1f2';
  print('Current token format (likely):');
  print('  Type: API Key');
  print('  Length: ${apiKey.length}');
  print('  Segments: ${apiKey.split('.').length}');
  print('  Example: ${apiKey.substring(0, 20)}...');
  print('  ❌ This causes "Invalid input segments length" error');
  print('');
  
  // Example of what Gorgias expects (JWT)
  final jwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
  print('Expected token format:');
  print('  Type: JWT (JSON Web Token)');
  print('  Length: ${jwtToken.length}');
  print('  Segments: ${jwtToken.split('.').length}');
  print('  Example: ${jwtToken.substring(0, 50)}...');
  print('  ✅ This would work with Gorgias API');
  print('');
  
  // Decode the JWT example to show structure
  try {
    final parts = jwtToken.split('.');
    final header = _decodeBase64Url(parts[0]);
    final payload = _decodeBase64Url(parts[1]);
    
    print('JWT Structure:');
    print('  Header: $header');
    print('  Payload: $payload');
    print('  Signature: [binary data]');
  } catch (e) {
    print('  Could not decode JWT example: $e');
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