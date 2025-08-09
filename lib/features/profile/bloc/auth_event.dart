import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCredentials extends AuthEvent {
  final Map<String, String> credentials;
  const SubmitCredentials(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class TestCredentials extends AuthEvent {
  final Map<String, String> credentials;
  const TestCredentials(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class LoadCredentials extends AuthEvent {}

class ClearCredentials extends AuthEvent {} 