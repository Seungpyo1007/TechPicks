# 실행 계획

2026-08-10 작성. `DEPENDENCIES.md`(지금 쓰는 것)와 `PLUGIN_RESEARCH.md`(넣을 만한 것)의
결론을 **언제 무엇을 하는가**로 묶는다.

여기 적힌 숫자는 대부분 오늘 실제로 돌려서 잰 것이다. 추정한 것은 그렇다고 표시했다.

---

## 0. 오늘 실측한 것

계획이 기대는 가정을 먼저 검증했다. **가장 큰 걱정이던 업그레이드가 실제로는 작다.**

### 0.1 Firebase 메이저 + firebase_ai 이주 — 검증 완료

임시로 올려서 돌려봤다.

```
firebase_core  3.6.0 → ^4.13.0
firebase_auth  5.3.1 → ^6.5.7
firebase_vertexai → firebase_ai ^3.15.0
shared_preferences → ^2.5.5   (보안 권고 해소)
flutter_lints  4.0.0 → ^6.0.0
```

| 항목 | 결과 |
|---|---|
| 의존성 해결 | **깨끗하다.** 충돌 없음, 17개 변경 |
| 깨진 코드 | **한 파일, 에러 8개** (`ask_service.dart`) |
| 고치는 데 든 것 | **4줄** — import, 클래스명, 생성자, 모델 ID |
| 이주 후 analyze | **에러 0** |
| 테스트 | **438건 전부 통과** |
| flutter_lints 6 여파 | info 9건 (`unnecessary_underscores` 7, 불필요 import 2) |
| lint 고친 뒤 | **이슈 0**, 테스트 438건 통과 |

실제 변경은 이게 전부였다.

```dart
- import 'package:firebase_vertexai/firebase_vertexai.dart';
+ import 'package:firebase_ai/firebase_ai.dart';

- static const String modelId = 'gemini-2.0-flash';
+ static const String modelId = 'gemini-3.6-flash';

- _model ??= FirebaseVertexAI.instance.generativeModel(
+ _model ??= FirebaseAI.googleAI().generativeModel(
```

→ **"메이저 두 단계"라는 말이 주는 인상보다 훨씬 작다.** 반나절이면 끝난다.

### 0.2 Android 타깃 SDK — 이미 충족

`android/app/build.gradle` 이 `flutter.targetSdkVersion` 을 그대로 쓴다.
Flutter 3.44 의 값은 **36** 이다 (`FlutterExtension.kt` 확인).

→ 8월 31일 Play 요건(API 36)은 **이미 만족한다.** 할 일 없음.

### 0.3 SPM 우회는 걷을 수 있다 — 대신 iOS 15.0

우회를 지우고 빌드했더니 SPM 통합 자체는 **성공**한다. `pod install` 도 돌고
Xcode 빌드도 시작된다. 걸린 건 다른 것이었다.

```
The package product 'firebase-core' requires minimum platform version 15.0
for the iOS platform, but this target supports 13.0
```

**Firebase 4.x / 6.x 가 iOS 15.0 이상을 요구한다.** 우리 배포 타깃은 13.0 이었다
(오늘 Flutter 가 12.0 에서 자동으로 올린 값).

→ `Podfile` 과 `project.pbxproj` 를 15.0 으로 올리면 된다. 확인 중.

**이게 계획을 하나 바꾼다.** ML Kit 이 iOS 15.5 를 요구해서 "스캔 때문에 최소
버전을 크게 올려야 한다"고 봤는데, **Firebase 를 올리는 순간 어차피 15.0 이
된다.** 실제 간극은 13.0 → 15.5 가 아니라 **15.0 → 15.5** 다.

스캔의 비용이 생각보다 훨씬 작다.

---

## 1. 달력

밖에서 정해진 기한이다. 우리가 못 미룬다.

