import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/locale_controller.dart';
import 'package:techpicks/data/service/auth_service.dart';

/// Firebase 가 없는 빌드.
///
/// main.dart 가 초기화 실패를 삼키고 "로그인만 안 되고 나머지는 다 된다"고
/// 적어뒀다. 그러려면 인증 쪽이 어디서도 던지면 안 된다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = FirebaseAuthService();

  test('현재 사용자를 물어도 안 터진다', () {
    expect(service.current, isNull);
  });

  for (final method in AuthMethod.values) {
    test('$method 로그인은 null 로 떨어진다', () async {
      expect(await service.signIn(method, email: 'a@b.com', password: '123456'),
          isNull);
    });
  }

  test('가입도 null 로 떨어진다', () async {
    expect(
      await service.signUp(email: 'a@b.com', password: '123456'),
      isNull,
    );
  });

  test('로그아웃은 조용히 지나간다', () async {
    await service.signOut();
  });

  group('언어', () {
    test('지원하는 언어를 찾는다', () {
      expect(TpLocale.of(const Locale('ko', 'KR')), TpLocale.ko);
      expect(TpLocale.of(const Locale('en', 'US')), TpLocale.en);
      // 나라가 달라도 언어로 찾는다.
      expect(TpLocale.of(const Locale('ko')), TpLocale.ko);
    });

    test('모르는 언어는 영어로 떨어진다', () {
      expect(TpLocale.of(const Locale('fr', 'FR')), TpLocale.en);
    });

    test('목록 이름은 각 언어로 적는다', () {
      expect(TpLocale.en.label, 'English');
      expect(TpLocale.ko.label, '한국어');
    });
  });
}
