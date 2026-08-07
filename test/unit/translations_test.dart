import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/shell/tp_tab.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/shared/copy_keys.dart';

Map<String, dynamic> _load(String locale) => jsonDecode(
      File('assets/translations/$locale.json').readAsStringSync(),
    ) as Map<String, dynamic>;

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

  test('K 의 상수가 전부 번역 파일에 있다', () => _guardKeys(en));

  test('화면이 쓰는 키가 다 있다', () {
    for (final key in <String>[
      'tabHome', 'tabRank', 'tabCmp', 'tabAsk', 'tabYou',
      'homeTitle', 'homeSub', 'verdict', 'shortlist', 'movers',
      'rankBy', 'rankNote', 'axIndex', 'axBatt', 'axCam', 'axVal', 'axPrice',
      'cmpTitle', 'choose', 'cancel',
      'addShort', 'inShort', 'compareB', 'view3d',
      'priorities', 'prioritiesNote', 'language', 'darkMode', 'logout',
      'chatSeed', 'askHint',
      'skip', 'next', 'start', 'onb1', 'onb1b', 'onb2', 'onb2b', 'onb3', 'onb3b',
      'welcome', 'lGoogle', 'lEmail', 'lAnon', 'noAccount', 'signup',
      'scanTitle', 'scanHintIdle', 'scanHintDone', 'detected', 'open',
      'viewerNote', 'partDisplay', 'partBattery', 'partChip', 'partCamera',
      'dataSource',
    ]) {
      expect(en.containsKey(key), isTrue, reason: key);
    }
  });
}

/// K 의 모든 상수가 실제 번역 파일에 있는지.
///
/// 키를 오타내면 easy_localization 은 키 문자열을 그대로 화면에 찍는다.
/// 컴파일로는 안 잡히니 여기서 잡는다.
void _guardKeys(Map<String, dynamic> en) {
  final keys = <String>[
    K.tabHome, K.tabRank, K.tabCompare, K.tabAsk, K.tabYou,
    K.homeTitle, K.homeSub, K.verdict, K.tpIndex, K.shortlist, K.addDevice,
    K.compareAll, K.askWhy, K.movers, K.emptyShortlist, K.emptyShortlistBody,
    K.emptyShortlistCta,
    K.phones, K.cpus, K.laptops, K.rankBy, K.rankNote, K.scanCta, K.scanShort,
    K.noDevices,
    K.compareTitle, K.choose, K.cancel, K.chooseTwo, K.tapToChange,
    K.addShortlist, K.inShortlist, K.compareButton, K.view3d, K.dataSource,
    K.loadFailed,
    K.chatSeed, K.askHint, K.askFailed,
    K.you, K.editProfile, K.priorities, K.prioritiesNote, K.reset, K.language,
    K.darkMode, K.notifications, K.currency, K.changePassword, K.logout,
    K.version, K.on, K.off, K.noAccountYet,
    K.skip, K.next, K.start,
    K.welcome, K.welcomeSub, K.loginGoogle, K.loginApple, K.loginFacebook,
    K.loginEmail, K.loginAnon, K.noAccount, K.signup,
    K.scanTitle, K.scanHintIdle, K.scanHintDone, K.detected, K.openDevice,
    K.viewerNote, K.partDisplay, K.partBattery, K.partChip, K.partCamera,
    for (final o in K.onboarding) ...<String>[o.title, o.body],
    for (final t in TpTab.values) K.tab(t),
    for (final a in TpAxisKind.values) K.axis(a),
    for (final a in RankAxis.values) K.rankAxis(a),
    for (final s in SpecKind.values) K.spec(s),
  ];

  for (final key in keys) {
    expect(en.containsKey(key), isTrue, reason: '번역 파일에 없는 키: $key');
  }
}
