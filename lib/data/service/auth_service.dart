import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/error_reporter.dart';

/// 로그인한 사람.
class TpUser {
  const TpUser({
    required this.uid,
    this.name,
    this.email,
    this.isAnonymous = false,
  });

  final String uid;
  final String? name;
  final String? email;
  final bool isAnonymous;
}

/// 로그인 방법. 화면의 버튼 네 개와 짝이 맞는다.
///
/// Facebook 은 뺐다. 붙이려면 개발자 계정과 앱 심사가 따로 필요한데 그걸
/// 치를 만큼 쓰일 거라고 볼 근거가 없었다.
enum AuthMethod { google, apple, email, anonymous }

/// 사용자가 로그인 시트를 닫았다.
///
/// **실패가 아니다.** 스스로 그만둔 사람에게 "연결되지 않았습니다"를
/// 보여주면 앱이 고장 난 것처럼 읽힌다.
class AuthCanceled implements Exception {
  const AuthCanceled();

  @override
  String toString() => 'AuthCanceled';
}

/// 인증.
///
/// 화면은 이 인터페이스만 본다. 테스트가 Firebase 를 띄우지 않게 하려는
/// 것이고, v1 처럼 화면 안에서 FirebaseAuth 를 직접 부르면 로그인 흐름을
/// 검사할 방법이 없다.
abstract class AuthService {
  TpUser? get current;

  Future<TpUser?> signIn(AuthMethod method, {String? email, String? password});

  /// 이메일 가입. 성공하면 그대로 로그인된 상태다.
  Future<TpUser?> signUp({required String email, required String password});

  Future<void> signOut();
}

/// Firebase 구현.
///
/// Google 과 Apple 은 각자 플러그인이 계정을 고르게 하고, 거기서 받은 토큰을
/// Firebase 자격증명으로 바꿔 넣는다. 어느 쪽도 콘솔 설정 없이는 안 돈다 —
/// Google 은 `google-services.json`·`GoogleService-Info.plist` 의
/// `oauth_client`, Apple 은 Apple Developer 에서 켠 Sign in with Apple 이다.
/// 설정이 없으면 플러그인이 던지고, 여기서 삼켜 화면이 안내를 띄운다.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth, GoogleSignIn? google})
    : _given = auth,
      _google = google;

  final fb.FirebaseAuth? _given;

  GoogleSignIn? _google;

  /// `initialize()` 는 한 번만 부르면 된다.
  bool _googleReady = false;

  /// Firebase 가 초기화되지 않았으면 `FirebaseAuth.instance` 자체가 던진다.
  ///
  /// 생성자에서 잡으면 프로바이더를 읽는 순간 앱이 죽는다. main.dart 가
  /// 초기화 실패를 삼키는 것과 짝이 맞아야 해서 여기서도 null 로 떨어뜨린다.
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
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async {
    final auth = _auth;
    if (auth == null) return null;
    try {
      return switch (method) {
        AuthMethod.anonymous => _map((await auth.signInAnonymously()).user),
        AuthMethod.email =>
          email == null || password == null
              ? null
              : _map(
                  (await auth.signInWithEmailAndPassword(
                    email: email,
                    password: password,
                  )).user,
                ),
        AuthMethod.google => await _signInWithGoogle(auth),
        AuthMethod.apple => await _signInWithApple(auth),
      };
    } on AuthCanceled {
      // 스스로 그만둔 것이다. 화면이 실패로 안 읽게 그대로 올려보낸다.
      rethrow;
    } catch (e, s) {
      // FirebaseAuthException 만 잡으면 설정이 없는 빌드에서 새어 나간다.
      // 화면은 어느 쪽이든 "연결되지 않았다"로 떨어진다.
      TpErrors.record(e, s, reason: 'auth.signIn.$method');
      return null;
    }
  }

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) return null;
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _map(cred.user);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'auth.signUp');
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e, s) {
      // 이미 로그아웃 상태거나 Firebase 가 없다. 어느 쪽이든 할 일이 없다.
      TpErrors.record(e, s, reason: 'auth.signOut');
    }
  }

  /// 구글 계정 선택 → ID 토큰 → Firebase.
  ///
  /// v7 부터 `authenticate()` 는 성공 아니면 던진다. 취소도 예외로 온다.
  Future<TpUser?> _signInWithGoogle(fb.FirebaseAuth auth) async {
    final google = _google ??= GoogleSignIn.instance;

    // 모바일만 쓴다. 웹은 버튼을 직접 그려야 해서 여기로 안 온다.
    if (!google.supportsAuthenticate()) return null;

    if (!_googleReady) {
      await google.initialize();
      _googleReady = true;
    }

    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthCanceled();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) return null;

    final credential = fb.GoogleAuthProvider.credential(idToken: idToken);
    return _map((await auth.signInWithCredential(credential)).user);
  }

  /// Apple 자격증명 → Firebase.
  ///
  /// nonce 를 원문으로 Firebase 에 주고 Apple 에는 해시를 준다. 그래야 받은
  /// 토큰이 이 요청에 대한 응답인지 확인된다.
  ///
  /// **이름은 첫 로그인에만 온다.** 그때 프로필에 심어두지 않으면 다시 받을
  /// 방법이 없다.
  Future<TpUser?> _signInWithApple(fb.FirebaseAuth auth) async {
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
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCanceled();
      }
      rethrow;
    }

    final idToken = apple.identityToken;
    if (idToken == null) return null;

    final credential = fb.AppleAuthProvider.credentialWithIDToken(
      idToken,
      rawNonce,
      fb.AppleFullPersonName(
        givenName: apple.givenName,
        familyName: apple.familyName,
      ),
    );

    final user = (await auth.signInWithCredential(credential)).user;
    await _adoptAppleName(user, apple);
    return _map(user);
  }

  /// Apple 이 준 이름을 프로필에 한 번 심는다.
  ///
  /// 실패해도 로그인 자체는 성공이다. 이름 하나 때문에 되돌리지 않는다.
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

  static TpUser? _map(fb.User? u) => u == null
      ? null
      : TpUser(
          uid: u.uid,
          name: u.displayName,
          email: u.email,
          isAnonymous: u.isAnonymous,
        );
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

/// 로그인 시도의 결말.
///
/// 성공과 실패만 두면 취소가 실패로 섞인다. 화면이 셋을 다르게 다뤄야 한다.
enum SignInOutcome { ok, canceled, failed }