| 날짜 | 무슨 일 | 우리 상태 |
|---|---|---|
| **2026-08-31** | Play 신규 앱 API 36 필수 | ✅ 이미 36 (§0.2) |
| **2026-10** | Firebase 가 CocoaPods 발행 중단 | ⚠️ 버전을 올려야 한다 |
| **2026-10** | Gemini 2.5 계열 종료 | ⚠️ 우리는 2.0 을 쓴다 |
| **2026-12** | CocoaPods 레지스트리 읽기 전용 | ⚠️ 위와 같음 |

10월 항목 둘은 §0.1 로 이미 검증됐다. **남은 건 실제로 커밋하는 것뿐이다.**

---

## 2. 단계

### P0 — 마감 대응 (반나절, 검증 완료)

| # | 무엇 | 근거 |
|---|---|---|
| P0.1 | 버전 일괄 상향 + `shared_preferences` 보안 권고 | GHSA-3hpf-ff72-j67p |
| P0.2 | `firebase_vertexai` → `firebase_ai`, 모델 ID `gemini-3.6-flash` | 폐기 + 10월 종료 |
| P0.3 | `flutter_lints` 6 경고 9건 정리 | — |
| P0.4 | SPM 우회 제거 시도 → iOS 빌드 확인 | 10월 CocoaPods 중단 |

전부 §0.1 에서 돌려봤다. **P0 는 위험이 거의 없다.**

`gemini-3.6-flash` 는 실제 호출로 확인이 필요하다. 지금 상담은
`LocalAskService` 가 기본이라 Gemini 경로는 테스트가 안 탄다.

### P1 — 출시를 막는 것 (외부 입력 필요)

**하나라도 빠지면 스토어에 못 낸다.**

| # | 무엇 | 막고 있는 것 |
|---|---|---|
| ✅ P1.1 | `google_sign_in` + `sign_in_with_apple` | **심사 지침 4.8.** Google 을 제공하면 필수 |
| ✅ P1.2 | Facebook 버튼 — **뺐다** | 제품 판단 |
| ✅ P1.3 | `applicationId` / 번들 ID → `com.techpicks.app` | Play 가 `com.example.*` 를 거부했다 |
| ✅ P1.4 | Android 릴리스 서명 배선 | 키스토어는 사용자 것 |
| P1.5 | `google-services.json` 교체 (`oauth_client: []`) | Firebase 콘솔 |
| P1.6 | `GoogleService-Info.plist` (지금 없음) | Firebase 콘솔 |
| ✅ P1.7 | `ios/Runner/PrivacyInfo.xcprivacy` 작성 | 앱 자체 매니페스트가 없다 |
| P1.8 | 개인정보 처리방침 URL, 지원 URL | 스토어 등록 항목 |
| ✅ P1.9 | `url_launcher` — CC-BY-SA 표기가 링크가 아니다 | 라이선스 의무 |

P1.3–P1.6 은 코드가 아니라 **계정·콘솔 작업**이다. 우리가 못 한다.

**P1 의 코드는 다 끝났다.** 남은 것은 콘솔·계정 작업뿐이다.

#### 릴리스 서명은 키스토어만 꽂으면 된다

`android/key.properties` 가 있으면 그 키로 서명하고, 없으면 지금처럼 디버그
키로 떨어진다. 키스토어가 없는 사람도 `flutter run --release` 가 되게 하려는
것이다. **디버그 키로 서명된 것은 Play 가 거부한다** — 올리기 전에 파일이
있는지 확인할 것.

