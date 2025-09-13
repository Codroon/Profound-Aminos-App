import 'dart:io';
import 'dart:ui';
import 'lib/core/services/reach_ship_service.dart';
import 'lib/core/services/crediential_storage_service.dart';

void main() async {
  print('Testing ReachShip Authentication...');

  try {
    // Create credential storage service
    final credentialService = CredentialStorageService();

    // Set test credentials
    final testCreds = {
      'reachShipClientId': 'w2iuTRwQyoE9TPZLW1GU7FijeApM6VShDk',
      'reachShipClientSecret': 'iZbXqR9NTQIkti5OEij9MAg3Spa9labJ',
      'reachShipEnv': 'sandbox',
    };

    await credentialService.saveCredentials(testCreds);
    print('✓ Test credentials saved');

    // Create ReachShip service
    final service = await ReachShipService.withCredentials(credentialService);
    print('✓ ReachShip service created');

    // Test getting rates
    final testRateRequest = {
      'shipTo': {
        'name': 'Test Recipient',
        'address_line_1': 'Test Address',
        'city': 'Multan',
        'state': 'Punjab',
        'postal_code': '60000',
        'country': 'PK',
      },
      'shipFrom': {
        'name': 'Test Sender',
        'address_line_1': 'Test Address',
        'city': 'Islamabad',
        'state': 'Islamabad Capital Territory',
        'postal_code': '44000',
        'country': 'PK',
      },
      'packages': [
        {
          'weight': 1.0,
          'length': 10.0,
          'width': 10.0,
          'height': 10.0,
          'weight_unit': 'kg',
          'dimension_unit': 'cm',
        },
      ],
    };

    final response = await service.getRates(
      shipTo: testRateRequest['shipTo'] as Map<String, dynamic>,
      shipFrom: testRateRequest['shipFrom'] as Map<String, dynamic>,
      packages: testRateRequest['packages'] as List<Map<String, dynamic>>,
    );

    print('✓ Rate request successful!');
    print('Response: $response');
  } catch (e) {
    print('✗ Error: $e');
    exit(1);
  }

  print('\n✓ All tests passed!');
}
