import 'package:firebase_auth/firebase_auth.dart' as fb;

/// 로그인한 사람.
class TpUser {
  const TpUser({required this.uid, this.name, this.email, this.isAnonymous = false});

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

  Future<void> signOut();
}

/// Firebase 구현.
///
/// Apple 과 Facebook 은 아직 붙이지 않았다. v1 에도 없었고 각각 별도 설정이
/// 필요하다. 누르면 null 을 돌려 화면이 안내를 띄운다.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  final fb.FirebaseAuth _auth;

  @override
  TpUser? get current => _map(_auth.currentUser);

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async {
    try {
      return switch (method) {
        AuthMethod.anonymous => _map((await _auth.signInAnonymously()).user),
        AuthMethod.email => email == null || password == null
            ? null
            : _map((await _auth.signInWithEmailAndPassword(
                email: email,
                password: password,
              ))
                .user),
        // 아직 미연결.
        AuthMethod.google || AuthMethod.apple || AuthMethod.facebook => null,
      };
    } on fb.FirebaseAuthException {
      return null;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static TpUser? _map(fb.User? u) => u == null
      ? null
      : TpUser(
          uid: u.uid,
          name: u.displayName,
          email: u.email,
          isAnonymous: u.isAnonymous,
        );
}