```bash
keytool -genkeypair -v -keystore ~/techpicks-upload.jks -storetype PKCS12 \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

```properties
# android/key.properties — .gitignore 대상이다
storeFile=/Users/<이름>/techpicks-upload.jks
storePassword=...
keyAlias=upload
keyPassword=...
```

던져 만든 키로 실제 서명이 붙는 것까지 확인했다 (`apksigner verify` 로 DN 확인).
**키스토어를 잃어버리면 그 앱은 다시 못 올린다.** 백업할 것.

Google·Apple 로그인은 붙였지만 **설정 없이는 안 돈다.**

| 무엇 | 어디서 |
|---|---|
| `oauth_client` 가 채워진 `google-services.json` | Firebase 콘솔 (Android SHA-1 등록 포함) |
| `GoogleService-Info.plist` | Firebase 콘솔 |
| App ID 에 Sign in with Apple 켜기 | Apple Developer |
| Firebase 콘솔에서 Google·Apple 로그인 공급자 켜기 | Firebase 콘솔 |

`ios/Runner/Runner.entitlements` 는 넣어뒀다. Apple Developer 에서 기능을
안 켜면 **실기기 서명이 실패한다** — 시뮬레이터는 서명을 안 해서 그대로 뜬다.

Facebook 은 뺐다. 개발자 계정과 앱 심사가 따로 필요한데 그걸 치를 만큼 쓰일
거라고 볼 근거가 없었다. 나중에 붙이려면 버튼·번역 키·로고를 되살리면 된다
(`78f8d4f` 참고).

### P1.5 — v1 잔재 정리 (한 시간, 지금 가능)

조사하다 나왔다. **안 쓰는 권한을 선언하고 있다.**

| 파일 | 남아 있는 것 | 왜 문제인가 |
|---|---|---|
| `AndroidManifest.xml` | `ACCESS_FINE_LOCATION` | 코드가 위치를 안 쓴다. v1 랭킹 웹뷰가 요구하던 것 |
| `Info.plist` | `NSLocationWhenInUseUsageDescription` | 위와 같음 |
| `Info.plist` | `NSPhotoLibrary*UsageDescription` ×2 | 사진 라이브러리를 안 쓴다 |

v2 가 웹뷰를 걷어내면서 없앤 게 위치 권한이었는데 **선언만 살아남았다.**
Play 데이터 안전 섹션에서 위치를 신고해야 하고, 심사에서 "왜 위치를 받나"를
묻는다. 안 쓰는 권한은 빼는 게 맞다.

카메라·마이크는 스캔을 붙일 때 쓰므로 남긴다.

### P2 — 안 보이는 것을 보이게 (1–2일)

| # | 무엇 | 왜 |
|---|---|---|
| ✅ P2.1 | `firebase_crashlytics` + 삼킨 자리 11군데에 non-fatal 기록 | 실패가 프로덕션에서 안 보인다 |
| ✅ P2.2 | `firebase_analytics` — 가중치·관심목록·비교·상담·축 전환 | 핵심 가설이 검증 안 됐다 |
| ~~P2.3~~ | ~~`riverpod_lint`~~ | **막혔다** — 아래 참고 |
| ✅ P2.4 | `animations` 로 손으로 짠 shared axis 대체 | 93줄 삭제, 공식 구현 |

P2.1 이 가장 값이 크다. **P1 보다 먼저 해도 된다** — 출시 전에 넣어야 첫날부터
보인다.

#### P2.3 은 지금 못 넣는다

넣어보니 의존성이 안 풀린다. `analyzer` 버전이 서로 안 맞는다.

| 패키지 | 요구하는 analyzer |
|---|---|
| `custom_lint` 0.8.1 | `^8.0.0` |
| `riverpod_lint` 3.1.8 | `^13.0.0` |
| `json_serializable` 6.14.1 | `>=10.0.0 <15.0.0` |

`riverpod_lint` 가 `custom_lint` 위에서 도는데 둘의 analyzer 요구가 다섯 단계
어긋나 있고, 우리가 쓰는 `json_serializable`·`freezed` 는 10 이상을 요구한다.
어느 조합으로도 안 풀린다.

→ `custom_lint` 가 analyzer 10 이상을 지원할 때까지 **보류.** 그때까지는
`await` 뒤 `ref.mounted` 를 사람이 봐야 한다.

### P3 — 제품 기능 (1–2주, 추정)

| # | 무엇 | 먼저 정할 것 |
|---|---|---|
| ✅ P3.1 | `share_plus` + `app_links` | 공유 문구, `techpicks://` |
| ✅ P3.2 | `firebase_remote_config` 로 카탈로그 전달 | URL 만 내려준다 |
| ✅ P3.3 | `connectivity_plus` 오프라인 안내 | 문구 |
| ✅ P3.4 | 골든 테스트 — `alchemist` 없이 `matchesGoldenFile` | 아래 참고 |
| ✅ P3.5 | `cloud_firestore` 관심 목록 동기화 | 로컬 우선, 문서 단위 LWW |

