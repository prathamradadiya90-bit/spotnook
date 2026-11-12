/// Domain failure representations for typed error handling.
sealed class Failure {
  final String message;
  final int? statusCode;

  const Failure(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = "Couldn't load places. Check your connection and retry",
    super.statusCode,
  ]);
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Server encountered an error. Please try again later.',
    super.statusCode,
  ]);
}

class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Rate limit reached. Please wait a moment before searching again.',
    super.statusCode,
  ]);
}

class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Cached data is unavailable or expired.',
    super.statusCode,
  ]);
}

class SecurityFailure extends Failure {
  const SecurityFailure([
    super.message = 'Insecure protocol or unauthorized operation.',
    super.statusCode,
  ]);
}

