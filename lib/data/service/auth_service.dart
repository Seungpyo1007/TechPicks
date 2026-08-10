import '../../core/error_reporter.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

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

/// 로그인 방법. 화면의 버튼 다섯 개와 짝이 맞는다.
enum AuthMethod { google, apple, facebook, email, anonymous }

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
/// Apple 과 Facebook 은 아직 붙이지 않았다. v1 에도 없었고 각각 별도 설정이
/// 필요하다. 누르면 null 을 돌려 화면이 안내를 띄운다.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth}) : _given = auth;

  final fb.FirebaseAuth? _given;

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
        // 아직 미연결.
        AuthMethod.google || AuthMethod.apple || AuthMethod.facebook => null,
      };
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

  static TpUser? _map(fb.User? u) => u == null
      ? null
      : TpUser(
          uid: u.uid,
          name: u.displayName,
          email: u.email,
          isAnonymous: u.isAnonymous,
        );
}
