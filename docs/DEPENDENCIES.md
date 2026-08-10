# 의존성 결정

2026-08-10 기준. 지금 쓰는 패키지를 어떻게 할지, 아직 못 만든 기능에 무엇을 쓸지
정한다. 버전은 pub.dev API 로 그날 직접 조회했다.

---

## 1. 지금 당장 손봐야 하는 것

### 1.1 `firebase_vertexai` — 폐기됨

```
firebase_vertexai  0.2.3+4  (discontinued)  →  firebase_ai  3.15.0
```

pub.dev 가 폐기 표시를 달았고 후속이 `firebase_ai` 다. **바꾼다.**

상담 화면이 이걸 쓴다. 우리가 만지는 표면은 좁다 — 모델 하나 만들고
`generateContent` 한 번 부르고 텍스트를 받는다. `GeminiAskService` 안에 다
들어 있고 화면은 `AskService` 인터페이스만 본다. 갈아 끼우는 범위가 파일 하나다.

응답 계약(`{pick, reason, rows[]}`)과 카탈로그 대조는 그대로 둔다.

### 1.2 `shared_preferences_android` — 보안 권고

```
GHSA-3hpf-ff72-j67p  심각도 low  취약: = 2.3.3  수정: 2.3.4
현재 2.3.3 → 2.4.27 로 올린다
```

직접 의존이 아니라 `shared_preferences` 를 타고 들어온 것이다. 상위를
`^2.5.5` 로 올리면 같이 해결된다. **올린다.**

낮은 심각도지만 저장 계층이고 고치는 비용이 0 이다.

### 1.3 Firebase 메이저 업그레이드

```
firebase_core  3.6.0  →  4.13.0
firebase_auth  5.3.1  →  6.5.7
```

**올린다.** 이유가 하나 더 있다 — `firebase_core 3.6.0` 이 Flutter 3.44 의
Swift Package Manager 를 못 따라와서 iOS 빌드가 통째로 깨졌다. 지금은
`pubspec.yaml` 에서 SPM 을 꺼서 우회하고 있는데, Flutter 는 이걸 곧 강제한다고
경고한다. 4.x 로 올리면 그 우회를 걷어낼 수 있는지 확인한다.

메이저 두 단계라 API 변경이 있다. 인증은 `AuthService` 뒤에 숨어 있어서 화면은
안 건드린다.

### 1.4 `flutter_lints` 4.0.0 → 6.0.0

**올린다.** 새 규칙이 붙으면 경고가 늘어날 수 있지만, 지금 `flutter analyze` 가
0 이라 늘어난 만큼만 정리하면 된다.

### 1.5 자잘한 것

`cupertino_icons`, `easy_localization`(3.0.7→3.0.8), `flutter_native_splash`,
`flutter_launcher_icons`, 그 밖의 전이 의존성. **한 번에 올린다.**

`dio`, `flutter_riverpod`, `freezed` 는 이미 최신이다.

---

## 2. 못 만든 기능에 쓸 것

### 2.1 카메라 + OCR — 스캔 화면

| 후보 | 판단 |
|---|---|
| `camera` 0.12.0+2 | **쓴다.** Flutter 팀 공식. 대안이 없다 |
| `google_mlkit_text_recognition` 0.16.0 | **쓴다.** 글자 인식만 |
| `google_ml_kit` 0.22.0 | 안 쓴다. 우산 패키지라 안 쓰는 모델까지 다 들어와 앱이 커진다 |
| Apple Vision 직접 | 안 쓴다. 플랫폼 채널을 양쪽에 따로 짜야 한다 |

v1 도 `google_ml_kit` 을 썼는데 그건 우산 쪽이었다. 명세가 요구하는 건
"뒷면 모델명 읽기" 하나뿐이라 텍스트 인식 모듈만 가져온다.

`permission_handler` 13.0.0 도 같이 필요하다 — 카메라 권한. v1 이 10.x 를
쓰다가 제거된 `PluginRegistry.Registrar` 때문에 빌드가 깨졌던 그 패키지다.
이번엔 13.x 로 넣는다.

인식 결과를 카탈로그에 맞추는 부분(`ScanMatcher`, 임계값 0.5)은 이미 있다.
붙일 것은 **카메라 프리뷰 → 프레임 → 텍스트** 파이프라인뿐이다.

### 2.2 3D 뷰어 — **아무것도 안 넣는다**

| 후보 | 판단 |
|---|---|
| `model_viewer_plus` 1.10.0 | 안 쓴다. WebView 로 `<model-viewer>` 웹 컴포넌트를 띄운다 |
| `flutter_3d_controller` 2.3.0 | 안 쓴다. 같은 방식 |
| `flutter_scene` 0.20.0 | 보류. 네이티브(Impeller)지만 0.x 이고 API 가 아직 움직인다 |
| `three_js` 0.3.0 | 보류. 0.x |

v2 의 전제가 **웹뷰를 없애는 것**이었다. v1 은 랭킹 3개와 3D 를 전부 웹뷰로
띄웠고 그걸 걷어내는 게 이번 재구축의 시작이었다. 3D 하나 때문에 웹뷰를 다시
들이면 그 결정을 되돌리는 셈이다.

