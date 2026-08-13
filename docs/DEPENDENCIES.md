# 의존성 결정

2026-08-10 조사. 버전은 pub.dev API 로, 나머지는 공식 문서로 그날 직접 확인했다.

---

## 0. 기한이 있는 것

이 둘은 우리가 정하는 게 아니라 밖에서 정해진다.

### 0.1 Firebase 가 CocoaPods 를 버린다 — **2026년 10월**

| 시점 | 무슨 일 |
|---|---|
| 2026-10 | Firebase 가 CocoaPods 에 새 버전 발행을 멈춘다 |
| 2026-12 | CocoaPods 레지스트리가 읽기 전용이 된다 |
| 이후 | 이미 나간 버전은 계속 받을 수 있다. 앱도 계속 돈다 |

지금 우리는 `pubspec.yaml` 에서 Swift Package Manager 를 **꺼둔 상태**다.
`firebase_core 3.6.0` 이 SPM 배치를 못 따라와 iOS 빌드가 통째로 깨졌기 때문이다.

그런데 **최신 FlutterFire 는 SPM 을 지원한다.** Firebase 문서가 "Flutter 에서
최신 버전으로 올리면 의존성 관리자가 자동으로 SPM 으로 옮겨간다"고 적어뒀다.

즉 우리가 켜둔 우회는 **버전을 안 올려서 생긴 것이고, 10월 전에 올리면
사라진다.** 안 올리면 그 뒤로 Firebase 보안 패치를 못 받는다.

→ **firebase_* 업그레이드는 위생 문제가 아니라 기한 문제다.**

### 0.2 우리가 쓰는 Gemini 모델이 내려간다

코드에 박힌 값은 `gemini-2.0-flash` 다. 현재 Firebase AI Logic 문서 기준:

| 모델 | 상태 |
|---|---|
| `gemini-3.6-flash` | 현행 권장 |
| `gemini-3.5-flash`, `gemini-3.5-flash-lite` | 안정 |
| `gemini-2.5-*` | **2026년 10월 종료** |
| `gemini-2.0-*` | 목록에 없다 |

우리 값은 2.5보다도 이전이라 이미 안 되거나 곧 안 된다. 상담 화면이 조용히
실패 말풍선만 띄우게 된다 — 예외를 삼키고 있어서 화면은 안 죽지만 답도 안 나온다.

→ `gemini-3.6-flash` 로 바꾼다. 모델 ID 는 상수 하나다.

---

## 1. 지금 쓰는 것

### 1.1 `firebase_vertexai` → `firebase_ai` — 폐기됨

```
firebase_vertexai  0.2.3+4  (discontinued)  →  firebase_ai  3.15.0
```

**바꾼다.** 공식 마이그레이션 문서 기준 Dart 쪽 변경은 이게 전부다.

```dart
// 전
import 'package:firebase_vertexai/firebase_vertexai.dart';
FirebaseVertexAI.instance.generativeModel(model: ...)

// 후
import 'package:firebase_ai/firebase_ai.dart';
FirebaseAI.googleAI().generativeModel(model: 'gemini-3.6-flash')
```

백엔드가 Vertex AI 에서 Gemini Developer API 로 바뀐다(`FirebaseAI.googleAI()`).
Vertex 를 계속 쓰려면 `FirebaseAI.vertexAI()` 다. 우리는 Vertex 특유 기능을
안 쓰니 기본값으로 간다.

건드리는 파일은 `lib/data/service/ask_service.dart` 하나다. 화면은
`AskService` 인터페이스만 보고, 응답 계약(`{pick, reason, rows[]}`)과 카탈로그
대조는 그대로다.

### 1.2 `shared_preferences_android` — 보안 권고

```
GHSA-3hpf-ff72-j67p   심각도 low   취약: = 2.3.3   수정: 2.3.4
```

전이 의존성이다. `shared_preferences` 를 `^2.5.5` 로 올리면 2.4.27 로 따라
올라간다. **올린다.** 심각도는 낮지만 저장 계층이고 비용이 0 이다.

### 1.3 Firebase 메이저

```
firebase_core  3.6.0  →  4.13.0
firebase_auth  5.3.1  →  6.5.7
```

**올린다.** §0.1 이 이유다. 인증은 `AuthService` 뒤에 숨어 있어 화면은 안
건드린다. `test/unit/auth_service_test.dart` 가 Firebase 없는 빌드에서 안
터지는지 계속 지킨다.

올린 뒤 `pubspec.yaml` 의 `enable-swift-package-manager: false` 를 **걷어내고
iOS 빌드가 통과하는지 확인한다.** 통과하면 우회를 지운다.

