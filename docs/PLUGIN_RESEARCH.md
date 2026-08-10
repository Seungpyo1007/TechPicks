# 이 앱에 보탬이 될 플러그인

2026-08-10 조사. **지금 쓰는 의존성을 어떻게 할지는 `DEPENDENCIES.md`.**
여기는 반대로 — 아직 안 쓰는 것 중에 이 앱에 값을 더할 게 뭔지 찾는다.

버전은 pub.dev API 로, 동작과 요건은 공식 문서로 그날 확인했다.

---

## 판단 기준

이 앱이 어떤 앱인지에 비춰서 본다.

1. **결정을 돕는 앱이다.** 사람들은 결정 전에 남에게 물어본다
2. **예외를 의도적으로 삼킨다.** 실패해도 화면이 안 죽는 게 설계다
3. **핵심 가설이 검증 안 됐다.** "지수는 사용자가 정한다"가 맞는지 모른다
4. **확정 디자인을 그대로 구현한 프로젝트다.** 값이 명세에 박혀 있다
5. **플랫폼 분기를 화면 코드에 두지 않는다.** 토큰만 갈아 끼운다
6. **웹뷰를 안 쓴다.** v2 가 없애려던 것이다

5·6 을 어기는 패키지는 기능이 좋아도 안 쓴다.

---

## A. 출시를 막는 것

### A.1 `sign_in_with_apple` 8.1.0 — **App Store 심사 요건**

App Store 심사 지침 **4.8** 은 이렇게 적는다.

> 제3자 또는 소셜 로그인(Facebook Login, Google Sign-In 등)으로 사용자의
> 기본 계정을 만들거나 인증하는 앱은, **동등한 선택지로 다음 조건을 갖춘 다른
> 로그인 서비스도 제공해야 한다** — 이름과 이메일만 수집하고, 이메일을
> 비공개로 유지할 수 있게 하며, 광고 목적으로 앱 내 상호작용을 수집하지 않을 것.

우리 로그인 화면에는 Google 과 Facebook 버튼이 있다. 예외 다섯 가지 중 어디에도
해당하지 않는다(회사 자체 계정만 쓰는 것도 아니고, 교육·기업용도 아니다).

이메일 로그인이 대체가 되는지 따져보면 **안 된다.** 조건 두 번째인 "이메일을
비공개로 유지"를 못 준다. Apple 의 비공개 이메일 릴레이가 그 조건을 만족하는
표준 수단이다.

지금 로그인 화면에 **Apple 버튼이 이미 있는데 누르면 "연결되지 않았습니다"만
뜬다.** 이건 미완성 기능이 아니라 **심사 반려 사유**다.

→ 스토어에 낼 거면 필수. Google 을 뺄 게 아니라면 피할 방법이 없다.

### A.2 `flutter_facebook_auth` 7.2.0 — 결정이 필요하다

Facebook 버튼도 죽어 있다. 선택지는 둘이다.

- 붙인다 → A.1 도 반드시 같이
- **버튼을 뺀다** → 로그인 제공자가 줄어 화면이 단순해진다

명세가 다섯 버튼을 못박았지만, 안 되는 버튼을 남겨두는 것보다 낫다. 제품
판단이 필요하다.

---

## B. 안 보이는 것을 보이게

### B.1 `firebase_crashlytics` 5.2.7 — **가장 값이 크다**

이 코드베이스는 예외를 **일부러 삼킨다.** 세어보면 15군데다.

| 파일 | 삼키는 것 |
|---|---|
| `auth_service.dart` | 로그인·가입·로그아웃·현재 사용자 (5) |
| `catalog_repository.dart` | 애셋 읽기·파싱 (2) |
| `tech_api_repository.dart` | 원격 조회 (2) |
| `providers.dart` | 카탈로그 조회, 가중치 파싱 (2) |
| `main.dart` | Firebase 초기화 |
| `ask_service.dart` | 모델 호출 |
| `device_info_service.dart` | 플러그인 부재 |

전부 의도한 것이다. 화면이 죽는 것보다 낫다. **그래서 프로덕션에서 아무것도
안 보인다.** 상담이 계속 실패해도, 카탈로그가 안 읽혀도, 로그인이 전부 죽어도
우리는 모른다. 사용자는 그냥 앱을 지운다.

