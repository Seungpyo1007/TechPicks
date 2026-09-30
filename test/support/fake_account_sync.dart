import 'package:techpicks/data/service/account_sync_service.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

/// 계정 쪽이 비어 있고, 무엇을 써도 받아만 두는 가짜. 위젯 테스트 기본값이다 —
/// 안 두면 로그인·삭제 경로가 Firestore 를 찾다 터진다.
class FakeAccountSync implements AccountSyncService {
  final List<String> deleted = <String>[];

  @override
  Future<AccountState> read(String uid) async => const AccountState();

  @override
  Stream<AccountState> watch(String uid) => const Stream<AccountState>.empty();

  @override
  Future<void> writeShortlist(String uid, List<String> slugs) async {}

  @override
  Future<void> writeWeights(String uid, TpWeights weights) async {}

  @override
  Future<void> writeRecents(String uid, List<String> keys) async {}

  @override
  Future<void> delete(String uid) async => deleted.add(uid);
}
