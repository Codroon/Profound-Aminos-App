import 'dart:io';
import 'package:dio/dio.dart';
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  // Convert exceptions to failures
  static Failure handleError(dynamic error) {
    if (error is ServerException) {
      return ServerFailure(
        message: error.message,
        statusCode: error.statusCode,
      );
    } else if (error is NetworkException) {
      return NetworkFailure(message: error.message);
    } else if (error is TimeoutException) {
      return TimeoutFailure(message: error.message);
    } else if (error is AuthenticationException) {
      return AuthenticationFailure(message: error.message);
    } else if (error is UnauthorizedException) {
      return UnauthorizedFailure(message: error.message);
    } else if (error is CacheException) {
      return CacheFailure(message: error.message);
    } else if (error is ValidationException) {
      return ValidationFailure(message: error.message, errors: error.errors);
    } else if (error is GameException) {
      return GameFailure(message: error.message);
    } else if (error is InsufficientFundsException) {
      return InsufficientFundsFailure(message: error.message);
    } else if (error is PaymentException) {
      return PaymentFailure(message: error.message);
    } else if (error is WebSocketException) {
      return WebSocketFailure(message: error.message);
    } else {
      return UnexpectedFailure(message: 'An unexpected error occurred');
    }
  }

  // Handle Dio errors
  static Exception handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutException(message: 'Connection timed out');

      case DioExceptionType.badResponse:
        return _handleResponseError(error);

      case DioExceptionType.cancel:
        return ServerException(message: 'Request was cancelled');

      case DioExceptionType.connectionError:
        return NetworkException(message: 'No internet connection');

      default:
        return ServerException(message: 'Something went wrong');
    }
  }

  // Handle HTTP response errors
  static Exception _handleResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    String message = 'Something went wrong';

    if (responseData != null && responseData is Map<String, dynamic>) {
      message = responseData['message'] ?? message;
    }

    switch (statusCode) {
      case 400:
        if (responseData != null &&
            responseData is Map<String, dynamic> &&
            responseData.containsKey('errors')) {
          final errors = responseData['errors'] as Map<String, dynamic>;
          final formattedErrors = <String, List<String>>{};

          errors.forEach((key, value) {
            if (value is List) {
              formattedErrors[key] = value.map((e) => e.toString()).toList();
            } else if (value is String) {
              formattedErrors[key] = [value];
            }
          });

          return ValidationException(message: message, errors: formattedErrors);
        }
        return ValidationException(message: message);

      case 401:
        return UnauthorizedException(message: 'Unauthorized access');

      case 403:
        return AuthenticationException(message: 'Access forbidden');

      case 404:
        return ServerException(
          message: 'Resource not found',
          statusCode: statusCode,
        );

      case 422:
        return ValidationException(message: 'Validation failed');

      case 500:
      case 501:
      case 502:
      case 503:
        return ServerException(message: 'Server error', statusCode: statusCode);

      default:
        return ServerException(message: message, statusCode: statusCode);
    }
  }

  // Handle socket exceptions
  static Exception handleSocketException(SocketException exception) {
    return NetworkException(message: 'No internet connection');
  }

  // Get user-friendly error message
  static String getUserFriendlyErrorMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Please check your internet connection and try again';
    } else if (failure is TimeoutFailure) {
      return 'The server is taking too long to respond, please try again later';
    } else if (failure is AuthenticationFailure ||
        failure is UnauthorizedFailure) {
      return 'Please log in again to continue';
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else if (failure is InsufficientFundsFailure) {
      return 'Insufficient funds. Please add money to your wallet';
    } else if (failure is GameFailure) {
      return failure.message;
    } else {
      return 'Something went wrong. Please try again later';
    }
  }
}