`recordError` 로 non-fatal 을 그 15군데에 기록하면 삼키는 동작은 그대로 두고
빈도가 보인다.

크래시가 없어서 안전한 게 아니라 **크래시를 안 나게 만들어서 실패가 안 보이는
상태**다.

### B.2 `firebase_analytics` 12.4.6

제품의 핵심 가설은 "TP Index 는 고정값이 아니라 사용자가 정한 비중"이다.
**사람들이 슬라이더를 실제로 만지는지 모른다.** 안 만지면 이 앱은 그냥 고정
점수 랭킹 앱이고 전제가 무너진다.

| 이벤트 | 무엇을 알 수 있나 |
|---|---|
| 가중치 변경 | 핵심 가설. 어느 축을 올리는지 |
| 관심 목록 담기/빼기 | 결론 카드가 의미 있는지 |
| 비교 실행 | 어떤 조합을 비교하는지 |
| 상담 질문 | 사람들이 뭘 묻는지 — 프롬프트와 제안 칩에 직결 |
| 랭킹 축 전환 | 다섯 축이 다 쓰이는지 |

제안 칩 네 개는 지금 우리가 지어낸 것이다.

### B.3 `firebase_performance` 0.11.4+6

TechAPI 는 GitHub Pages 정적 덤프다. 응답이 느려지거나 죽어도 우리는 모른다.
카탈로그 애셋 파싱 시간, 원격 조회 지연을 본다.

B.1·B.2 다음이다. 셋 다 Firebase 라 설정은 한 번만 한다.

---

## C. 제품 기능

### C.1 `share_plus` 13.3.0 + `app_links` 7.2.1 — **한 묶음**

결정을 돕는 앱인데 사람들은 결정 전에 **남에게 물어본다.** 홈의 결론 카드
(`지금의 결론` + 기기 + 지수 + 근거)가 그대로 공유 문구다.

텍스트만 공유하면 반쪽이다. 받은 사람이 링크를 눌러 앱이 열려야 한다
→ `app_links` 로 `techpicks://device/<slug>`, `techpicks://compare/<a>/<b>`.

`go_router` 를 안 쓴 이유가 "딥링크 요구가 없어서"였는데 공유를 넣으면 그
전제가 바뀐다. 다만 `app_links` 는 라우터를 강제하지 않는다 — 들어온 URI 를
`TabHost` 가 받아 밀어 올리면 된다. back stack 이 한 단계라 복잡할 게 없다.

**따로 넣으면 의미가 없다.**

### C.2 `firebase_remote_config` 6.5.6 — **명세가 원하던 것**

명세 Data model 절이 이렇게 적어뒀다.

> until then ship it as a versioned JSON asset **so scores can be updated
> without a store release**

그런데 지금 카탈로그는 **애셋**이라 바꾸려면 앱을 다시 내야 한다. 명세가 적은
목표를 실제로는 달성 못 하고 있다.

Remote Config 로 카탈로그 JSON 을 내려주면 그 목표가 달성된다. 점수 갱신,
기기 추가, 큐레이션 교체가 스토어를 안 거친다.

주의: Remote Config 값 크기 제한이 있어 40KB 카탈로그를 통째로 넣을지, URL 만
내려주고 본문은 따로 받을지 정해야 한다. 후자가 무난하다.

이건 **패키지 하나로 §12 의 막힌 항목 하나가 풀리는** 드문 경우다.

### C.3 `cloud_firestore` 6.8.0 — 명세가 후보로 적었다

명세 State 절이 shortlist 를 `device id[] // persist to SharedPreferences/Firestore`
라고 적었다. 우리는 로컬을 골랐고 그 이유(계정 없이 써야 한다)는 여전히 맞다.

다만 **로그인한 사용자**에게는 기기 간 동기화가 실제 값이다. 폰에서 담은 걸
태블릿에서 보는 것.

로컬 우선을 유지하고 로그인 시에만 위로 올리는 구조가 맞다. 계정 없이 쓰는
사람은 지금과 똑같이 동작해야 한다.

### C.4 `url_launcher` 6.3.2 — 라이선스 의무

