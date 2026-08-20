import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String locale) =>
    jsonDecode(File('assets/translations/$locale.json').readAsStringSync())
        as Map<String, dynamic>;

void main() {
  final en = _load('en-US');
  final ko = _load('ko-KR');

  test('두 언어의 키가 같다', () {
    // 한쪽에만 있는 키는 그 언어에서 원문이 그대로 노출된다.
    expect(ko.keys.toSet().difference(en.keys.toSet()), isEmpty);
    expect(en.keys.toSet().difference(ko.keys.toSet()), isEmpty);
  });

  test('빈 값이 없다', () {
    for (final map in <Map<String, dynamic>>[en, ko]) {
      for (final e in map.entries) {
        expect(e.value, isA<String>(), reason: e.key);
        expect((e.value as String).trim(), isNotEmpty, reason: e.key);
      }
    }
  });

  test('v1 의 죽은 키가 남아 있지 않다', () {
    // 명세가 지목한 것들. 홈이 지도 템플릿에서 물려받은 문구와, 언어를 바꿀
    // 때 앱을 재시작하던 시절의 안내다.
    for (final dead in <String>[
      'where_to',
      'choose_bookmark',
      'set_destination_on_map',
      'around_you',
      'reserve',
      'restart_required',
      'restart_confirm_message',
    ]) {
      expect(en.containsKey(dead), isFalse, reason: dead);
      expect(ko.containsKey(dead), isFalse, reason: dead);
    }
  });

  test('줄바꿈 위치가 두 언어에서 같다', () {
    // 온보딩과 로그인 제목은 하드 브레이크가 디자인의 일부다.
    for (final key in <String>['onb1', 'onb2', 'onb3', 'welcome']) {
      expect(
        '\n'.allMatches(en[key] as String).length,
        '\n'.allMatches(ko[key] as String).length,
        reason: key,
      );
      expect((en[key] as String).contains('\n'), isTrue, reason: key);
    }
  });

  test('한국어가 음역이 아니다', () {
    // 명세가 짚은 예시들. 그대로 옮기지 않고 뜻으로 옮겼는지 본다.
    expect(ko['verdict'], '지금의 결론');
    expect(ko['movers'], '이번 주 변동');
    expect(ko['tabYou'], '내 정보');
  });

  test('K 가 쓰는 키가 전부 번역 파일에 있다', () {
    // 키를 오타내면 easy_localization 은 키 문자열을 그대로 화면에 찍는다.
    // 컴파일로는 안 잡힌다.
    for (final key in _keysInCode()) {
      expect(en.containsKey(key), isTrue, reason: '번역 파일에 없는 키: $key');
    }
  });

  test('번역 파일에 안 쓰는 키가 없다', () {
    final unused = en.keys.toSet()
      ..removeAll(_keysInCode())
      ..removeAll(_pending.keys);
    expect(
      unused,
      isEmpty,
      reason: '어디서도 안 쓰는 키. 화면에 붙이거나 _pending 에 이유와 함께 적는다.',
    );
  });

  test('붙일 자리를 못 정한 키가 아직 번역 파일에 있다', () {
    // 지우면 나중에 그 화면을 만들 때 확정 카피를 다시 찾아야 한다.
    for (final key in _pending.keys) {
      expect(en.containsKey(key), isTrue, reason: key);
      expect(ko.containsKey(key), isTrue, reason: key);
    }
  });
}

/// 아직 화면에 안 붙은 확정 카피와 그 이유.
///
/// 명세의 `T` 객체에서 그대로 가져온 문자열이라 값 자체는 확정이다. 어느
/// 요소에 붙는지가 확정이 아니다 — 프로토타입(`TechPicks-Web`)이 지워져서
/// 바인딩을 확인할 수 없다. 임의로 정하지 않고 여기 적어둔다.
const Map<String, String> _pending = <String, String>{
  'laptopTitle': 'Laptops 화면(명세 §6)이 아직 없다',
  'currency': '통화 줄을 뺐다. 값이 USD 하나뿐이라 고를 것이 없다 — 여러 통화로 들어오면 되살린다',
  'rankBy': '정렬 축 줄의 눈썹이었다. 칩 라벨이 이미 정렬이라고 말해서 뺐다',
  'seeAll': '명세가 이 버튼을 어느 섹션 헤더에 두는지 안 적었다. Shortlist 는 Add 를 쓴다',
  'swap': '비교 화면 슬롯은 캡션 tapToChange 를 쓴다. Change 가 별도 버튼인지 불명',
  'viewerTitle': '뷰어 헤더는 기기 이름을 쓴다. 어느 기기인지가 3D 뷰어라는 사실보다 쓸모 있다',
  'askPlaceholder': '입력창 힌트는 askHint 를 쓴다. 둘 다 T 에 있고 어느 쪽이 입력창인지 불명',
  'indexNote': 'TP Index 설명. 명세의 어느 화면 절에도 안 나온다',
  'version': '설정의 버전 줄은 명세 §13 의 확정 문구를 통째로 쓴다',
  'welcomeSub': '로그인 부제. welcomeSubShort 도 T 에 있고 지금은 그쪽을 쓴다',
};

/// 코드가 실제로 쓰는 번역 키.
///
/// 키는 전부 [K] 를 거친다. 손으로 목록을 복사해두면 새 키를 넣을 때마다
/// 같이 고쳐야 하고, 안 고쳐도 테스트가 통과한다. 그래서 파일을 읽는다.
Set<String> _keysInCode() {
  final src = File('lib/shared/copy_keys.dart').readAsStringSync();
  return RegExp(
    r"'([A-Za-z][A-Za-z0-9_]*)'",
  ).allMatches(src).map((m) => m.group(1)!).toSet();
}
