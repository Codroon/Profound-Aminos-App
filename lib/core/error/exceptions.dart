// Network Exceptions
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({required this.message, this.statusCode});
}

class NetworkException implements Exception {
  final String message;

  NetworkException({required this.message});
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException({required this.message});
}

// Authentication Exceptions
class AuthenticationException implements Exception {
  final String message;

  AuthenticationException({required this.message});
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException({required this.message});
}

// Cache Exceptions
class CacheException implements Exception {
  final String message;

  CacheException({required this.message});
}

// Validation Exceptions
class ValidationException implements Exception {
  final String message;
  final Map<String, List<String>>? errors;

  ValidationException({required this.message, this.errors});
}

// Game Exceptions
class GameException implements Exception {
  final String message;

  GameException({required this.message});
}

// Wallet Exceptions
class InsufficientFundsException implements Exception {
  final String message;

  InsufficientFundsException({required this.message});
}

class PaymentException implements Exception {
  final String message;

  PaymentException({required this.message});
}

// WebSocket Exceptions
class WebSocketException implements Exception {
  final String message;

  WebSocketException({required this.message});
}

// General Exceptions
class UnexpectedException implements Exception {
  final String message;

  UnexpectedException({required this.message});
}
