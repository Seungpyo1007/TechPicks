import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/service/auth_service.dart';

/// Apple 로그인 nonce.
///
/// 원문은 Firebase 에, 해시는 Apple 에 간다. 둘이 안 맞으면 로그인 자체가
/// 거절되므로 형태가 정확해야 한다.
void main() {
  test('32자이고 URL 에 실을 수 있는 문자만 쓴다', () {
    final nonce = AppleNonce.create();

    expect(nonce, hasLength(AppleNonce.length));
    expect(nonce, matches(RegExp(r'^[A-Za-z0-9\-._]+$')));
  });

  test('부를 때마다 다르다', () {
    // 같은 값이 두 번 나오면 재사용 방지가 통째로 무의미해진다.
    final seen = <String>{for (var i = 0; i < 200; i++) AppleNonce.create()};

    expect(seen, hasLength(200));
  });

  test('해시는 SHA-256 16진 문자열이다', () {
    // 알려진 값. Apple 에는 이 형태로만 보낸다.
    expect(
      AppleNonce.hash('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    expect(AppleNonce.hash(AppleNonce.create()), hasLength(64));
  });
}
