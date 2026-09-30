import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/error_reporter.dart';

/// 로그인 방법. 화면의 버튼 셋과 짝이 맞는다.
///
/// 익명은 뺐다. 로그인은 선택이고, 로그인하지 않은 사람의 데이터는 기기에만
/// 둔다 — 익명 계정을 만들어 봐야 나중에 진짜 계정과 이어 붙일 일만 생긴다.
/// Facebook 은 개발자 계정·앱 심사를 치를 만큼 쓰일 근거가 없어 안 붙였다.
enum AuthMethod { apple, google, email }

/// 로그인한 사람.
class TpUser {
  const TpUser({
    required this.uid,
    this.name,
    this.email,
    this.method,
    this.emailVerified = false,
    this.photoUrl,
  });

  final String uid;
  final String? name;
  final String? email;

  /// 어느 방법으로 만든 계정인가. 비밀번호 변경 줄은 이메일 계정에만 뜬다.
  final AuthMethod? method;

  /// 이메일 계정이 메일 주소를 확인했는가. Apple·Google 은 늘 true 다.
  final bool emailVerified;
  final String? photoUrl;
}

/// 로그인이 안 된 까닭. 화면은 이걸 문장 하나로 바꾼다.
///
/// 예전에는 전부 null 이었다. 비밀번호가 틀려도, 이미 가입된 메일이어도,
/// 인터넷이 끊겨도 "로그인하지 못했습니다" 하나였고, Google·Apple 은 무엇이
/// 실패해도 "아직 연결되지 않았습니다"였다.
enum AuthFailure {
  /// 스스로 닫았다. **실패로 보여주지 않는다.**
  canceled,

  /// 메일이나 비밀번호가 틀렸다. 열거 보호가 켜진 Firebase 는 "계정 없음"과
  /// "비밀번호 틀림"을 구분해 주지 않는다.
  badCredentials,
  emailInUse,
  weakPassword,
  invalidEmail,
  network,
  tooMany,

  /// 같은 메일이 다른 방법(Google 등)으로 이미 가입돼 있다.
  otherProvider,

  /// 계정 삭제처럼 민감한 일은 방금 로그인했어야 한다.
  requiresRecentLogin,
  disabled,

  /// 콘솔에서 이 방법을 안 켰거나, 빌드에 설정이 없다.
  notConfigured,
  unknown;

  /// Firebase 오류 코드를 우리 이유로.
  static AuthFailure fromCode(String code) => switch (code) {
    'wrong-password' ||
    'user-not-found' ||
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' => badCredentials,
    'email-already-in-use' => emailInUse,
    'weak-password' => weakPassword,
    'invalid-email' => invalidEmail,
    'network-request-failed' => network,
    'too-many-requests' => tooMany,
    'account-exists-with-different-credential' ||
    'credential-already-in-use' => otherProvider,
    'requires-recent-login' => requiresRecentLogin,
    'user-disabled' => disabled,
    'operation-not-allowed' ||
    'configuration-not-found' ||
    'app-not-authorized' => notConfigured,
    _ => unknown,
  };
}

/// 로그인·가입의 결말. 성공이면 [user], 아니면 [failure].
class AuthResult {
  const AuthResult.ok(TpUser this.user) : failure = null;
  const AuthResult.failed(AuthFailure this.failure) : user = null;

  final TpUser? user;
  final AuthFailure? failure;

  bool get ok => user != null;
}

/// 인증.
///
/// 화면은 이 인터페이스만 본다. 테스트가 Firebase 를 띄우지 않게 하려는
/// 것이다.
abstract class AuthService {
  TpUser? get current;

  /// 로그인 상태가 바뀔 때마다 흘린다. Firebase 는 저장된 세션을 비동기로
  /// 복원하므로 [current] 만으로는 모자란다.
  Stream<TpUser?> changes();

