import 'dart:typed_data' show Uint8List;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show ValueChanged;

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
  ///
  /// 경로가 아니라 바이트를 받는다. 웹에서 `XFile.path` 는 `blob:` URL 이라
  /// `File(...)` 로 열 수 없다 — `putData` 는 어디서나 되므로 구현이 하나로
  /// 남고 `dart:io` 의존도 사라진다.
  Future<String?> uploadPhoto(
    String uid,
    Uint8List bytes, {
    ValueChanged<double>? onProgress,
  });

  /// 올린 사진 파일을 지운다. 없거나 못 지워도 던지지 않는다.
  Future<void> removePhoto(String uid);
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

  Reference _photo(String uid) => (_storage ??= FirebaseStorage.instance)
      .ref()
      .child('profile_images')
      .child(uid);

  @override
  Future<String?> uploadPhoto(
    String uid,
    Uint8List bytes, {
    ValueChanged<double>? onProgress,
  }) async {
    try {
      final ref = _photo(uid);
      final task = ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      // 진행 원이 실제 바이트 비율로 찬다.
      final sub = onProgress == null
          ? null
          : task.snapshotEvents.listen((snap) {
              if (snap.totalBytes > 0) {
                onProgress(snap.bytesTransferred / snap.totalBytes);
              }
            }, onError: (_) {});
      try {
        await task;
      } finally {
        await sub?.cancel();
      }
      return await ref.getDownloadURL();
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'profile.photo');
      return null;
    }
  }

  @override
  Future<void> removePhoto(String uid) async {
    try {
      await _photo(uid).delete();
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'profile.photo.remove');
    }
  }
}
