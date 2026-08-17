import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../core/error_reporter.dart';
import '../../domain/model/tp_profile.dart';

/// 프로필을 읽고 쓴다.
///
/// 화면은 이 인터페이스만 본다 — 테스트가 Firebase 없이 돌 수 있어야 한다.
abstract class ProfileService {
  Future<TpProfile> load(String uid);

  /// 저장했으면 true. 콘솔 설정이 없거나 규칙에 막히면 false 다.
  Future<bool> save(String uid, TpProfile profile);

  /// 사진을 올리고 주소를 돌려준다. 실패하면 null.
  Future<String?> uploadPhoto(String uid, String filePath);
}

/// Firestore `users/{uid}` + Storage `profile_images/{uid}`.
///
/// v1 이 쓰던 자리 그대로다. 열쇠 이름을 바꾸면 예전 사용자의 값이 안 보인다.
///
/// **어느 호출도 던지지 않는다.** Storage 규칙이나 버킷이 아직 없을 수 있고,
/// 그때 내 정보 화면이 통째로 죽으면 안 된다 — 화면은 안내를 띄운다.
class FirebaseProfileService implements ProfileService {
  FirebaseProfileService({FirebaseFirestore? db, FirebaseStorage? storage})
    : _db = db,
      _storage = storage;

  FirebaseFirestore? _db;
  FirebaseStorage? _storage;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      (_db ??= FirebaseFirestore.instance).collection('users').doc(uid);

  @override
  Future<TpProfile> load(String uid) async {
    try {
      final data = (await _doc(uid).get()).data();
      return data == null ? const TpProfile() : TpProfile.fromMap(data);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'profile.load');
      return const TpProfile();
    }
  }

  @override
  Future<bool> save(String uid, TpProfile profile) async {
    try {
      // merge 를 쓴다. 이 문서에는 관심 목록 동기화가 쓰는 것 말고도 나중에
      // 다른 게 들어올 수 있다.
      await _doc(uid).set(profile.toMap(), SetOptions(merge: true));
      return true;
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'profile.save');
      return false;
    }
  }

  @override
  Future<String?> uploadPhoto(String uid, String filePath) async {
    try {
      final ref = (_storage ??= FirebaseStorage.instance)
          .ref()
          .child('profile_images')
          .child(uid);
      await ref.putFile(File(filePath));
      return await ref.getDownloadURL();
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'profile.photo');
      return null;
    }
  }
}
