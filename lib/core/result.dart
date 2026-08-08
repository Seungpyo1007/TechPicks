import 'failure.dart';

/// 성공 또는 [Failure] 중 하나.
///
/// 리포지토리는 예외를 던지지 않고 이 타입을 돌려준다. 호출부가 실패 처리를
/// 잊는 것을 컴파일 단계에서 막기 위해서다.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Failure failure) = Err<T>;

  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// 성공이면 값, 실패면 null.
  T? get valueOrNull => switch (this) {
    Ok<T>(:final value) => value,
    Err<T>() => null,
  };

  /// 실패면 [Failure], 성공이면 null.
  Failure? get failureOrNull => switch (this) {
    Ok<T>() => null,
    Err<T>(:final failure) => failure,
  };

  /// 성공 값을 변환한다. 실패는 그대로 통과시킨다.
  Result<R> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T>(:final value) => Ok<R>(transform(value)),
    Err<T>(:final failure) => Err<R>(failure),
  };

  /// 두 갈래를 모두 처리해 하나의 값으로 접는다.
  R fold<R>(R Function(T value) onOk, R Function(Failure failure) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final failure) => onErr(failure),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;

  @override
  String toString() => 'Ok($value)';
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;

  @override
  String toString() => 'Err($failure)';
}
