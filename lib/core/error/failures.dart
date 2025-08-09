import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object> get props => [message];
}

// Network Failures
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure({required super.message, this.statusCode});

  @override
  List<Object> get props => [message, statusCode ?? 0];
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message});
}

class TimeoutFailure extends Failure {
  const TimeoutFailure({required super.message});
}

// Authentication Failures
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({required super.message});
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({required super.message});
}

// Cache Failures
class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

// Validation Failures
class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({required super.message, this.errors});

  @override
  List<Object> get props => [message, errors ?? {}];
}

// Game Failures
class GameFailure extends Failure {
  const GameFailure({required super.message});
}

// Wallet Failures
class InsufficientFundsFailure extends Failure {
  const InsufficientFundsFailure({required super.message});
}

class PaymentFailure extends Failure {
  const PaymentFailure({required super.message});
}

// WebSocket Failures
class WebSocketFailure extends Failure {
  const WebSocketFailure({required super.message});
}

// General Failures
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({required super.message});
}