상세 화면 아래에 이렇게 찍힌다.

```
Data from TechAPI · CC-BY-SA 4.0
```

**그런데 아무 데도 안 간다.** 링크로 여는 코드가 없다. CC-BY-SA 는 출처 표기와
라이선스 접근을 요구하는데 글자만 있다.

`Apache-2.0` 푸터, 개인정보 처리방침, 지원 메일도 같은 문제다. 스토어 심사에
개인정보 처리방침 URL 이 필요하다.

작지만 **의무 사항**이다.

### C.5 `connectivity_plus` 7.3.1

카탈로그 밖 기기를 열 때만 네트워크를 탄다. 끊기면 지금은 그냥 "불러오지
못했습니다"다. 사용자는 앱이 고장 난 건지 인터넷이 없는 건지 모른다.

오프라인일 때 그 사실을 알려주면 실패의 성격이 달라진다.

### C.6 `cached_network_image` 3.4.1 — 이미지가 생기면

TechAPI 의 `image_url` 이 카탈로그 10/10 채워져 있는데 **전부 404 다**
(`GetTechAPI/images` 레포가 없다). 그냥 붙이면 모든 기기가 깨진 이미지가 된다.

### C.7 `photo_view` 0.15.0 — C.6 다음

제품 사진 핀치 줌. 기기를 고르는 앱에서 사진을 확대해 보는 건 자연스럽다.
사진이 먼저다.

### C.8 `in_app_review` 2.0.12 — 시점이 생기면

리뷰를 요청할 좋은 순간이 앱 안에 있다 — 관심 목록에서 결론을 확인하고 비교까지
마친 직후. 아무 때나 띄우면 역효과라 그 순간을 코드로 잡아야 하고, 그러려면
사용 흐름 데이터(B.2)가 먼저다.

### C.9 `in_app_update` 5.0.0 / `upgrader` 13.6.0 — 나중

카탈로그가 애셋인 동안은 앱 업데이트가 곧 데이터 업데이트다. C.2 를 하면
그 압박이 줄어든다. 순서상 C.2 뒤다.

---

## D. 코드와 테스트

### D.1 `riverpod_lint` 3.1.8 + `custom_lint` 0.8.1 — **우리가 겪은 버그를 잡는다**

26·27 회차에서 같은 버그를 아홉 군데서 고쳤다 — `await` 뒤에 `ref.mounted` 를
안 보고 `state` 를 쓰는 것. 전부 손으로 찾았다.

`riverpod_lint` 가 이 부류를 정적으로 잡는다. Riverpod 을 쓰는 프로젝트가
안 넣을 이유가 없고, 이 프로젝트는 **이미 그 버그를 겪었다**는 실증이 있다.

dev 의존성이라 앱에 안 들어간다.

### D.2 `alchemist` 0.14.0 — **디자인 명세 프로젝트에 맞는다**

이 프로젝트의 전부가 "확정 디자인을 그대로 구현했는가"다. 토큰·지오메트리·
간격이 명세에 박혀 있고, 그게 지켜지는지는 지금 **사람 눈으로만** 확인한다.

골든 테스트가 그걸 고정한다. 화면 13개 × 두 크롬 × 두 언어를 이미지로 잠가두면
토큰을 잘못 건드렸을 때 바로 걸린다.

`golden_toolkit` 은 **폐기됐다.** `alchemist` 가 현행이다.

주의: iOS 크롬은 `BackdropFilter` 를 쓰는데 골든에서 블러 렌더링이 환경에 따라
달라질 수 있다. 붙일 때 확인이 필요하다.

### D.3 `mocktail` 1.0.5

지금 테스트의 가짜를 전부 손으로 썼다 — `_NoAuth`, `_FakeApi`, `_StubAdapter`,
`_NoFirebase`, `_Dead`. 인터페이스가 바뀌면 전부 같이 고쳐야 한다.

`mocktail` 은 코드 생성이 없어서 build_runner 를 더 태우지 않는다.
(`mockito` 는 생성이 필요해 안 쓴다.)

다만 지금 가짜들은 짧고 읽기 쉽다. **급하지 않다.**

### D.4 `patrol` 4.8.0 — 시뮬레이터에서 못 잡은 것들

