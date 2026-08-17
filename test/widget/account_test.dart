import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/data/service/profile_service.dart';
import 'package:techpicks/domain/model/tp_profile.dart';
import 'package:techpicks/feature/you/you_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 이름과 비밀번호는 Firebase 가 처리한다. 여기서는 무엇을 시켰는지만 본다.
class _StubAuth implements AuthService {
  @override
  Stream<TpUser?> changes() => const Stream<TpUser?>.empty();
  _StubAuth({this.succeeds = true, TpUser? user})
    : _current = user ?? const TpUser(uid: 'u1', email: 'a@b.com', name: '홍길동');

  final bool succeeds;
  TpUser? _current;

  final List<String> resets = <String>[];
  final List<String> names = <String>[];

  @override
  TpUser? get current => _current;

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async => _current;

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<bool> sendPasswordReset(String email) async {
    resets.add(email);
    return succeeds;
  }

  @override
  Future<TpUser?> updateName(String name) async {
    names.add(name);
    if (!succeeds) return null;
    return _current = TpUser(uid: 'u1', email: 'a@b.com', name: name);
  }

  @override
  Future<void> signOut() async => _current = null;
}

/// 프로필 문서. Firestore 없이 무엇을 저장했는지만 본다.
class _StubProfiles implements ProfileService {
  _StubProfiles({this.succeeds = true, TpProfile? stored})
    : stored = stored ?? const TpProfile();

  final bool succeeds;
  TpProfile stored;
  final List<TpProfile> saved = <TpProfile>[];
  final List<String> uploads = <String>[];

  @override
  Future<TpProfile> load(String uid) async => stored;

  @override
  Future<bool> save(String uid, TpProfile profile) async {
    saved.add(profile);
    if (succeeds) stored = profile;
    return succeeds;
  }

  @override
  Future<String?> uploadPhoto(String uid, String filePath) async {
    uploads.add(filePath);
    return succeeds ? 'https://example.test/p.jpg' : null;
  }
}

Future<void> _pump(
  WidgetTester tester,
  _StubAuth auth, {
  String? name = '홍길동',
  String? email = 'a@b.com',
  ProfileService? profiles,
}) => pumpScreen(
  tester,
  YouScreen(name: name, email: email),
  size: const Size(1200, 3600),
  overrides: <Override>[
    authServiceProvider.overrideWithValue(auth),
    profileServiceProvider.overrideWithValue(profiles ?? _StubProfiles()),
  ],
);

void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  group('비밀번호 재설정', () {
    testWidgets('로그인한 주소로 메일을 보낸다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth);

      await tester.tap(find.text(K.changePassword.tr()));
      await tester.pumpAndSettle();

      expect(auth.resets, <String>['a@b.com']);
      expect(find.textContaining('a@b.com'), findsWidgets);
    });

    testWidgets('못 보내면 그렇다고 말한다', (tester) async {
      final auth = _StubAuth(succeeds: false);
      await _pump(tester, auth);

      await tester.tap(find.text(K.changePassword.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.pwResetFailed.tr()), findsOneWidget);
    });

    testWidgets('메일 주소가 없으면 줄 자체가 없다', (tester) async {
      // 익명이나 소셜 로그인은 보낼 곳이 없다.
      await _pump(tester, _StubAuth(), name: null, email: null);

      expect(find.text(K.changePassword.tr()), findsNothing);
    });
  });

  // v1 은 사진과 다섯 칸을 갖고 있었다. 리메이크 뒤에는 이름 한 줄짜리
  // 알림창이 그 자리에 있었고, 없어진 것이 기록조차 안 됐다.
  group('프로필 편집', () {
    /// 편집 화면을 연다. 이름 칸이 첫 칸이다.
    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text(K.editProfile.tr()));
      await tester.pumpAndSettle();
    }

    testWidgets('이름과 다섯 칸이 다 있다', (tester) async {
      await _pump(tester, _StubAuth());
      await open(tester);

      for (final label in <String>[
        K.nameLabel,
        K.usernameLabel,
        K.pronounsLabel,
        K.phoneLabel,
        K.genderLabel,
      ]) {
        expect(find.text(label.tr()), findsOneWidget);
      }
    });

    testWidgets('저장하면 이름은 계정으로, 나머지는 프로필로 간다', (tester) async {
      final auth = _StubAuth();
      final profiles = _StubProfiles();
      await _pump(tester, auth, profiles: profiles);
      await open(tester);

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '  김승표  ');
      await tester.enterText(fields.at(1), 'seungpyo');
      await tester.enterText(fields.at(2), 'they/them');
      await tester.enterText(fields.at(3), '010-0000-0000');
      await tester.tap(find.text(K.save.tr()));
      await tester.pumpAndSettle();

      expect(auth.names, <String>['김승표']);
      expect(profiles.saved.single.username, 'seungpyo');
      expect(profiles.saved.single.pronouns, 'they/them');
      expect(profiles.saved.single.phone, '010-0000-0000');
      expect(find.text(K.profileSaved.tr()), findsOneWidget);
    });

    testWidgets('저장해둔 값이 칸에 들어와 있다', (tester) async {
      await _pump(
        tester,
        _StubAuth(),
        profiles: _StubProfiles(
          stored: const TpProfile(username: 'seungpyo', gender: '남'),
        ),
      );
      await open(tester);

      expect(find.text('seungpyo'), findsOneWidget);
      expect(find.text('남'), findsOneWidget);
    });

    testWidgets('취소하면 아무 일도 없다', (tester) async {
      final auth = _StubAuth();
      final profiles = _StubProfiles();
      await _pump(tester, auth, profiles: profiles);
      await open(tester);

      await tester.enterText(find.byType(TextField).first, '다른 이름');
      await tester.tap(find.text(K.cancel.tr()));
      await tester.pumpAndSettle();

      expect(auth.names, isEmpty);
      expect(profiles.saved, isEmpty);
    });

    testWidgets('빈 이름은 계정에 안 올린다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth);
      await open(tester);

      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.tap(find.text(K.save.tr()));
      await tester.pumpAndSettle();

      expect(auth.names, isEmpty);
    });

    testWidgets('한쪽만 실패해도 저장했다고 말하지 않는다', (tester) async {
      // 이름은 계정에, 나머지는 프로필 문서에 간다.
      await _pump(
        tester,
        _StubAuth(),
        profiles: _StubProfiles(succeeds: false),
      );
      await open(tester);

      await tester.enterText(find.byType(TextField).first, '새 이름');
      await tester.tap(find.text(K.save.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.profileFailed.tr()), findsOneWidget);
    });

    testWidgets('사진을 골라 올린다', (tester) async {
      final profiles = _StubProfiles();
      await _pump(tester, _StubAuth(), profiles: profiles);
      await open(tester);

      await tester.tap(find.text(K.changePhoto.tr()));
      await tester.pumpAndSettle();

      // 갤러리는 플랫폼 채널이라 테스트에서 아무것도 안 돌려준다. 화면이
      // 죽지 않는 것까지가 여기서 볼 수 있는 전부다.
      expect(find.text(K.editProfile.tr()), findsWidgets);
      expect(profiles.uploads, isEmpty);
    });
  });
}