게다가 **모델 파일이 없다.** 명세도 "3D models — Not supplied" 다. 지금은
와이어프레임 대역으로 그리고 있고 그 화면은 잘 돌아간다.

모델을 실제로 받게 되면 그때 `flutter_scene` 성숙도를 다시 본다. 그 전에는
결정할 근거가 없다.

### 2.3 Google 로그인 — `google_sign_in` 7.2.0

**쓴다.** 다만 **패키지가 문제가 아니다.** `google-services.json` 의
`oauth_client` 가 비어 있어서 막힌 것이고, Firebase 콘솔에서 실제 파일을 받아야
한다. 패키지는 그 다음이다.

7.x 는 6.x 에서 API 가 크게 바뀌었다(초기화·인증 흐름 분리). 새로 붙이는
거라 마이그레이션 부담은 없다.

### 2.4 제품 사진 — `cached_network_image` 3.4.1

**쓴다.** 상세 화면의 196px 자리와 목록 썸네일. 사진 URL 이 생기면 그때
넣는다. 지금은 넣을 이미지가 없다.

명세가 "3:2, 밝은 중성 바탕, 그림자 없음" 이라고만 적어뒀고 파일은 안 왔다.

### 2.5 앱 버전 — `package_info_plus` 10.2.1

**쓴다.** 지금 You 화면 푸터의 `2.0.0` 이 코드 상수다. pubspec 과 어긋나지
않게 테스트로 묶어놨지만, 빌드에서 직접 읽는 게 맞다.

우선순위는 낮다. 테스트가 이미 어긋남을 잡는다.

### 2.6 검색 — 패키지로 해결되지 않음

카탈로그 10종 밖을 찾는 문제다. TechAPI 목록 인덱스가 19MB 에 점수도 없어서
클라이언트에서 못 한다. 서버 쿼리나 브랜드별 샤딩이 필요하고, 그건
**TechAPI 쪽 작업**이지 패키지 선택이 아니다.

### 2.7 다크 모드 — 패키지 아님

토큰이 없어서 막힌 것이다. 디자인에서 다크 팔레트를 받아야 한다.
`TpTokens` 에 자리는 이미 있다.

### 2.8 가격 현지화 — 패키지 아님

`intl` 이 이미 들어와 있지만 소용없다. TechAPI 에 `msrp_usd` 밖에 없고,
명세가 **환율 환산을 금지**한다("localised, not converted at runtime").
원화 가격을 받아 카탈로그에 같이 구워야 한다.

---

## 3. 안 넣기로 한 것

| 패키지 | 왜 |
|---|---|
| `go_router` | 딥링크 요구가 없고 back stack 이 한 단계다 |
| `drift` | 목록 인덱스가 19MB 라 로컬 DB 계획 자체가 무산됐다 |
| `fl_chart` | 확정 디자인에 차트가 없다 |
| `webview_flutter` | v2 가 없애려던 것이다 (§2.2) |
| `rive` | v1 잔재. 확정 디자인에 Rive 애니메이션이 없다 |
| `video_player` | 같은 이유 |
| `restart_app` | 언어 전환이 즉시 반영으로 바뀌어 필요 없다 |
| Riverpod code-gen | build_runner 를 하나 더 태울 이유가 없다 |

---

## 4. 하는 순서

앞의 것이 뒤의 것을 막는다.

| # | 무엇 | 이유 |
|---|---|---|
| 1 | 전체 버전 올리기 + 보안 권고 | 비용이 낮고 나머지의 바탕이 된다 |
| 2 | `firebase_vertexai` → `firebase_ai` | 폐기된 패키지를 계속 두면 안 된다 |
| 3 | Firebase 메이저 + SPM 우회 걷기 | 2 와 같이 움직인다 |
| 4 | `google-services.json` 교체 → `google_sign_in` | 파일이 먼저다 |
| 5 | `camera` + `google_mlkit_text_recognition` + `permission_handler` | 스캔이 완성된다 |
| 6 | 사진 URL 확보 → `cached_network_image` | 이미지가 먼저다 |
| 7 | `package_info_plus` | 급하지 않다 |

3D 와 검색·다크 모드·가격은 이 목록에 없다. 패키지로 풀리는 문제가 아니다.

---

## 5. 확인 방법

메이저 업그레이드는 화면이 아니라 경계에서 검증한다.

- 인증 → `test/unit/auth_service_test.dart` (Firebase 없는 빌드에서 안 터지는지)
- 상담 → `test/unit/ask_service_test.dart` (카탈로그 대조, 응답 계약)
- 저장 → `test/unit/persistence_test.dart`
- 전체 → `flutter test` 438건, `flutter analyze` 0

올린 뒤 iOS·Android 양쪽에서 실제로 띄워봐야 한다. 지금까지 iOS 빌드를 깨뜨린
것들은 전부 테스트가 못 잡는 종류였다 (CocoaPods, SPM, 없는 plist 참조).
