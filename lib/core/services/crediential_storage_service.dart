import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CredentialStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveCredentials(Map<String, String> creds) async {
    for (var key in creds.keys) {
      await _storage.write(key: key, value: creds[key]);
    }
  }
Future<Map<String, String?>> getCredentials() async {
  return {
    'wooKey': await _storage.read(key: 'wooKey'),
    'wooSecret': await _storage.read(key: 'wooSecret'),
    'wooUrl': await _storage.read(key: 'wooUrl'),
    'wpUser': await _storage.read(key: 'wpUser'),
    'wpPass': await _storage.read(key: 'wpPass'),
    'gorgiasToken': await _storage.read(key: 'gorgiasToken'),
    'gorgiasSub': await _storage.read(key: 'gorgiasSub'),
    'gorgiasUserName': await _storage.read(key: 'gorgiasUserName'),
    'wordPressUserName': await _storage.read(key: 'wordPressUserName'),
    // ReachShip credentials
    'reachShipClientId': await _storage.read(key: 'reachShipClientId'),
    'reachShipClientSecret': await _storage.read(key: 'reachShipClientSecret'),
    'reachShipEnv': await _storage.read(key: 'reachShipEnv'),
    // ReachShip production credentials
    'reachShipProClientId': await _storage.read(key: 'reachShipProClientId'),
    'reachShipProSecret': await _storage.read(key: 'reachShipProSecret'),
  };
}
  Future<Map<String, String?>> getCredential() async {
    return {
      'wooKey': await _storage.read(key: 'wooKey'),
      'wooSecret': await _storage.read(key: 'wooSecret'),
      'wooUrl': await _storage.read(key: 'wooUrl'),
      'wpUser': await _storage.read(key: 'wpUser'),
      'wpPass': await _storage.read(key: 'wpPass'),
      'gorgiasToken': await _storage.read(key: 'gorgiasToken'),
      'gorgiasSub': await _storage.read(key: 'gorgiasSub'),
      'gorgiasUserName': await _storage.read(key: 'gorgiasUserName'),
      'wordPressUserName': await _storage.read(key: 'wordPressUserName'),
    };
  }

  Future<void> clearAll() async => _storage.deleteAll();
}
