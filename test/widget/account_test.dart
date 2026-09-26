import 'dart:typed_data' show Uint8List;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/service/profile_service.dart';
import 'package:techpicks/domain/model/tp_profile.dart';
import 'package:techpicks/feature/you/profile_edit_screen.dart';
import 'package:techpicks/feature/you/you_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/fake_auth.dart';
import '../support/harness.dart';

/// 이름과 비밀번호는 Firebase 가 처리한다. 여기서는 무엇을 시켰는지만 본다.
class _StubAuth extends FakeAuthService {
  _StubAuth({this.succeeds = true, TpUser? user})
    : super(
        user:
            user ??
            const TpUser(
              uid: 'u1',
              email: 'a@b.com',
              name: '홍길동',
              method: AuthMethod.email,
              emailVerified: true,
            ),
        resetFailure: succeeds ? null : AuthFailure.network,
      );

  final bool succeeds;
  final List<String> names = <String>[];

  @override
  Future<TpUser?> updateName(String name) async {
    names.add(name);
    if (!succeeds) return null;
    return super.updateName(name);
  }
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

  final List<String> removed = <String>[];

  @override
  Future<String?> uploadPhoto(
    String uid,
    Uint8List bytes, {
    ValueChanged<double>? onProgress,
  }) async {
    uploads.add('${bytes.length}B');
    onProgress?.call(.5);
    return succeeds ? 'https://example.test/p.jpg' : null;
  }

  @override
  Future<void> removePhoto(String uid) async => removed.add(uid);
}

/// 카메라·갤러리. 몇 바이트를 돌려주거나 권한 거절을 던진다.
class _FakePicker extends ImagePicker {
  _FakePicker({this.denied = false});

  final bool denied;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (denied) throw PlatformException(code: 'camera_access_denied');
    return XFile.fromData(Uint8List.fromList(<int>[1, 2, 3]));
  }
}