  Future<AuthResult> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  });

  /// 이메일 가입. 성공하면 로그인된 상태고, 확인 메일이 나간다.
  Future<AuthResult> signUp({required String email, required String password});

  /// 비밀번호 재설정 메일. **로그아웃 상태에서도** 쓴다(비밀번호 찾기).
  /// 보냈으면 null.
  Future<AuthFailure?> sendPasswordReset(String email);

  /// 메일 주소 확인 메일을 다시 보낸다. 보냈으면 null.
  Future<AuthFailure?> sendEmailVerification();

  /// 표시 이름을 바꾼다. 성공하면 바뀐 사용자를 돌려준다.
  Future<TpUser?> updateName(String name);

  /// 계정을 지운다. 성공하면 null.
  ///
  /// 순서가 중요하다: **먼저 다시 인증**하고(Apple 은 토큰 취소에 쓸 코드를
  /// 이때 받는다), [cleanup] 으로 계정의 데이터를 지우고, Apple 토큰을
  /// 취소하고, 마지막에 계정을 지운다. 인증부터 하지 않으면 데이터만 지워지고
  /// 계정은 "최근 로그인 필요"로 남는 일이 생긴다.
  ///
  /// 이메일 계정은 [password] 가 있어야 한다.
  Future<AuthFailure?> deleteAccount({
    String? password,
    required Future<void> Function(String uid) cleanup,
  });

  Future<void> signOut();
}

