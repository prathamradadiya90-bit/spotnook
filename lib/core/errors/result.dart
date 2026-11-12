import 'failure.dart';

/// Typed result container representing either a [Success] with data of type [T],
/// or a [FailureResult] with an error of type [E] (defaults to [Failure]).
sealed class Result<T, E> {
  const Result();

  factory Result.ok(T data) = Success<T, E>;
  factory Result.err(E error) = FailureResult<T, E>;

  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is FailureResult<T, E>;

  T? get dataOrNull => isSuccess ? (this as Success<T, E>).data : null;
  E? get errorOrNull => isFailure ? (this as FailureResult<T, E>).error : null;

  /// Pattern-matching transformation over success and failure outcomes.
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(E error) onFailure,
  }) {
    if (this is Success<T, E>) {
      return onSuccess((this as Success<T, E>).data);
    } else {
      return onFailure((this as FailureResult<T, E>).error);
    }
  }
}

/// Successful outcome container.
class Success<T, E> extends Result<T, E> {
  final T data;
  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T, E> && other.data == data);

  @override
  int get hashCode => data.hashCode;
}

/// Failure outcome container.
class FailureResult<T, E> extends Result<T, E> {
  final E error;
  const FailureResult(this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is FailureResult<T, E> && other.error == error);

  @override
  int get hashCode => error.hashCode;
}

