import 'dart:async';

import 'package:techpicks/data/service/auth_service.dart';

/// 테스트용 인증. 한동안 테스트 파일마다 `implements AuthService` 가 복사돼
/// 있었다(8개 파일에 11개). 인터페이스가 바뀔 때마다 전부 고쳐야 했다.
///
/// 기본은 무엇이든 성공하는 계정이다. 필드를 바꿔 실패·취소·늦은 복원을 만든다.
class FakeAuthService implements AuthService {
  FakeAuthService({
    this.user,
    this.signInResult,
    this.signUpResult,
    this.resetFailure,
    this.verifyFailure,
    this.deleteFailure,
    this.hangSignOut = false,
  });

  /// 지금 로그인한 사람.
  TpUser? user;

  /// null 이면 [defaultUser] 로 성공.
  AuthResult? signInResult;
  AuthResult? signUpResult;
  AuthFailure? resetFailure;
  AuthFailure? verifyFailure;
  AuthFailure? deleteFailure;

  /// 로그아웃이 영영 안 돌아온다(Firebase 가 멈춘 경우).
  bool hangSignOut;

  static const TpUser defaultUser = TpUser(
    uid: 'u1',
    name: 'Test User',
    email: 'test@techpicks.app',
    method: AuthMethod.email,
    emailVerified: true,
  );

  final List<AuthMethod> signIns = <AuthMethod>[];
  final List<String> resets = <String>[];
  final List<String> signUps = <String>[];

  /// 이메일 로그인에 들어온 주소.
  final List<String> emails = <String>[];
  int signOuts = 0;
  int verifies = 0;
  int deletes = 0;
  String? deletePassword;

  final StreamController<TpUser?> _changes =
      StreamController<TpUser?>.broadcast();

  /// 저장된 세션이 늦게 복원된 것처럼 흘린다.
  void emit(TpUser? next) {
    user = next;
    _changes.add(next);
  }

  @override
  TpUser? get current => user;

  @override
  Stream<TpUser?> changes() => _changes.stream;

  @override
  Future<AuthResult> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async {
    signIns.add(method);
    if (email != null) emails.add(email);
    final result = signInResult ?? const AuthResult.ok(defaultUser);
    if (result.user != null) user = result.user;
    return result;
  }

  @override
  Future<AuthResult> signUp({
    required String email,
    required String password,
  }) async {
    signUps.add(email);
    final result = signUpResult ?? const AuthResult.ok(defaultUser);
    if (result.user != null) user = result.user;
    return result;
  }

  @override
  Future<AuthFailure?> sendPasswordReset(String email) async {
    resets.add(email);
    return resetFailure;
  }

  @override
  Future<AuthFailure?> sendEmailVerification() async {
    verifies++;
    return verifyFailure;
  }

  @override
  Future<TpUser?> updateName(String name) async {
    final u = user;
    if (u == null) return null;
    return user = TpUser(
      uid: u.uid,
      name: name,
      email: u.email,
      method: u.method,
      emailVerified: u.emailVerified,
      photoUrl: u.photoUrl,
    );
  }

  @override
  Future<AuthFailure?> deleteAccount({
    String? password,
    required Future<void> Function(String uid) cleanup,
  }) async {
    deletes++;
    deletePassword = password;
    if (deleteFailure != null) return deleteFailure;
    final uid = user?.uid;
    if (uid != null) await cleanup(uid);
    user = null;
    return null;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    if (hangSignOut) await Completer<void>().future;
    user = null;
  }
}
