// import 'package:flutter/foundation.dart';
// import '../../domain/entities/user.dart';
// import '../../domain/usecases/login_usecase.dart';
// import '../../domain/usecases/register_usecase.dart';
// import '../../../../core/error/failures.dart';
//
// class AuthProvider extends ChangeNotifier {
//   final LoginUseCase loginUseCase;
//   final RegisterUseCase registerUseCase;
//
//   AuthProvider({required this.loginUseCase, required this.registerUseCase});
//
//   User? _currentUser;
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   // Getters
//   User? get currentUser => _currentUser;
//   bool get isLoading => _isLoading;
//   String? get errorMessage => _errorMessage;
//   bool get isAuthenticated => _currentUser != null;
//
//   void _setLoading(bool loading) {
//     _isLoading = loading;
//     notifyListeners();
//   }
//
//   void _setError(String? error) {
//     _errorMessage = error;
//     notifyListeners();
//   }
//
//   Future<void> login({
//     required String username,
//     required String password,
//     bool rememberMe = false,
//   }) async {
//     _setLoading(true);
//     _setError(null);
//
//     final result = await loginUseCase.call(
//       LoginParams(
//         username: username,
//         password: password,
//         rememberMe: rememberMe,
//       ),
//     );
//
//     result.fold((failure) => _setError(_mapFailureToMessage(failure)), (user) {
//       _currentUser = user;
//       // Navigate to home page would be handled by the UI
//     });
//
//     _setLoading(false);
//   }
//
//   Future<void> register({
//     required String username,
//     required String password,
//     required String phone,
//     String? referralCode,
//   }) async {
//     _setLoading(true);
//     _setError(null);
//
//     final result = await registerUseCase.call(
//       RegisterParams(
//         username: username,
//         password: password,
//         phone: phone,
//         referralCode: referralCode,
//       ),
//     );
//
//     result.fold((failure) => _setError(_mapFailureToMessage(failure)), (user) {
//       _currentUser = user;
//       // Navigate to home page would be handled by the UI
//     });
//
//     _setLoading(false);
//   }
//
//   void logout() {
//     _currentUser = null;
//     _errorMessage = null;
//     notifyListeners();
//   }
//
//   String _mapFailureToMessage(Failure failure) {
//     switch (failure.runtimeType) {
//       case const (ServerFailure):
//         return 'Server error occurred';
//       case const (NetworkFailure):
//         return 'Network connection failed';
//       case const (AuthenticationFailure):
//         return 'Invalid credentials';
//       case const (ValidationFailure):
//         return failure.message;
//       default:
//         return 'An unexpected error occurred';
//     }
//   }
// }
