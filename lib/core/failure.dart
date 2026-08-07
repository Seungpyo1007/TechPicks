/// 데이터 계층에서 발생할 수 있는 실패의 분류.
///
/// UI가 "무엇이 잘못됐는지"에 따라 다르게 반응할 수 있도록 원인을 나눈다.
/// 네트워크 문제는 재시도 버튼을, 없는 레코드는 빈 상태를 보여야 한다.
sealed class Failure implements Exception {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

/// 연결 실패·타임아웃 등 요청이 서버에 닿지 못한 경우.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause});
}

/// 해당 slug의 레코드가 없다 (HTTP 404).
///
/// TechAPI 데이터셋은 큐레이션 중이라 상위 목록에 있어도 상세가 없을 수 있다.
class NotFoundFailure extends Failure {
  const NotFoundFailure(this.collection, this.slug)
      : super('$collection/$slug 레코드를 찾을 수 없다');

  final String collection;
  final String slug;
}

/// 응답은 왔지만 JSON이 기대한 형태가 아니다.
class ParseFailure extends Failure {
  const ParseFailure(super.message, {super.cause});
}

/// 위 어디에도 속하지 않는 서버 오류.
class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode, super.cause});

  final int? statusCode;
}