P3.2 로 명세의 "스토어 배포 없이 점수 갱신"이 달성됐다. **다만 콘솔에서
값을 넣어야 실제로 돈다.**

| Remote Config 키 | 무엇 |
|---|---|
| `catalog_url` | 카탈로그 JSON 주소. 비어 있으면 애셋을 쓴다 |
| `catalog_version` | 애셋(`assets/catalog/v1.json`)의 `version` 보다 클 때만 받는다 |

JSON 을 어디에 올릴지는 아직 안 정했다. 도메인이 없으니 지금은 GitHub Pages
가 제일 싸다. 코드는 주소만 받으므로 나중에 옮겨도 값 하나만 바꾸면 된다.

Firestore 보안 규칙도 콘솔 작업이다 — `users/{uid}` 아래는 본인만.

#### P3.4 는 alchemist 없이 넣었다

유리 크롬이 골든에서 안정적인지가 관건이었다. 화면 11종을 두 크롬으로 구워
같은 기계에서 세 번 돌렸고 **PNG 24장이 매번 바이트까지 같았다.** 블러도
그림자도 흔들리지 않는다.

`alchemist` 를 안 쓴 이유는 그것이 주는 게 여기서는 이미 공짜라서다. 핵심
기능이 글자를 블록으로 그려 폰트 차이를 지우는 것인데, `flutter test` 는
폰트를 안 실으면 어차피 Ahem 으로 그린다 — 구운 이미지의 글자가 전부
검은 블록이다. 나머지는 시나리오 격자와 CI/플랫폼 골든 분리인데, 격자는
위젯을 나열하면 되고 CI 는 지금 안 돈다.

대신 **macOS 밖에서는 건너뛴다.** 렌더링은 OS 가 다르면 미세하게 다르다.
리눅스 CI 에서 돌리려면 그때 이미지를 고정하고 그 안에서 다시 구워야 한다.

```
flutter test test/golden --update-goldens   # 기준선 다시 굽기
```

### P4 — 밖에서 뭔가 와야 시작

| 무엇 | 기다리는 것 |
|---|---|
| Laptops 화면 | 노트북 점수 데이터 (TechAPI 1,951종에 점수 0) |
| 제품 사진 | 이미지 저장소 (`image_url` 이 전부 404) |
| 가격 현지화 | 원화 가격 필드 |
| 다크 모드 | 디자인 토큰 한 벌 |
| 검색 | 서버 쿼리 또는 브랜드별 목록 |
| 알림 | 서버가 순위를 계산해 푸시 |
| 카메라·OCR | iOS 최소 15.5 로 올릴지 제품 판단 |
| 3D | 모델 파일 + `flutter_scene` 이 stable 에 오기 |

---

## 3. 출시 체크리스트

P1 을 실행 순서로 편 것이다.

**콘솔·계정**
- [ ] 번들 ID / applicationId 확정
- [ ] Firebase 프로젝트에 그 ID 로 앱 등록
- [ ] `google-services.json` 재발급 (`oauth_client` 채워짐)
- [ ] `GoogleService-Info.plist` 내려받아 `ios/Runner/` 에
- [ ] Apple Developer 에서 Sign in with Apple 활성화
- [ ] Android 릴리스 키스토어 생성 + `key.properties`
- [ ] 개인정보 처리방침 게시, URL 확보

**코드**
- [ ] `sign_in_with_apple` 붙이기
- [ ] Facebook 붙이거나 버튼 빼기
- [ ] `ios/Runner/PrivacyInfo.xcprivacy` 작성
- [ ] 안 쓰는 권한 선언 제거 (위치, 사진)
- [ ] `url_launcher` 로 라이선스·정책 링크
- [ ] `applicationId` / `PRODUCT_BUNDLE_IDENTIFIER` 교체
- [ ] 릴리스 서명 설정

