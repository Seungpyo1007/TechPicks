/// 계정에 딸린 프로필.
///
/// v1 은 이걸 다 갖고 있었다 — 사진, 사용자 이름, 대명사, 전화번호, 성별.
/// 리메이크 뒤에는 표시 이름 한 줄만 남았고, "바꿀 수 있는 게 이름뿐이었다"는
/// 주석까지 붙어 있었다. **사실이 아니었다.**
///
/// 저장 자리는 v1 과 같은 Firestore `users/{uid}` 다. 열쇠 이름도 그대로라
/// 예전 사용자의 값이 그대로 보인다.
class TpProfile {
  const TpProfile({
    this.username,
    this.pronouns,
    this.phone,
    this.gender,
    this.photoUrl,
  });

  /// 표시 이름과 별개인 사용자 이름. v1 의 `username`.
  final String? username;

  /// 불릴 대명사. 지어내지 않기 위해 **받아 적는 칸**이다.
  final String? pronouns;

  final String? phone;
  final String? gender;

  /// Storage 에 올린 사진. 없으면 이니셜 원을 그린다.
  final String? photoUrl;

  bool get isEmpty =>
      (username ?? '').isEmpty &&
      (pronouns ?? '').isEmpty &&
      (phone ?? '').isEmpty &&
      (gender ?? '').isEmpty &&
      (photoUrl ?? '').isEmpty;

  static String? _read(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  factory TpProfile.fromMap(Map<String, Object?> map) => TpProfile(
    username: _read(map, 'username'),
    pronouns: _read(map, 'pronouns'),
    // v1 이 쓰던 열쇠 이름이다. 바꾸면 예전 값이 안 보인다.
    phone: _read(map, 'phone_number'),
    gender: _read(map, 'gender'),
    photoUrl: _read(map, 'photo_url'),
  );

  /// 비운 칸은 **지우는 것**이지 안 건드리는 게 아니다. null 로 적어 보낸다.
  Map<String, Object?> toMap() => <String, Object?>{
    'username': username,
    'pronouns': pronouns,
    'phone_number': phone,
    'gender': gender,
    'photo_url': photoUrl,
  };

  TpProfile copyWith({
    String? username,
    String? pronouns,
    String? phone,
    String? gender,
    String? photoUrl,
  }) => TpProfile(
    username: username ?? this.username,
    pronouns: pronouns ?? this.pronouns,
    phone: phone ?? this.phone,
    gender: gender ?? this.gender,
    photoUrl: photoUrl ?? this.photoUrl,
  );
}