지금까지 iOS 빌드를 깨뜨린 것들은 전부 위젯 테스트가 못 잡는 종류였다 —
CocoaPods 미설치, SPM 충돌, 없는 plist 참조. 438건이 다 통과하는데 앱이 안 떴다.

`patrol` 은 실제 기기·시뮬레이터에서 돌고 권한 다이얼로그 같은 네이티브 UI 도
다룬다. 카메라 권한(스캔)을 붙이면 특히 필요해진다.

`integration_test` 로도 되지만 네이티브 권한을 못 누른다.

### D.5 `very_good_analysis` 10.3.0 — 선택

`flutter_lints` 보다 엄격하다. 지금 analyze 가 0 이라 올리면 경고가 늘어난다.
`DEPENDENCIES.md` §1.4 에서 `flutter_lints` 6.0.0 으로 올리기로 했으니 그걸
먼저 하고, 부족하면 그때 본다.

### D.6 `talker` 5.1.20 — B.1 과 겹친다

구조화 로깅. Crashlytics 를 넣으면 프로덕션 관찰은 그쪽이 맡는다. 개발 중
로그는 `debugPrint` 로 충분하다. **안 넣는다.**

---

## E. 이미 있는 코드를 대체하는 것

### E.1 `animations` 2.2.0 — **손으로 짠 걸 공식으로 바꾼다**

32 회차에서 Android 푸시 전환(M3 shared axis X)을 직접 그렸다. 90 줄쯤 된다.
그때 "전환 하나 때문에 의존성을 늘리지 않는다"고 판단했다.

그런데 이 패키지는 **flutter.dev 가 직접 낸다**(verified publisher). API 문서를
확인하니 `SharedAxisPageTransitionsBuilder` 를 그대로 export 한다 —
`PageTransitionsTheme` 에 바로 꽂는 클래스다.

명세가 요구한 게 "M3 shared axis X" 인데, 그 정의의 원본을 쓰는 게 우리가 읽고
옮긴 것보다 정확하다. 곡선과 지속 시간을 우리가 다시 맞출 이유가 없다.

→ **바꾼다.** 커스텀 코드 90 줄이 사라진다.

### E.2 `skeletonizer` 2.1.3 — 검토

지금 스켈레톤은 화면마다 따로 그린다(`_RowSkeletons` 가 랭킹·프로세서에 중복).
`skeletonizer` 는 **진짜 위젯 트리를 그대로 스켈레톤으로 바꿔준다.**

명세가 "카드 자기 반지름의 스켈레톤 행" 을 요구하는데, 실제 위젯에서 자동
생성하면 그 요구가 저절로 지켜진다.

다만 유리 크롬(`BackdropFilter`)과 어떻게 어울릴지 확인이 필요하다.
**해볼 만하지만 지금 것도 잘 돈다.**

---

## F. 값을 못 찾은 것

### F.1 알림 — 패키지 문제가 아니다

내 정보의 **알림 토글이 죽어 있다.** 설정은 저장되는데 알림이 없다.

| 후보 | 왜 안 되나 |
|---|---|
| `flutter_local_notifications` 22.3.0 | 알릴 내용이 없다 |
| `firebase_messaging` 16.5.0 | 서버가 없다 |

알릴 만한 건 "이번 주 변동"인데 변동은 **앱을 켜야 계산된다.** 지난 실행의
순위를 저장했다가 다음 실행에 비교하는 구조라, 앱을 안 켜면 바뀐 걸 알 수 없다.
로컬 알림으로는 "앱을 켜보세요" 밖에 못 보낸다.

제대로 하려면 서버가 순위를 주기적으로 계산해 바뀐 사람에게 푸시해야 한다.
그러면 `firebase_messaging` 이 맞는 답이다. 그 전에는 패키지를 넣어도 토글이
계속 죽어 있다.

→ 지금 정직한 선택은 **토글을 숨기거나 "준비 중"으로 표시하는 것.**

### F.2 `home_widget` 0.9.3 — 전제와 충돌한다

"오늘의 결론"을 홈 화면 위젯에 띄우는 건 이 앱에 정말 잘 맞는다. 매일 볼 이유가
생긴다.