Future<void> _pump(
  WidgetTester tester,
  FakeAuthService auth, {
  String? name = '홍길동',
  String? email = 'a@b.com',
  AuthMethod? method,
  bool emailVerified = true,
  ProfileService? profiles,
}) async {
  await pumpScreen(
    tester,
    YouScreen(
      name: name,
      email: email,
      method: method,
      emailVerified: emailVerified,
    ),
    size: const Size(1200, 3600),
    overrides: <Override>[
      authServiceProvider.overrideWithValue(auth),
      profileServiceProvider.overrideWithValue(profiles ?? _StubProfiles()),
    ],
  );
  // 계정 줄은 맨 위 카드를 눌러 들어간 계정 화면에 있다.
  final label = name ?? email;
  if (label != null) {
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }
}

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

    testWidgets('사진 바꾸기를 누르면 찍기·고르기가 나온다', (tester) async {
      final profiles = _StubProfiles();
      await _pump(tester, _StubAuth(), profiles: profiles);
      await open(tester);

      await tester.tap(find.text(K.changePhoto.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.takePhoto.tr()), findsOneWidget);
      expect(find.text(K.choosePhoto.tr()), findsOneWidget);
      // 사진이 없으면 지울 것도 없다.
      expect(find.text(K.removePhoto.tr()), findsNothing);
      expect(profiles.uploads, isEmpty);
    });
  });

  group('프로필 사진', () {
    /// 편집 화면만 띄운다. 선택기와 자르기를 갈아끼운다.
    Future<void> pumpEdit(
      WidgetTester tester, {
      required _StubProfiles profiles,
      ImagePicker? picker,
      TpChrome chrome = TpChrome.ios,
    }) async {
      await pumpScreen(
        tester,
        ProfileEditScreen(
          onBack: () {},
          picker: picker ?? _FakePicker(),
          crop: (_, bytes) async => bytes,
        ),
        chrome: chrome,
        size: const Size(1200, 3600),
        overrides: <Override>[
          authServiceProvider.overrideWithValue(_StubAuth()),
          profileServiceProvider.overrideWithValue(profiles),
        ],
      );
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester) async {
      await tester.tap(find.text(K.changePhoto.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(K.choosePhoto.tr()));
      await tester.pumpAndSettle();
    }

    testWidgets('고르면 바로 올리고 알린다', (tester) async {
      final profiles = _StubProfiles();
      await pumpEdit(tester, profiles: profiles);
      await choose(tester);

      expect(profiles.uploads, hasLength(1));
      expect(profiles.stored.photoUrl, 'https://example.test/p.jpg');
      expect(find.text(K.photoUpdated.tr()), findsOneWidget);
      // 위의 저장은 안 눌렀다. 사진만 저장됐다.
      expect(find.text(K.profileSaved.tr()), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text(K.photoUpdated.tr()), findsNothing);
    });

    testWidgets('못 올리면 빨간 줄과 다시 시도', (tester) async {
      final profiles = _StubProfiles(succeeds: false);
      await pumpEdit(tester, profiles: profiles);
      await choose(tester);

      expect(find.text(K.photoFailed.tr()), findsOneWidget);
      await tester.tap(find.text(K.retry.tr()));
      await tester.pumpAndSettle();
      expect(profiles.uploads, hasLength(2));
    });

    testWidgets('권한을 거절하면 조용히 끝난다', (tester) async {
      final profiles = _StubProfiles();
      await pumpEdit(
        tester,
        profiles: profiles,
        picker: _FakePicker(denied: true),
      );
      await tester.tap(find.text(K.changePhoto.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(K.takePhoto.tr()));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(profiles.uploads, isEmpty);
      expect(find.text(K.photoFailed.tr()), findsNothing);
    });

    testWidgets('지우면 묻고, 주소를 비우고 파일을 지운다', (tester) async {
      final profiles = _StubProfiles(
        stored: const TpProfile(
          username: 'seungpyo',
          photoUrl: 'https://example.test/old.jpg',
        ),
      );
      await pumpEdit(tester, profiles: profiles);

      await tester.tap(find.text(K.changePhoto.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(K.removePhoto.tr()));
      await tester.pumpAndSettle();
      expect(find.text(K.removePhotoAsk.tr()), findsOneWidget);

      await tester.tap(find.text(K.removePhoto.tr()).last);
      await tester.pumpAndSettle();

      expect(profiles.stored.photoUrl, isNull);
      expect(profiles.stored.username, 'seungpyo');
      expect(profiles.removed, <String>['u1']);
      expect(find.text(K.photoRemoved.tr()), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Android 는 아바타를 누르면 바텀 시트', (tester) async {
      await pumpEdit(
        tester,
        profiles: _StubProfiles(),
        chrome: TpChrome.android,
      );
      await tester.tap(find.bySemanticsLabel(K.changePhoto.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text(K.choosePhotoGallery.tr()), findsOneWidget);
      expect(find.text(K.removePhoto.tr()), findsNothing);
    });
  });

  group('계정', () {
    testWidgets('Google 계정은 비밀번호 줄이 없고 방법이 보인다', (tester) async {
      await _pump(tester, _StubAuth(), method: AuthMethod.google);

      expect(find.text(K.changePassword.tr()), findsNothing);
      expect(find.text('a@b.com · Google'), findsOneWidget);
      expect(find.text(K.deleteAccount.tr()), findsOneWidget);
    });

    testWidgets('확인한 메일은 알약으로, 삭제 카드 아래 안내가 있다', (tester) async {
      await _pump(tester, _StubAuth());

      expect(find.text(K.emailConfirmed.tr()), findsOneWidget);
      expect(find.text(K.deleteNote.tr()), findsOneWidget);
      // 로그아웃과 삭제가 한 카드에 묶이지 않는다.
      expect(find.text(K.logout.tr()), findsOneWidget);
    });

    testWidgets('확인 안 한 메일은 다시 보낼 수 있다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth, emailVerified: false);

      expect(find.text(K.verifyEmail.tr()), findsOneWidget);
      await tester.tap(find.text(K.resend.tr()));
      await tester.pumpAndSettle();

      expect(auth.verifies, 1);
      expect(find.text(K.verifySent.tr()), findsOneWidget);
    });

    testWidgets('이메일 계정 삭제는 비밀번호를 받아 지운다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth);

      await tester.tap(find.text(K.deleteAccount.tr()));
      await tester.pumpAndSettle();
      expect(find.text(K.deleteConfirm.tr()), findsOneWidget);

      await tester.enterText(find.byType(EditableText).last, 'longenough');
      await tester.tap(find.text(K.delete.tr()));
      await tester.pumpAndSettle();

      expect(auth.deletes, 1);
      expect(auth.deletePassword, 'longenough');
      expect(find.text(K.deleted.tr()), findsOneWidget);
    });

    testWidgets('Apple 계정 삭제는 비밀번호를 묻지 않는다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth, method: AuthMethod.apple);

      await tester.tap(find.text(K.deleteAccount.tr()));
      await tester.pumpAndSettle();
      expect(find.text(K.deletePassword.tr()), findsNothing);

      await tester.tap(find.text(K.delete.tr()));
      await tester.pumpAndSettle();

      expect(auth.deletes, 1);
      expect(auth.deletePassword, isNull);
    });

    testWidgets('취소하면 아무것도 안 지운다', (tester) async {
      final auth = _StubAuth();
      await _pump(tester, auth);

      await tester.tap(find.text(K.deleteAccount.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(K.cancel.tr()));
      await tester.pumpAndSettle();

      expect(auth.deletes, 0);
    });

    testWidgets('틀린 비밀번호면 그렇게 말하고 계정은 남는다', (tester) async {
      final auth = _StubAuth()..deleteFailure = AuthFailure.badCredentials;
      await _pump(tester, auth);

      await tester.tap(find.text(K.deleteAccount.tr()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).last, 'wrongpass');
      await tester.tap(find.text(K.delete.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.authBadCredentials.tr()), findsOneWidget);
      expect(find.text(K.deleted.tr()), findsNothing);
    });
  });
}