### 1.4 `flutter_lints` 4.0.0 → 6.0.0

**올린다.** 지금 analyze 가 0 이라 늘어난 경고만 정리하면 된다.

### 1.5 나머지

`cupertino_icons`, `easy_localization`(3.0.7→3.0.8), `flutter_native_splash`,
`flutter_launcher_icons`, 전이 의존성 전부. **한 번에 올린다.**

`dio` 5.11.0, `flutter_riverpod` 3.4.2, `freezed` 3.2.5 는 이미 최신이다.

### 1.5b 나중에 들어온 것

P3 을 붙이면서 여섯 개가 더 들어왔다.

| 패키지 | 무엇에 | 어디서 쓰나 |
|---|---|---|
| `share_plus` 13.3.0 | 공유 시트 | `ShareService` |
| `app_links` 7.2.1 | `techpicks://` 수신 | `DeepLinkService` |
| `connectivity_plus` 7.3.1 | 오프라인 안내 | `ConnectivityService` |
| `firebase_remote_config` 6.5.6 | 카탈로그 주소·버전 | `RemoteConfigCatalogFeed` |
| `path_provider` 2.x | 받아둔 카탈로그 파일 | `FileCatalogStore` |
| `cloud_firestore` 6.8.0 | 관심 목록 동기화 | `FirestoreShortlistSync` |

전부 인터페이스 뒤에 있다. 화면과 테스트는 플러그인을 안 본다.

`url_launcher` 는 `share_plus` 가 전이로 끌고 왔다. P1.9(라이선스 링크)를
붙일 때 직접 선언하면 된다.

### 1.6 `easy_localization` — 지켜본다

| | |
|---|---|
| 마지막 안정 | 3.0.8, **12개월 전** |
| 진행 중 | 4.0.0-dev.0 |
| pub points | 140 |
| 업로더 | unverified |

바꾸지 않는다. 키가 144개고 잘 돌아간다. 다만 **테스트에서 위젯을 못 올린다** —
`EasyLocalization` 위젯을 트리에 올리면 `pumpAndSettle` 이 끝나지 않아 10분
타임아웃까지 간다. 그래서 앱 전체를 띄우는 테스트를 못 쓰고 루트 분기만 떼어
검사한다.

이게 커지면 `slang` 이나 Flutter 기본 `gen-l10n` 으로 옮기는 걸 검토한다.
지금은 우회가 문서화돼 있고 비용이 크지 않다.

---

## 2. 못 만든 기능

### 2.1 카메라 + OCR — 스캔

| 패키지 | 버전 | 판단 |
|---|---|---|
| `camera` | 0.12.0+2 | **쓴다.** Flutter 팀 공식 |
| `google_mlkit_text_recognition` | 0.16.0 | **쓴다.** 텍스트 인식만 |
| `permission_handler` | 13.0.0 | **쓴다.** `camera` 가 권한을 직접 요청하지 않는다 |
| `google_ml_kit` | 0.22.0 | 안 쓴다. 우산 패키지라 안 쓰는 모델까지 들어온다 |

**최소 버전이 올라간다.** 이게 가장 큰 부작용이다.

| | 현재 | ML Kit 요구 |
|---|---|---|
| iOS | 13.0 (빌드가 자동 상향한 값) | **15.5** |
| Android | — | minSdk 21 |

`camera` 자체는 iOS 13 / Android 24 면 되는데 ML Kit 이 iOS 15.5 를 요구한다.
iOS 15 미만 사용자를 버리는 결정이라 스캔 하나 때문에 감수할지 정해야 한다.

한국어 문자셋도 인식 대상에 들어 있다. 다만 우리가 읽는 건 모델 코드
(`SM-S931B`)라 라틴 문자면 충분하다. 비라틴 스크립트는 네이티브 빌드 파일에
따로 추가해야 하므로 **넣지 않는다.**

권한 문구도 필요하다 — `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`.

⚠️ **확인할 것:** ML Kit iOS 는 CocoaPods 로 배포된다. §0.1 대로 Firebase 를
SPM 으로 옮기면 한 프로젝트에 SPM 과 CocoaPods 가 섞인다. Flutter 는 이걸
지원하지만 실제로 빌드가 되는지 붙일 때 확인한다.

인식 결과를 카탈로그에 맞추는 부분(`ScanMatcher`, 임계값 0.5)은 이미 있고
테스트도 있다. 붙일 것은 **프리뷰 → 프레임 → 텍스트** 파이프라인뿐이다.