**확인**
- [ ] `flutter build ipa` / `flutter build appbundle` 통과
- [ ] 실기기에서 로그인 4종 동작
- [ ] Play 데이터 안전 · App Privacy 문항 작성

---

## 4. 위험

| 위험 | 크기 | 대응 |
|---|---|---|
| `gemini-3.6-flash` 실제 호출이 안 됨 | 중 | Gemini 경로는 테스트가 안 탄다. 실기기로 한 번 확인 |
| SPM 을 켜면 ML Kit(CocoaPods)과 섞임 | 중 | 스캔 붙일 때 확인. Flutter 는 혼용을 지원한다 |
| Apple 로그인이 심사에서 또 걸림 | 중 | 4.8 은 조건이 명확하다. 붙이면 해소 |
| 유리 크롬 골든이 환경마다 달라짐 | 낮 | 한 기계에서는 바이트까지 같다. macOS 밖에서는 건너뛴다 |
| `easy_localization` 이 정체됨 | 낮 | 안정판이 12개월 전. 지금 문제 없음, 지켜본다 |
| lint 도구가 analyzer 를 못 따라옴 | 낮 | `riverpod_lint` 가 그래서 막혔다. 코드 생성 쪽이 더 빠르다 |
| iOS 15.5 로 올려 사용자를 잃음 | 낮 | 스캔을 포기하면 안 올려도 된다 |
| TechAPI 가 멈춤 | 낮 | 카탈로그가 애셋이라 앱은 계속 돈다 |

---

## 5. 순서 요약

```
지금 ────────────────────────────────────────────────
  ✅ P0  마감 대응          완료 (6fc95c6)
  ✅ P1.5 v1 권한 잔재 정리  완료 (732c250)
  ✅ P2.4 animations 교체    완료 (732c250)
  ⛔ P2.3 riverpod_lint      막힘 — analyzer 버전 충돌
  ✅ P2.1 Crashlytics        완료 (af11ca8)
  ✅ P2.2 Analytics          완료 (af11ca8)
  ✅ P3.4 골든 테스트        완료 — PNG 24장
  ✅ P3.1 공유 + 딥링크      완료 — techpicks://
  ✅ P3.2 Remote Config      완료 — 콘솔 값 대기
  ✅ P3.3 오프라인 안내      완료
  ✅ P3.5 Firestore 동기화   완료 — 로그인 후 확인 필요
  ✅ P1.7 개인정보 매니페스트 완료 — 번들에 들어간 것까지 확인
  ✅ P1.9 출처·라이선스 링크  완료
  ✅ P1.1 Google·Apple 로그인 완료 — 콘솔 설정 대기
  ✅ P1.2 Facebook            뺐다
  ✅ P1.4 릴리스 서명 배선     완료 — 키스토어 대기

콘솔 작업이 들어오면 ────────────────────────────────
  P1  출시 요건            2–3일    ← 스토어 제출 가능

데이터가 오면 ──────────────────────────────────────
  P4  막힌 것들
```

**P0 · P1.5 · P2 · P3 가 끝났다.** 코드로 할 수 있는 것은 남아 있지 않다.

남은 것은 전부 콘솔·계정 작업이다.

- **P1 출시 요건** — 이게 되면 스토어에 낼 수 있다
- **Remote Config 값과 카탈로그 호스팅** — P3.2 가 실제로 도는 조건
- **Firestore 보안 규칙** — P3.5 가 실제로 도는 조건

---

## 출처

- [Play 타깃 API 요건](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Firebase CocoaPods 종료](https://firebase.google.com/docs/ios/cocoapods-deprecation)
- [Firebase AI Logic 모델](https://firebase.google.com/docs/ai-logic/models)
- [App Store 심사 지침 4.8](https://developer.apple.com/app-store/review/guidelines/)
- [Apple 개인정보 매니페스트 요건](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)