그런데 문서가 명시한다 — "HomeWidget does **not** allow writing Widgets with
Flutter itself." iOS 는 SwiftUI, Android 는 Kotlin 으로 UI 를 각각 짜야 한다.

이 프로젝트는 화면 코드에 플랫폼 분기를 두지 않는 걸 전제로 만들었다. 위젯을
넣으면 **같은 디자인 시스템을 두 네이티브 프레임워크로 다시 구현**하게 된다.

기능 값은 크지만 비용이 구조를 흔든다. → **보류.** 본체가 안정된 뒤 별도 과제.

### F.3 `mobile_scanner` 7.4.0 — 우리 스캔과 다른 것

**바코드·QR 전용이고 글자를 못 읽는다.** 명세는 "뒷면의 모델 번호를 겨누세요"
라 텍스트다. 대체가 안 된다.

조사하다 알아둘 게 나왔다 — 이 패키지는 **iOS 에서 Apple Vision 을 쓴다.**
그래서 ML Kit 의 CocoaPods 의존도, iOS 15.5 요구도 없다. Android 는 unbundled
로 ~600KB.

텍스트 인식에도 같은 게 있는지 찾아봤는데 **없다.** `apple_vision` 은 0.1.0 이라
못 쓴다. OCR 은 `google_mlkit_text_recognition` 뿐이고 iOS 15.5 비용을 감수해야
한다 (`DEPENDENCIES.md` §2.1).

→ 나중에 **소매 박스 바코드**를 읽는 두 번째 경로를 만들 여지는 있다. 박스
바코드가 모델 코드를 담아 OCR 보다 정확하다. 지금 명세에는 없다.

### F.4 `dio_cache_interceptor` 4.0.7

원격 조회 캐시. 그런데 원격을 타는 건 **카탈로그 밖 기기의 상세**뿐이고 그건
자주 안 일어난다. 카탈로그는 애셋이라 캐시가 필요 없다.

C.2 로 카탈로그를 원격으로 옮기면 그때 다시 본다.

### F.5 `flutter_secure_storage` 11.0.0

토큰을 우리가 직접 저장하지 않는다. Firebase Auth 가 알아서 한다. 우리가 쓰는
`SharedPreferences` 키 6개는 전부 민감하지 않다(가중치·관심 목록·순위·플래그).

**넣을 이유가 없다.**

### F.6 `flutter_slidable` 4.0.3

관심 목록 행에 스와이프 액션 버튼. 명세는 "swipe/long-press → remove" 고 액션
버튼을 요구하지 않는다.

실제 약점은 **잘못 밀면 되돌릴 수 없다**는 것인데, 그건 `SnackBar` + 실행 취소로
패키지 없이 된다.

### F.7 `shimmer` 3.0.0

스켈레톤에 빛이 훑고 지나가는 효과. 명세는 "Skeleton rows at the card's own
radius — never a centred spinner" 라고만 적었다. 반짝임은 요구 사항이 아니다.
E.2 를 하면 그쪽에 딸려 온다.

### F.8 `screenshot` 3.0.0

비교 표를 이미지로 공유. C.1 이 텍스트로 자리를 잡고 부족하다는 게 확인되면
본다. 유리 크롬 캡처가 어긋날 수 있어 검증이 따로 필요하다.

---

## G. 후보가 아닌 것

| 패키지 | 왜 |
|---|---|
| `webview_flutter` 계열 | v2 가 없애려던 것 |
| `model_viewer_plus`, `flutter_3d_controller` | 내부가 웹뷰 |
| `flutter_scene` | Flutter master 채널이 필요하다 |
| `fl_chart` 등 차트 | 확정 디자인에 차트가 없다 |
| `go_router` | back stack 이 한 단계. `app_links` 도 라우터를 요구하지 않는다 |
| `drift`, `hive`, `isar` | 저장할 게 키 6개뿐 |
| `golden_toolkit` | 폐기됨 → `alchemist` |
| `mockito` | 코드 생성이 필요하다 → `mocktail` |
| 햅틱 패키지 | `HapticFeedback` 이 기본에 있다 |

---

## H. 정리

### 지금

