import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../domain/model/tp_weights.dart';

/// 계정에 올라가 있는 것. 문서가 없는 칸은 null.
///
/// [AccountSyncService.watch] 는 문서 하나가 바뀔 때마다 그 칸만 채워 흘린다.
class AccountState {
  const AccountState({this.shortlist, this.weights, this.recents});

  final List<String>? shortlist;
  final TpWeights? weights;
  final List<String>? recents;
}

/// 관심 목록·가중치·최근 검색을 계정에 올리고 내린다.
///
/// **로컬이 먼저다.** 계정 없이 쓰는 사람은 이 경로를 아예 안 탄다. 통화·테마·
/// 언어는 기기마다 다르게 두는 게 맞아서 올리지 않는다.
abstract class AccountSyncService {
  Future<AccountState> read(String uid);

  /// 다른 기기에서 바뀐 것. 이 기기가 쓴 것의 메아리는 거른다.
  Stream<AccountState> watch(String uid);

  Future<void> writeShortlist(String uid, List<String> slugs);

  Future<void> writeWeights(String uid, TpWeights weights);

  Future<void> writeRecents(String uid, List<String> keys);

  /// 계정 삭제 때. 세 문서, 프로필 문서, 프로필 사진.
  Future<void> delete(String uid);
}

/// Firestore 구현. `users/{uid}/state/{shortlist,weights,recents}`.
///
/// 칸마다 문서 하나다. 슬러그마다 문서를 두면 지운 것을 표시할 자리가
/// 필요해지는데, 10개 남짓한 목록에 그건 과하다.
class FirestoreAccountSync implements AccountSyncService {
  FirestoreAccountSync({FirebaseFirestore? db, FirebaseStorage? storage})
    : _db = db,
      _storage = storage;

  FirebaseFirestore? _db;
  FirebaseStorage? _storage;

  DocumentReference<Map<String, dynamic>> _user(String uid) =>
      (_db ??= FirebaseFirestore.instance).collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _state(String uid, String name) =>
      _user(uid).collection('state').doc(name);

  static List<String>? _strings(Object? raw) =>
      raw is List ? raw.whereType<String>().toList(growable: false) : null;

  static List<String>? _shortlist(Map<String, dynamic>? d) =>
      d == null ? null : _strings(d['slugs']);

  static TpWeights? _weights(Map<String, dynamic>? d) =>
      d == null ? null : TpWeights.fromJson(d);

  static List<String>? _recents(Map<String, dynamic>? d) =>
      d == null ? null : _strings(d['keys']);

  @override
  Future<AccountState> read(String uid) async {
    final docs =
        await Future.wait(<Future<DocumentSnapshot<Map<String, dynamic>>>>[
          _state(uid, 'shortlist').get(),
          _state(uid, 'weights').get(),
          _state(uid, 'recents').get(),
        ]);
    return AccountState(
      shortlist: _shortlist(docs[0].data()),
      weights: _weights(docs[1].data()),
      recents: _recents(docs[2].data()),
    );
  }

  @override
  Stream<AccountState> watch(String uid) {
    late final StreamController<AccountState> out;
    final subs = <StreamSubscription<Object?>>[];
    void on(String name, AccountState Function(Map<String, dynamic>?) map) {
      subs.add(
        _state(uid, name).snapshots().listen((snap) {
          // 이 기기가 방금 쓴 것의 메아리다. 받아 쓰면 끄는 중인 슬라이더가
          // 한 박자 전 값으로 튄다.
          if (snap.metadata.hasPendingWrites) return;
          final data = snap.data();
          if (data != null) out.add(map(data));
        }, onError: out.addError),
      );
    }

    out = StreamController<AccountState>(
      onListen: () {
        on('shortlist', (d) => AccountState(shortlist: _shortlist(d)));
        on('weights', (d) => AccountState(weights: _weights(d)));
        on('recents', (d) => AccountState(recents: _recents(d)));
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }

  Future<void> _write(String uid, String name, Map<String, dynamic> data) =>
      _state(uid, name).set(<String, dynamic>{
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> writeShortlist(String uid, List<String> slugs) =>
      _write(uid, 'shortlist', <String, dynamic>{'slugs': slugs});

  @override
  Future<void> writeWeights(String uid, TpWeights weights) =>
      _write(uid, 'weights', weights.toJson());

  @override
  Future<void> writeRecents(String uid, List<String> keys) =>
      _write(uid, 'recents', <String, dynamic>{'keys': keys});

  @override
  Future<void> delete(String uid) async {
    final db = _db ??= FirebaseFirestore.instance;
    final batch = db.batch();
    for (final name in <String>['shortlist', 'weights', 'recents']) {
      batch.delete(_state(uid, name));
    }
    batch.delete(_user(uid));
    await batch.commit();
    try {
      await (_storage ??= FirebaseStorage.instance)
          .ref()
          .child('profile_images')
          .child(uid)
          .delete();
    } on FirebaseException catch (e) {
      // 사진을 올린 적이 없으면 없는 게 맞다.
      if (e.code != 'object-not-found') rethrow;
    }
  }
}