### 2.2 3D 뷰어 — **아무것도 안 넣는다**

| 후보 | 버전 | 판단 |
|---|---|---|
| `model_viewer_plus` | 1.10.0 | 안 쓴다. WebView 로 `<model-viewer>` 를 띄운다 |
| `flutter_3d_controller` | 2.3.0 | 안 쓴다. 같은 방식 |
| `flutter_scene` | 0.20.0 | **못 쓴다.** Flutter master 채널이 필요하다 |
| `three_js` | 0.3.0 | 안 쓴다. 0.x |

v2 의 전제가 **웹뷰를 없애는 것**이었다. v1 은 랭킹 3개와 3D 를 전부 웹뷰로
띄웠고 그걸 걷어내는 게 재구축의 시작이었다. 3D 하나 때문에 다시 들이면 그
결정을 되돌리는 셈이다.

유일한 네이티브 후보인 `flutter_scene` 은 스스로 "pre-1.0, 마이너 릴리스마다
호환성이 깨진다"고 적어뒀고 **Flutter GPU 가 stable 에 안 올라와서 master
채널을 써야 한다.** 채널을 바꾸는 건 3D 하나와 바꿀 일이 아니다.

게다가 모델 파일이 없다. 명세도 "3D models — Not supplied". 지금은 와이어프레임
대역으로 그리고 그 화면은 잘 돈다.

→ 모델을 실제로 받고 `flutter_scene` 이 stable 에 오면 다시 본다.

### 2.3 Google 로그인 — `google_sign_in` 7.2.0

**쓴다.** 다만 막고 있는 건 패키지가 아니라 `google-services.json` 의
`oauth_client` 가 비어 있는 것이다. Firebase 콘솔에서 실제 파일을 받는 게 먼저다.

7.x 는 6.x 에서 구조가 바뀌었다 — **인증과 인가가 분리됐다.**

```dart
GoogleSignIn.instance.initialize(clientId: ..., serverClientId: ...);
// 인증: authenticationEvents 스트림, attemptLightweightAuthentication()
// 인가: authorizationForScopes() / authorizeScopes() / authorizeServer()
```

새로 붙이는 거라 마이그레이션 부담은 없다. 우리는 인증만 필요하고 스코프 인가는
안 쓴다.

### 2.4 제품 사진 — 데이터가 **거짓말을 한다**

TechAPI 스마트폰 레코드에 `image_url` 이 있다. 카탈로그 10종 **전부** 채워져
있고 우리 DTO 도 이미 받아서 애셋에 굽고 있다.

```
image_url = https://cdn.jsdelivr.net/gh/GetTechAPI/images/smartphones/galaxy-s25-ultra.webp
```

**그런데 404 다.**

```
GetTechAPI/images 레포          → 404
jsDelivr 패키지 조회            → 404
raw.githubusercontent 직접      → 404
```

이미지 저장소 자체가 없다. 필드는 채워져 있는데 가리키는 곳이 비어 있다.

→ `cached_network_image` 를 그냥 붙이면 **모든 기기가 깨진 이미지로 보인다.**
지금 자리 표시자(`slotBg` 196px)를 두는 게 맞다.

붙일 때는 URL 이 실제로 200 인지 확인하는 단계를 `tool/build_catalog.dart` 에
넣는다. 그때 패키지는 `cached_network_image` 3.4.1 을 쓴다.

### 2.5 앱 버전 — `package_info_plus` 10.2.1

**쓴다.** 지금 You 화면 푸터의 `2.0.0` 이 코드 상수다. 테스트가 pubspec 과
어긋남을 잡고 있어서 급하지 않다. 우선순위 최하.

### 2.6 검색 — 패키지로 안 풀린다

TechAPI 는 정적 덤프다. 목록 인덱스가 19MB 에 점수도 없다.

브랜드별 샤딩도 없다. `brands/samsung/index.json` 을 받아 보면 브랜드 메타
정보(설명·로고·창립연도)만 있고 **그 브랜드의 기기 목록이 없다.**

→ 서버 쿼리가 필요하고 그건 **TechAPI 쪽 작업**이다. Algolia·Typesense 같은
외부 검색을 붙이는 것도 결국 색인을 서버에서 만들어야 한다.

> 곁가지: 브랜드 레코드에 `description_ko` 가 있다. TechAPI 가 한국어 데이터를
> 일부 갖고 있다는 뜻이라, 가격 현지화(§2.8)를 요청할 때 같이 물어볼 만하다.

### 2.7 다크 모드 — 패키지 아님