/// Firebase 구현.
///
/// Google 과 Apple 은 각자 플러그인이 계정을 고르게 하고, 받은 토큰을
/// Firebase 자격증명으로 바꿔 넣는다. 어느 쪽도 콘솔 설정 없이는 안 돈다.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? auth,
    GoogleSignIn? google,
    String? googleServerClientId,
  }) : _given = auth,
       _google = google,
       _serverClientId =
           googleServerClientId ??
           (_envServerClientId.isEmpty ? null : _envServerClientId);

  /// Android 의 Google 로그인은 웹 클라이언트 ID 가 있어야 ID 토큰을 준다.
  /// 빌드할 때 `--dart-define=GOOGLE_SERVER_CLIENT_ID=...` 로 넣는다.
  static const String _envServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  /// Android 에서 Google 버튼을 보여도 되는가. iOS 는 plist 의 CLIENT_ID 로 충분하다.
  static bool get googleConfiguredForAndroid => _envServerClientId.isNotEmpty;

  final fb.FirebaseAuth? _given;
  GoogleSignIn? _google;
  final String? _serverClientId;

  /// `initialize()` 는 한 번만 부르면 된다.
  bool _googleReady = false;

  /// Firebase 가 초기화되지 않았으면 `FirebaseAuth.instance` 자체가 던진다.
  /// main.dart 가 초기화 실패를 삼키는 것과 짝이 맞게 null 로 떨어뜨린다.
  fb.FirebaseAuth? get _auth {
    if (_given != null) return _given;
    try {
      return fb.FirebaseAuth.instance;
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'auth.instance');
      return null;
    }
  }

  @override
  TpUser? get current {
    try {
      return _map(_auth?.currentUser);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'auth.current');
      return null;
    }
  }

  @override
  Stream<TpUser?> changes() {
    final auth = _auth;
    if (auth == null) return const Stream<TpUser?>.empty();
    return auth.userChanges().map(_map);
  }

  /// 오류를 이유로 바꾸고 기록한다.
  AuthFailure _fail(Object e, StackTrace s, String reason) {
    if (e is _Canceled) return AuthFailure.canceled;
    TpErrors.record(e, s, reason: reason);
    if (e is fb.FirebaseAuthException) return AuthFailure.fromCode(e.code);
    if (e is GoogleSignInException) return AuthFailure.notConfigured;
    if (e is SignInWithAppleException) return AuthFailure.notConfigured;
    return AuthFailure.unknown;
  }

  @override
  Future<AuthResult> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async {
    final auth = _auth;
    if (auth == null) return const AuthResult.failed(AuthFailure.notConfigured);
    try {
      final fb.User? user = switch (method) {
        AuthMethod.email => (await auth.signInWithEmailAndPassword(
          email: email ?? '',
          password: password ?? '',
        )).user,
        AuthMethod.google => (await auth.signInWithCredential(
          await _googleCredential(),
        )).user,
        AuthMethod.apple => await _signInWithApple(auth),
      };
      final mapped = _map(user);
      return mapped == null
          ? const AuthResult.failed(AuthFailure.unknown)
          : AuthResult.ok(mapped);
    } catch (e, s) {
      return AuthResult.failed(_fail(e, s, 'auth.signIn.${method.name}'));
    }
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) return const AuthResult.failed(AuthFailure.notConfigured);
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // 확인 메일이 안 나가도 가입은 됐다. 내 정보에서 다시 보낼 수 있다.
      try {
        await cred.user?.sendEmailVerification();
      } catch (e, s) {
        TpErrors.record(e, s, reason: 'auth.signUp.verify');
      }
      final mapped = _map(cred.user);
      return mapped == null
          ? const AuthResult.failed(AuthFailure.unknown)
          : AuthResult.ok(mapped);
    } catch (e, s) {
      return AuthResult.failed(_fail(e, s, 'auth.signUp'));
    }
  }

  @override
  Future<AuthFailure?> sendPasswordReset(String email) async {
    final auth = _auth;
    if (auth == null) return AuthFailure.notConfigured;
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } catch (e, s) {
      final failure = _fail(e, s, 'auth.passwordReset');
      // 없는 계정이라고 알려주면 가입한 메일을 캐는 데 쓰인다. 보낸 것처럼 둔다.
      return failure == AuthFailure.badCredentials ? null : failure;
    }
  }

  @override
  Future<AuthFailure?> sendEmailVerification() async {
    final user = _auth?.currentUser;
    if (user == null) return AuthFailure.unknown;
    try {
      await user.sendEmailVerification();
      return null;
    } catch (e, s) {
      return _fail(e, s, 'auth.verify');
    }
  }

  @override
  Future<TpUser?> updateName(String name) async {
    final user = _auth?.currentUser;
    if (user == null) return null;
    try {
      await user.updateDisplayName(name);
      await user.reload();
      return _map(_auth?.currentUser);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'auth.updateName');
      return null;
    }
  }

  @override
  Future<AuthFailure?> deleteAccount({
    String? password,
    required Future<void> Function(String uid) cleanup,
  }) async {
    final user = _auth?.currentUser;
    if (user == null) return AuthFailure.unknown;
    try {
      String? appleCode;
      switch (_methodOf(user)) {
        case AuthMethod.apple:
          final apple = await _appleCredential();
          appleCode = apple.$2.authorizationCode;
          await user.reauthenticateWithCredential(apple.$1);
        case AuthMethod.google:
          await user.reauthenticateWithCredential(await _googleCredential());
        case AuthMethod.email:
          if (password == null || password.isEmpty) {
            return AuthFailure.badCredentials;
          }
          await user.reauthenticateWithCredential(
            fb.EmailAuthProvider.credential(
              email: user.email ?? '',
              password: password,
            ),
          );
        case null:
          break;
      }
      await cleanup(user.uid);
      if (appleCode != null) {
        try {
          await _auth?.revokeTokenWithAuthorizationCode(appleCode);
        } catch (e, s) {
          // 토큰 취소가 안 돼도 계정은 지운다. Apple 쪽 연결은 사용자가 설정에서
          // 끊을 수 있다.
          TpErrors.record(e, s, reason: 'auth.delete.revoke');
        }
      }
      await user.delete();
      await _signOutProviders();
      return null;
    } catch (e, s) {
      return _fail(e, s, 'auth.delete');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'auth.signOut');
    }
    await _signOutProviders();
  }

  /// Google 은 자기 세션을 따로 쥔다. 안 끊으면 다음 로그인에서 계정을
  /// 고르지 않고 방금 그 계정으로 바로 들어간다.
  Future<void> _signOutProviders() async {
    if (!_googleReady) return;
    try {
      await (_google ?? GoogleSignIn.instance).signOut();
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'auth.google.signOut');
    }
  }

  /// 구글 계정 선택 → ID 토큰 → Firebase 자격증명.
  ///
  /// v7 부터 `authenticate()` 는 성공 아니면 던진다. 취소도 예외로 온다.
  Future<fb.AuthCredential> _googleCredential() async {
    final google = _google ??= GoogleSignIn.instance;
    if (!google.supportsAuthenticate()) {
      throw fb.FirebaseAuthException(code: 'operation-not-allowed');
    }
    if (!_googleReady) {
      await google.initialize(serverClientId: _serverClientId);
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw const _Canceled();
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw fb.FirebaseAuthException(code: 'configuration-not-found');
    }
    return fb.GoogleAuthProvider.credential(idToken: idToken);
  }

  /// Apple 자격증명. nonce 원문은 Firebase 에, 해시는 Apple 에 준다.
  Future<(fb.AuthCredential, AuthorizationCredentialAppleID)>
  _appleCredential() async {
    final rawNonce = AppleNonce.create();
    final AuthorizationCredentialAppleID apple;
    try {
      apple = await SignInWithApple.getAppleIDCredential(
        scopes: const <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: AppleNonce.hash(rawNonce),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const _Canceled();
      rethrow;
    }
    final idToken = apple.identityToken;
    if (idToken == null) {
      throw fb.FirebaseAuthException(code: 'configuration-not-found');
    }
    final credential = fb.AppleAuthProvider.credentialWithIDToken(
      idToken,
      rawNonce,
      fb.AppleFullPersonName(
        givenName: apple.givenName,
        familyName: apple.familyName,
      ),
    );
    return (credential, apple);
  }

  /// **이름은 첫 로그인에만 온다.** 그때 프로필에 심어두지 않으면 다시 받을
  /// 방법이 없다.
  Future<fb.User?> _signInWithApple(fb.FirebaseAuth auth) async {
    final (credential, apple) = await _appleCredential();
    final user = (await auth.signInWithCredential(credential)).user;
    await _adoptAppleName(user, apple);
    return user;
  }

  static Future<void> _adoptAppleName(
    fb.User? user,
    AuthorizationCredentialAppleID apple,
  ) async {
    if (user == null || (user.displayName?.isNotEmpty ?? false)) return;
    final name = <String?>[
      apple.givenName,
      apple.familyName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    if (name.isEmpty) return;
    try {
      await user.updateDisplayName(name);
      await user.reload();
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'auth.apple.name');
    }
  }

  static AuthMethod? _methodOf(fb.User u) {
    for (final p in u.providerData) {
      switch (p.providerId) {
        case 'apple.com':
          return AuthMethod.apple;
        case 'google.com':
          return AuthMethod.google;
        case 'password':
          return AuthMethod.email;
      }
    }
    return null;
  }

  static TpUser? _map(fb.User? u) {
    if (u == null || u.isAnonymous) return null;
    final method = _methodOf(u);
    return TpUser(
      uid: u.uid,
      name: u.displayName,
      email: u.email,
      method: method,
      emailVerified: method != AuthMethod.email || u.emailVerified,
      photoUrl: u.photoURL,
    );
  }
}

/// 사용자가 계정 선택·Apple 시트를 닫았다. 밖으로는 [AuthFailure.canceled].
class _Canceled implements Exception {
  const _Canceled();
}

/// Apple 로그인에 붙이는 일회용 난수.
///
/// 원문은 Firebase 에, SHA-256 해시는 Apple 에 준다. 이렇게 해야 받은 토큰이
/// **이 요청에 대한 응답인지** 확인된다. 가로챈 토큰을 다시 써먹지 못한다.
abstract final class AppleNonce {
  /// URL 에 그대로 실을 수 있는 문자만 쓴다.
  static const String _alphabet =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

  /// 32자. Apple 예제가 쓰는 길이다.
  static const int length = 32;

  static String create([Random? random]) {
    // 예측 가능한 난수를 쓰면 재사용 방지가 통째로 무의미해진다.
    final rng = random ?? Random.secure();
    return List<String>.generate(
      length,
      (_) => _alphabet[rng.nextInt(_alphabet.length)],
    ).join();
  }

  static String hash(String raw) => sha256.convert(utf8.encode(raw)).toString();
}
