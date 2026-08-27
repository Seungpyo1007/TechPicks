import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/domain/model/tp_profile.dart';

/// 프로필은 v1 이 쓰던 Firestore 문서를 그대로 읽는다.
///
/// 열쇠 이름을 바꾸면 예전 사용자의 값이 안 보인다 — 그 사람 입장에서는
/// 프로필이 지워진 것과 구분이 안 된다.
void main() {
  test('v1 이 쓰던 열쇠 이름을 그대로 읽는다', () {
    final profile = TpProfile.fromMap(<String, Object?>{
      'username': 'seungpyo',
      'pronouns': 'they/them',
      'phone_number': '010-0000-0000',
      'gender': '남',
      'photo_url': 'https://example.test/p.jpg',
    });

    expect(profile.username, 'seungpyo');
    expect(profile.pronouns, 'they/them');
    expect(profile.phone, '010-0000-0000');
    expect(profile.gender, '남');
    expect(profile.photoUrl, 'https://example.test/p.jpg');
  });

  test('빈 칸과 공백은 없는 것으로 읽는다', () {
    final profile = TpProfile.fromMap(<String, Object?>{
      'username': '   ',
      'pronouns': '',
      'gender': 42,
    });

    expect(profile.username, isNull);
    expect(profile.pronouns, isNull);
    expect(profile.gender, isNull);
    expect(profile.isEmpty, isTrue);
  });

  test('비운 칸은 지우는 것이다', () {
    // null 을 안 적어 보내면 예전 값이 문서에 남는다. merge 로 쓰기 때문에
    // 화면에서 지운 것이 다시 나타난다.
    const profile = TpProfile(username: 'seungpyo');
    final map = profile.toMap();

    expect(map['username'], 'seungpyo');
    expect(map.containsKey('pronouns'), isTrue);
    expect(map['pronouns'], isNull);
  });

  test('사진만 바꿔도 나머지가 남는다', () {
    const profile = TpProfile(username: 'seungpyo', gender: '남');
    final next = profile.copyWith(photoUrl: 'https://example.test/p.jpg');

    expect(next.username, 'seungpyo');
    expect(next.gender, '남');
    expect(next.photoUrl, 'https://example.test/p.jpg');
  });
}
