import 'package:cloud_firestore/cloud_firestore.dart';

/// 계정에 올라가 있는 관심 목록.
class RemoteShortlist {
  const RemoteShortlist({required this.slugs, required this.updatedAt});

  final List<String> slugs;

  /// 그쪽에서 마지막으로 고친 시각. 어느 쪽이 이길지 이걸로 정한다.
  final DateTime updatedAt;
}

/// 관심 목록을 계정에 올리고 내린다.
///
/// **로컬이 먼저다.** 계정 없이 쓰는 사람은 이 경로를 아예 안 탄다. 로그인한
/// 사람에게만 기기 사이 동기화가 값이 있다 — 폰에서 담은 걸 태블릿에서 보는 것.
abstract class ShortlistSyncService {
  /// 올라가 있는 것. 없으면 null.
  Future<RemoteShortlist?> read(String uid);

  Future<void> write(String uid, List<String> slugs, DateTime updatedAt);
}

/// Firestore 구현.
///
/// 문서 하나만 쓴다 — `users/{uid}/state/shortlist`. 슬러그마다 문서를 두면
/// 지운 것을 표시할 자리가 필요해지는데, 5–10개짜리 목록에 그건 과하다.
class FirestoreShortlistSync implements ShortlistSyncService {
  FirestoreShortlistSync({FirebaseFirestore? db}) : _db = db;

  FirebaseFirestore? _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      (_db ??= FirebaseFirestore.instance)
          .collection('users')
          .doc(uid)
          .collection('state')
          .doc('shortlist');

  @override
  Future<RemoteShortlist?> read(String uid) async {
    final data = (await _doc(uid).get()).data();
    if (data == null) return null;

    final at = data['updatedAt'];
    if (at is! Timestamp) return null;

    return RemoteShortlist(
      slugs:
          (data['slugs'] as List<dynamic>?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const <String>[],
      updatedAt: at.toDate(),
    );
  }

  @override
  Future<void> write(String uid, List<String> slugs, DateTime updatedAt) =>
      _doc(uid).set(<String, dynamic>{
        'slugs': slugs,
        'updatedAt': Timestamp.fromDate(updatedAt),
      });
}
