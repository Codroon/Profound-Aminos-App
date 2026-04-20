import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/services/api_credential_service.dart';
import '../../../../core/services/crediential_storage_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final CredentialStorageService _storageService;

  AuthBloc({CredentialStorageService? storageService})
      : _storageService = storageService ?? CredentialStorageService(),
        super(AuthInitial()) {
    on<SubmitCredentials>(_onSubmitCredentials);
    on<TestCredentials>(_onTestCredentials);
    on<LoadCredentials>(_onLoadCredentials);
    on<ClearCredentials>(_onClearCredentials);
  }

  Future<void> _onSubmitCredentials(
    SubmitCredentials event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _storageService.saveCredentials(event.credentials);
      print('[AuthBloc] Credentials saved successfully.');
      emit(AuthSuccess());
    } catch (e) {
      print('[AuthBloc] Failed to save credentials: ${e.toString()}');
      emit(AuthFailure('Failed to save credentials.'));
    }
  }

  Future<void> _onTestCredentials(
    TestCredentials event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final tester = ApiService(event.credentials);
      final wooOK = await tester.testWooCommerce();
      final wpOK = await tester.testWordPress();
      final gorgiasOK = await tester.testGorgias();
      print('[AuthBloc] WooCommerce OK: $wooOK, WordPress OK: $wpOK, Gorgias OK: $gorgiasOK');
      if (wooOK) {
        emit(AuthSuccess());
      } else {
        String failMsg = 'WooCommerce credentials are required and failed.\n';
        if (!wooOK) failMsg += 'WooCommerce failed.';
        print('[AuthBloc] $failMsg');
        emit(AuthFailure(failMsg));
      }
    } catch (e) {
      print('[AuthBloc] Error testing credentials: ${e.toString()}');
      emit(AuthFailure('Error testing credentials.'));
    }
  }

  Future<void> _onLoadCredentials(
    LoadCredentials event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final creds = await _storageService.getCredentials();
      print('[AuthBloc] Credentials loaded: ${creds.toString()}');
      emit(CredentialsLoaded(creds));
    } catch (e) {
      print('[AuthBloc] Failed to load credentials: ${e.toString()}');
      emit(AuthFailure('Failed to load credentials.'));
    }
  }

  Future<void> _onClearCredentials(
    ClearCredentials event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _storageService.clearAll();
      print('[AuthBloc] Credentials cleared.');
      emit(AuthSuccess());
    } catch (e) {
      print('[AuthBloc] Failed to clear credentials: ${e.toString()}');
      emit(AuthFailure('Failed to clear credentials.'));
    }
  }
} 