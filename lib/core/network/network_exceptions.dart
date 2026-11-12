/// Structured Network & API Exceptions
sealed class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection. Please check your network.', super.statusCode]);
}

class TimeoutException extends AppException {
  const TimeoutException([super.message = 'Request timed out. Please try again.', super.statusCode]);
}

class ServerException extends AppException {
  const ServerException([super.message = 'Server encountered an error. Please try again later.', super.statusCode]);
}

class RateLimitException extends AppException {
  const RateLimitException([super.message = 'Rate limit reached. Please wait a moment before searching again.', super.statusCode]);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException([super.message = 'Invalid or missing API credentials.', super.statusCode]);
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'No places found matching your criteria.', super.statusCode]);
}

class ParsingException extends AppException {
  const ParsingException([super.message = 'Failed to parse place details.', super.statusCode]);
}

class SecurityException extends AppException {
  const SecurityException([super.message = 'Security violation detected.', super.statusCode]);
}