토큰이 없어서 막혔다. 디자인에서 다크 팔레트를 받아야 한다. `TpTokens` 에 자리는
있다.

### 2.8 가격 현지화 — 패키지 아님

`intl` 이 이미 있지만 소용없다. TechAPI 에 `msrp_usd` 뿐이고, 명세가 **환율
환산을 금지**한다("localised, not converted at runtime"). 원화 가격을 받아
카탈로그에 같이 구워야 한다.

---

## 3. 안 넣기로 한 것

| 패키지 | 왜 |
|---|---|
| `go_router` | 딥링크 요구가 없고 back stack 이 한 단계다 |
| `drift` | 목록 인덱스가 19MB 라 로컬 DB 계획이 무산됐다 |
| `fl_chart` | 확정 디자인에 차트가 없다 |
| `webview_flutter` | v2 가 없애려던 것이다 (§2.2) |
| `rive`, `video_player` | v1 잔재. 확정 디자인에 없다 |
| `restart_app` | 언어 전환이 즉시 반영으로 바뀌었다 |
| `google_ml_kit` (우산) | 안 쓰는 모델까지 들어온다 (§2.1) |
| Riverpod code-gen | build_runner 를 하나 더 태울 이유가 없다 |

---

## 4. 순서

앞의 것이 뒤의 것을 막는다.

| # | 무엇 | 기한 |
|---|---|---|
| 1 | 전체 버전 올리기 + 보안 권고 | — |
| 2 | `firebase_ai` 이주 + 모델 ID `gemini-3.6-flash` | **10월** (§0.2) |
| 3 | Firebase 메이저 + SPM 우회 걷기 | **10월** (§0.1) |
| 4 | `google-services.json` 교체 → `google_sign_in` | — |
| 5 | iOS 최소 버전 결정 → 카메라 + OCR | — |
| 6 | 이미지 저장소 확보 → `cached_network_image` | — |
| 7 | `package_info_plus` | — |

1–3 은 10월 전에 끝내야 한다. 4–7 은 밖에서 뭔가 들어와야 시작된다.

3D·검색·다크 모드·가격은 이 목록에 없다. 패키지로 풀리는 문제가 아니다.

---

## 5. 밖에 요청할 것

우리가 못 정하는 것들이다.

| 대상 | 필요한 것 |
|---|---|
| Firebase 콘솔 | `oauth_client` 가 채워진 `google-services.json`, iOS 용 `GoogleService-Info.plist` |
| 디자인 | 다크 모드 토큰 한 벌 |
| 디자인 | 제품 사진 (3:2, 밝은 중성 바탕, 그림자 없음) 또는 3D 모델 |
| TechAPI | 이미지 저장소 — `image_url` 이 404 다 (§2.4) |
| TechAPI | 원화 가격 필드 |
| TechAPI | 검색 또는 브랜드별 목록 (§2.6) |
| 제품 결정 | iOS 최소 버전을 15.5 로 올릴지 (§2.1) |

---

## 6. 확인 방법

메이저 업그레이드는 화면이 아니라 경계에서 검증한다.

| 대상 | 테스트 |
|---|---|
| 인증 | `test/unit/auth_service_test.dart` |
| 상담 | `test/unit/ask_service_test.dart` |
| 저장 | `test/unit/persistence_test.dart` |
| 전체 | `flutter test` 438건, `flutter analyze` 0 |

올린 뒤 **iOS·Android 양쪽에서 실제로 띄워봐야 한다.** 지금까지 iOS 빌드를
깨뜨린 것들은 전부 테스트가 못 잡는 종류였다 — CocoaPods 미설치, SPM 충돌,
없는 plist 참조.

---

## 출처

- [Firebase: Migrate from CocoaPods](https://firebase.google.com/docs/ios/cocoapods-deprecation)
- [Firebase AI Logic: 최신 SDK 로 이주](https://firebase.google.com/docs/ai-logic/migrate-to-latest-sdk)
- [Firebase AI Logic: 모델 목록](https://firebase.google.com/docs/ai-logic/models)
- [firebase_ai](https://pub.dev/packages/firebase_ai) · [google_sign_in](https://pub.dev/packages/google_sign_in) · [camera](https://pub.dev/packages/camera)
- [google_mlkit_text_recognition](https://pub.dev/packages/google_mlkit_text_recognition) · [flutter_scene](https://pub.dev/packages/flutter_scene) · [easy_localization](https://pub.dev/packages/easy_localization)
- [GHSA-3hpf-ff72-j67p](https://github.com/advisories/GHSA-3hpf-ff72-j67p)
