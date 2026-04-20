import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:woo_management_app/core/services/crediential_storage_service.dart';
import 'package:http/http.dart' as http;

/// Debug script to check the actual stored Gorgias credentials
/// and test authentication with real data
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== REAL GORGIAS CREDENTIALS DEBUG ===');
  
  try {
    final credentialStorage = CredentialStorageService();
    final credentials = await credentialStorage.getCredentials();
    
    print('\nStored Credentials:');
    print('  Username: ${credentials['gorgiasUserName'] ?? 'NOT SET'}');
    print('  Token: ${credentials['gorgiasToken']?.substring(0, 10) ?? 'NOT SET'}...');
    print('  Subdomain: ${credentials['gorgiasSub'] ?? 'NOT SET'}');
    
    final username = credentials['gorgiasUserName'];
    final token = credentials['gorgiasToken'];
    final subdomain = credentials['gorgiasSub'];
    
    if (username == null || token == null || subdomain == null) {
      print('\n❌ MISSING CREDENTIALS');
      print('Please ensure all Gorgias credentials are properly stored.');
      return;
    }
    
    // Test authentication with real credentials
    print('\n=== TESTING REAL AUTHENTICATION ===');
    
    final credentialsEncoded = base64Encode(utf8.encode('$username:$token'));
    print('Basic Auth Header: Basic $credentialsEncoded');
    
    final url = 'https://$subdomain.gorgias.com/api/account';
    print('Testing URL: $url');
    
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Basic $credentialsEncoded',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    
    print('\nResponse Status: ${response.statusCode}');
    print('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      print('\n✅ AUTHENTICATION SUCCESSFUL!');
      print('The Basic Auth fix is working with real credentials.');
    } else if (response.statusCode == 401) {
      print('\n❌ AUTHENTICATION FAILED');
      print('Possible issues:');
      print('  1. Invalid username or API key');
      print('  2. API key expired or revoked');
      print('  3. Incorrect subdomain');
      print('  4. Account permissions issue');
      
      // Try to decode the response for more details
      try {
        final errorData = json.decode(response.body);
        print('  Error details: $errorData');
      } catch (e) {
        print('  Raw error: ${response.body}');
      }
    } else {
      print('\n⚠️  UNEXPECTED RESPONSE: ${response.statusCode}');
      print('Response: ${response.body}');
    }
    
    // Additional credential validation
    print('\n=== CREDENTIAL VALIDATION ===');
    print('Username format: ${_validateUsername(username)}');
    print('Token format: ${_validateToken(token)}');
    print('Subdomain format: ${_validateSubdomain(subdomain)}');
    
  } catch (e) {
    print('\n❌ ERROR: $e');
    if (e.toString().contains('MissingPluginException')) {
      print('\n⚠️  Plugin not available in debug environment.');
      print('This script needs to be run within the Flutter app context.');
      print('Try running: flutter run and then use the debug options in the app.');
    }
  }
}

String _validateUsername(String username) {
  if (username.isEmpty) return '❌ Empty username';
  if (username.contains('@')) return '✅ Email format';
  if (username.length < 3) return '⚠️  Very short username';
  return '✅ Valid format';
}

String _validateToken(String token) {
  if (token.isEmpty) return '❌ Empty token';
  if (token.length == 64) return '✅ 64-char API key (expected)';
  if (token.contains('.')) return '⚠️  JWT format (unexpected for Gorgias API key)';
  return '⚠️  Unusual length: ${token.length} characters';
}

String _validateSubdomain(String subdomain) {
  if (subdomain.isEmpty) return '❌ Empty subdomain';
  if (RegExp(r'^[a-zA-Z0-9-]+$').hasMatch(subdomain)) return '✅ Valid subdomain format';
  return '⚠️  Invalid characters in subdomain';
}