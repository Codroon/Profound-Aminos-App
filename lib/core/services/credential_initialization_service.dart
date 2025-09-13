import '../services/api_credential_service.dart';
import '../services/crediential_storage_service.dart';
import '../di/injection_container.dart' as di;

class CredentialInitializationService {
  static final CredentialInitializationService _instance = CredentialInitializationService._internal();
  factory CredentialInitializationService() => _instance;
  CredentialInitializationService._internal();

  bool _isInitialized = false;
  ApiService? _apiService;

  bool get isInitialized => _isInitialized;
  ApiService? get apiService => _apiService;

  /// Initialize credentials and create a new ApiService instance
  Future<void> initializeCredentials() async {
    if (_isInitialized) return;

    try {
      final credentialStorage = CredentialStorageService();
      final credentials = await credentialStorage.getCredentials();
      
      // Convert nullable values to non-nullable with empty string fallback
      final cleanCredentials = <String, String>{};
      credentials.forEach((key, value) {
        cleanCredentials[key] = value ?? '';
      });
      
      // Create new ApiService with loaded credentials
      _apiService = ApiService(cleanCredentials);
      
      // Update the service locator with the new instance
      if (di.sl.isRegistered<ApiService>()) {
        di.sl.unregister<ApiService>();
      }
      di.sl.registerLazySingleton<ApiService>(() => _apiService!);
      
      _isInitialized = true;
      print('[CredentialInit] Credentials loaded and ApiService updated');
    } catch (e) {
      print('[CredentialInit] Failed to initialize credentials: $e');
      rethrow;
    }
  }

  /// Reset the initialization state (useful for logout)
  void reset() {
    _isInitialized = false;
    _apiService = null;
  }

  /// Refresh Gorgias credentials specifically
  static Future<void> refreshGorgiasCredentials() async {
    try {
      final credentialStorage = CredentialStorageService();
      final credentials = await credentialStorage.getCredentials();
      
      // Get the current ApiService instance
      final apiService = di.sl<ApiService>();
      
      // Update Gorgias credentials in the ApiService
      if (credentials['gorgiasToken'] != null) {
        apiService.creds['gorgiasToken'] = credentials['gorgiasToken']!;
      }
      if (credentials['gorgiasSub'] != null) {
        apiService.creds['gorgiasSub'] = credentials['gorgiasSub']!;
      }
      if (credentials['gorgiasUserName'] != null) {
        apiService.creds['gorgiasUserName'] = credentials['gorgiasUserName']!;
      }
      
      print('[CredentialInit] Gorgias credentials refreshed');
    } catch (e) {
      print('[CredentialInit] Failed to refresh Gorgias credentials: $e');
      rethrow;
    }
  }
}