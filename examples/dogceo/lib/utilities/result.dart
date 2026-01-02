sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok;
  bool get isError => this is Error;

  const factory Result.ok(T data) = Ok;
  const factory Result.error(Exception error, {StackTrace? stackTrace}) = Error;
}

final class Ok<T> extends Result<T> {
  const Ok(this.data);

  final T data;

  @override
  int get hashCode => data.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return (other is Ok<T>) && other.data == data;
  }

  @override
  String toString() => "Result<$T>.ok(data: $data)";
}

final class Error extends Result<Never> {
  const Error(this.error, {this.stackTrace});

  final Exception error;
  final StackTrace? stackTrace;

  @override
  int get hashCode => error.hashCode ^ stackTrace.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return (other is Error) &&
        other.error == error &&
        other.stackTrace == stackTrace;
  }

  @override
  String toString() =>
      "Result<Never>.error(error: $error)"
      "StackTrace: $stackTrace";
}