| # | 패키지 | 왜 |
|---|---|---|
| 1 | `sign_in_with_apple` | **App Store 4.8 요건.** 안 하면 반려된다 |
| 2 | `firebase_crashlytics` | 삼킨 실패 15군데가 프로덕션에서 안 보인다 |
| 3 | `firebase_analytics` | 핵심 가설(가중치)이 검증 안 됐다 |
| 4 | `riverpod_lint` + `custom_lint` | 우리가 실제로 겪은 버그를 정적으로 잡는다 |
| 5 | `animations` | 손으로 짠 shared axis 90줄을 공식으로 대체 |
| 6 | `url_launcher` | CC-BY-SA 표기가 링크가 아니다. 의무 사항 |

1–6 은 **화면 작업이 거의 없다.** 4·5·6 은 반나절짜리다.

### 다음

| # | 패키지 | 무엇이 먼저 |
|---|---|---|
| 7 | `share_plus` + `app_links` | 공유 문구 정하기 |
| 8 | `firebase_remote_config` | 카탈로그 전달 방식 정하기 |
| 9 | `alchemist` | 유리 크롬 골든이 안정적인지 확인 |
| 10 | `connectivity_plus` | 오프라인 문구 |
| 11 | `cloud_firestore` | 로컬 우선 + 로그인 시 동기화 설계 |
| 12 | `firebase_performance` | 2·3 뒤 |

### 무언가 들어와야 시작

`cached_network_image` · `photo_view` (이미지 저장소) ·
`in_app_review` (사용 흐름 데이터) · `in_app_update` (8 뒤) ·
`patrol` (스캔 붙인 뒤) · `skeletonizer` (해볼 만함) ·
`flutter_facebook_auth` (붙일지 뺄지 제품 판단)

### 안 함

알림(서버가 먼저) · `home_widget`(네이티브 UI 2벌) · `mobile_scanner`(텍스트를 못 읽음) ·
`dio_cache_interceptor` · `flutter_secure_storage` · `flutter_slidable` ·
`shimmer` · `screenshot` · `talker` · `very_good_analysis`

---

## 출처

- [App Store 심사 지침 4.8](https://developer.apple.com/app-store/review/guidelines/)
- [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple) · [flutter_facebook_auth](https://pub.dev/packages/flutter_facebook_auth)
- [firebase_crashlytics](https://pub.dev/packages/firebase_crashlytics) · [firebase_analytics](https://pub.dev/packages/firebase_analytics) · [firebase_performance](https://pub.dev/packages/firebase_performance)
- [share_plus](https://pub.dev/packages/share_plus) · [app_links](https://pub.dev/packages/app_links) · [firebase_remote_config](https://pub.dev/packages/firebase_remote_config) · [cloud_firestore](https://pub.dev/packages/cloud_firestore)
- [url_launcher](https://pub.dev/packages/url_launcher) · [connectivity_plus](https://pub.dev/packages/connectivity_plus) · [cached_network_image](https://pub.dev/packages/cached_network_image) · [photo_view](https://pub.dev/packages/photo_view)
- [riverpod_lint](https://pub.dev/packages/riverpod_lint) · [custom_lint](https://pub.dev/packages/custom_lint) · [alchemist](https://pub.dev/packages/alchemist) · [mocktail](https://pub.dev/packages/mocktail) · [patrol](https://pub.dev/packages/patrol)
- [animations](https://pub.dev/documentation/animations/latest/animations/animations-library.html) · [skeletonizer](https://pub.dev/packages/skeletonizer)
- [home_widget](https://pub.dev/packages/home_widget) · [mobile_scanner](https://pub.dev/packages/mobile_scanner) · [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) · [firebase_messaging](https://pub.dev/packages/firebase_messaging)
- [in_app_review](https://pub.dev/packages/in_app_review) · [in_app_update](https://pub.dev/packages/in_app_update) · [upgrader](https://pub.dev/packages/upgrader) · [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) · [dio_cache_interceptor](https://pub.dev/packages/dio_cache_interceptor) · [flutter_slidable](https://pub.dev/packages/flutter_slidable) · [shimmer](https://pub.dev/packages/shimmer) · [screenshot](https://pub.dev/packages/screenshot) · [talker](https://pub.dev/packages/talker) · [very_good_analysis](https://pub.dev/packages/very_good_analysis)
