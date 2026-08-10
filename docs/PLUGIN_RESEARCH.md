# 이 앱에 보탬이 될 플러그인

2026-08-10 조사. **지금 있는 의존성을 어떻게 할지는 `DEPENDENCIES.md` 에 있다.**
여기는 반대로 — 아직 안 쓰는 것 중에 이 앱에 실제로 값을 더할 게 뭔지 찾는다.

버전은 pub.dev API 로, 동작은 공식 문서로 그날 확인했다.

---

## 판단 기준

이 앱이 어떤 앱인지에 비춰서 본다.

1. **결정을 돕는 앱이다.** 사람들은 결정 전에 남에게 물어본다
2. **예외를 의도적으로 삼킨다.** 실패해도 화면이 안 죽는 게 설계다
3. **핵심 가설이 검증 안 됐다.** "지수는 사용자가 정한다"가 맞는지 모른다
4. **플랫폼 분기를 화면 코드에 두지 않는다.** 토큰만 갈아 끼운다
5. **웹뷰를 안 쓴다.** v2 가 없애려던 것이다

4·5 를 어기는 패키지는 아무리 기능이 좋아도 안 쓴다.

---

## A. 강하게 추천

### A.1 `firebase_crashlytics` 5.2.7 — **가장 값이 크다**

이 코드베이스는 예외를 **일부러 삼킨다.** 세어보면 15군데다.

| 파일 | 삼키는 것 |
|---|---|
| `main.dart` | Firebase 초기화 실패 |
| `auth_service.dart` | 로그인·가입·로그아웃·현재 사용자 (5) |
| `ask_service.dart` | 모델 호출 실패 |
| `providers.dart` | 카탈로그 조회, 가중치 파싱 (2) |
| `catalog_repository.dart` | 애셋 읽기·파싱 (2) |
| `tech_api_repository.dart` | 원격 조회 (2) |
| `device_info_service.dart` | 플러그인 부재 |

전부 의도한 것이다. 화면이 죽는 것보다 낫다. **그런데 그래서 프로덕션에서
아무것도 안 보인다.** 상담이 계속 실패해도, 카탈로그가 안 읽혀도, 로그인이
전부 죽어도 우리는 모른다. 사용자는 그냥 앱을 지운다.

Crashlytics 의 **non-fatal 기록**(`recordError`)을 이 15군데에 넣으면 삼키는
동작은 그대로 두면서 어떤 실패가 얼마나 나는지 보인다.

이 앱이 특별히 이 패키지를 필요로 하는 이유가 여기 있다. 크래시가 없어서
안전한 게 아니라, **크래시를 안 나게 만들어서 실패가 안 보이는 것**이다.

Firebase 는 이미 들어와 있어서 추가 설정이 적다.

### A.2 `firebase_analytics` 12.4.6

제품의 핵심 가설은 "TP Index 는 고정값이 아니라 사용자가 정한 비중"이다.
그런데 **사람들이 슬라이더를 실제로 만지는지 모른다.** 안 만지면 이 앱은
그냥 고정 점수 랭킹 앱이고, 전제가 무너진다.

측정할 것이 명확하다.

| 이벤트 | 무엇을 알 수 있나 |
|---|---|
| 가중치 변경 | 핵심 가설이 맞는지. 어느 축을 올리는지 |
| 관심 목록 담기/빼기 | 결론 카드가 의미 있는지 |
| 비교 실행 | 어떤 조합을 비교하는지 |
| 상담 질문 | 사람들이 뭘 묻는지 (프롬프트 개선에 직결) |
| 랭킹 축 전환 | 다섯 축이 다 쓰이는지 |

상담 질문 로그는 특히 값이 크다. 지금 제안 칩 네 개는 우리가 지어낸 것이다.

### A.3 `share_plus` 13.3.0

이 앱은 결정을 돕는다. 사람들은 결정 전에 **남에게 물어본다.** 비교 표나
결론 카드를 공유하는 건 제품의 핵심 행동과 정확히 맞물린다.

명세에 없지만 없는 게 이상한 쪽이다. 홈의 결론 카드(`지금의 결론` +
기기 + 지수 + 근거 한 문장)는 그대로가 공유 문구다.

주의: 텍스트만 공유하면 반쪽이다. 받은 사람이 링크를 눌러 앱이 열려야 한다
→ **A.4 와 짝이다.**

### A.4 `app_links` 7.2.1 — A.3 과 함께

공유 링크가 앱을 열게 한다. `techpicks://device/galaxy-s25-ultra`,
`techpicks://compare/a/b`.

우리는 `go_router` 를 안 쓰기로 했고 그 이유가 "딥링크 요구가 없어서"였다.
공유를 넣으면 그 전제가 바뀐다. 다만 `app_links` 는 라우터를 강제하지 않는다 —
들어온 URI 를 받아서 `TabHost` 가 밀어 올리면 된다. back stack 이 한 단계라
복잡할 게 없다.

**A.3 없이 A.4 만 넣는 건 의미 없다.** 둘은 한 묶음이다.

---

## B. 조건이 붙는 것

### B.1 `cached_network_image` 3.4.1 — 이미지가 생기면

상세의 196px 자리와 목록 썸네일. 지금은 넣을 이미지가 없다.

TechAPI 의 `image_url` 이 카탈로그 10/10 전부 채워져 있는데 **전부 404 다**
(`GetTechAPI/images` 레포가 없다). 그냥 붙이면 모든 기기가 깨진 이미지가 된다.
`DEPENDENCIES.md` §2.4 참고.

### B.2 `in_app_review` 2.0.12 — 시점이 생기면

리뷰를 요청할 **좋은 순간**이 앱 안에 있다 — 관심 목록에서 결론을 확인하고
비교까지 마친 직후. 아무 때나 띄우면 역효과라 그 순간을 코드로 잡아야 한다.

지금 넣으면 띄울 자리를 못 정한다. 사용 흐름 데이터(A.2)가 먼저다.

### B.3 `flutter_slidable` 4.0.3 — 안 넣는 쪽에 가깝다

관심 목록 행에 스와이프 액션 버튼을 붙인다. 지금은 `Dismissible` 로 밀어서
바로 지우고, 명세도 "swipe/long-press → remove" 다.

명세가 액션 버튼을 요구하지 않는다. **실행 취소**가 필요해지면 그때 본다 —
지금은 잘못 밀면 되돌릴 수 없다는 게 실제 약점이긴 하다. 다만 그건
`SnackBar` + 실행 취소로 패키지 없이 된다.

---

## C. 값을 못 찾은 것

### C.1 알림 — **패키지 문제가 아니다**

내 정보의 **알림 토글이 죽어 있다.** 설정은 저장되는데 알림이 없다.

| 후보 | 왜 안 되나 |
|---|---|
| `flutter_local_notifications` 22.3.0 | 알릴 내용이 없다 |
| `firebase_messaging` 16.5.0 | 서버가 없다 |

알릴 만한 건 "이번 주 변동"인데, 변동은 **앱을 켜야 계산된다.** 지난 실행의
순위를 저장해뒀다가 다음 실행에 비교하는 구조라, 앱을 안 켜면 바뀐 걸 알 수
없다. 로컬 알림으로는 "앱을 켜보세요" 밖에 못 보낸다.

제대로 하려면 **서버가 순위를 주기적으로 계산하고 바뀐 사람에게 푸시**해야
한다. 그게 되면 `firebase_messaging` 이 맞는 답이다. 그 전에는 패키지를
넣어도 토글이 계속 죽어 있다.

→ 지금 할 수 있는 정직한 선택은 **토글을 숨기거나 "준비 중"으로 표시하는 것**이다.

### C.2 `home_widget` 0.9.3 — 전제와 충돌한다

"오늘의 결론"을 홈 화면 위젯에 띄우는 건 이 앱에 정말 잘 맞는다. 매일 볼
이유가 생긴다.

그런데 이 패키지는 **Flutter 로 위젯을 못 만든다.** 문서가 명시한다 —
"HomeWidget does **not** allow writing Widgets with Flutter itself."
iOS 는 SwiftUI, Android 는 Kotlin 으로 각각 UI 를 짜야 한다.

이 프로젝트는 화면 코드에 플랫폼 분기를 두지 않는 걸 전제로 만들었다. 토큰
집합 하나에 두 크롬을 담고 화면은 그걸 갈아 끼우기만 한다. 위젯을 넣으면
**같은 디자인 시스템을 SwiftUI 와 Kotlin 으로 두 번 더 구현**하게 된다.

기능 값은 크지만 비용이 구조를 흔든다. → **보류.** 앱 본체가 안정된 뒤에 별도
과제로 다룬다.

### C.3 `mobile_scanner` 7.4.0 — 우리 스캔과 다른 것

**바코드·QR 전용이고 글자는 못 읽는다.** 명세는 "뒷면의 모델 번호를 겨누세요"
라 텍스트다. 대체가 안 된다.

다만 조사하면서 알아둘 게 나왔다 — 이 패키지는 **iOS 에서 Apple Vision 을
쓴다.** 그래서 ML Kit 의 CocoaPods 의존도, iOS 15.5 요구도 없다. Android 도
unbundled 로 ~600KB 다.

텍스트 인식 쪽에도 같은 게 있는지 찾아봤는데 **없다.** `apple_vision` 은
0.1.0 이라 못 쓴다. 결국 OCR 은 `google_mlkit_text_recognition` 뿐이고
iOS 15.5 비용을 감수해야 한다 (`DEPENDENCIES.md` §2.1).

→ 나중에 **소매 박스 바코드**를 읽는 두 번째 경로를 만들 여지는 있다. 박스
바코드가 모델 코드를 담고 있어 OCR 보다 정확하다. 지금 명세에는 없다.

### C.4 `shimmer` 3.0.0 — 명세가 요구하지 않는다

로딩 스켈레톤에 빛이 훑고 지나가는 효과. 지금은 정적인 회색 블록이다.

명세 Interactions 는 "Skeleton rows at the card's own radius — never a centred
spinner" 라고만 적었다. 반짝임은 요구 사항이 아니다. 디자인이 원하면 그때 넣는다.

### C.5 `screenshot` 3.0.0 — 공유가 자리 잡은 뒤에

비교 표를 이미지로 만들어 공유. A.3 이 텍스트 공유로 먼저 자리를 잡고, 그걸로
부족하다는 게 확인되면 본다.

이미지 공유는 유리 크롬(`BackdropFilter`)을 캡처할 때 결과가 어긋날 수 있어
검증이 따로 필요하다.

---

## D. 아예 후보가 아닌 것

| 패키지 | 왜 |
|---|---|
| `webview_flutter` 계열 | v2 가 없애려던 것 |
| `model_viewer_plus`, `flutter_3d_controller` | 위와 같음 (내부가 웹뷰) |
| `fl_chart` 등 차트 | 확정 디자인에 차트가 없다 |
| `go_router` | back stack 이 한 단계. A.4 도 라우터를 요구하지 않는다 |
| `drift`, `hive`, `isar` | 저장할 게 키 6개뿐이다 |
| 햅틱 패키지 | `HapticFeedback` 이 Flutter 기본에 있다 |

---

## E. 정리

| 순위 | 무엇 | 왜 지금 |
|---|---|---|
| 1 | `firebase_crashlytics` | 삼킨 실패 15군데가 프로덕션에서 안 보인다 |
| 2 | `firebase_analytics` | 핵심 가설(가중치)이 검증 안 됐다 |
| 3 | `share_plus` + `app_links` | 결정을 돕는 앱인데 공유가 없다 |
| — | `cached_network_image` | 이미지 저장소가 생기면 |
| — | `in_app_review` | 사용 흐름 데이터가 쌓이면 |
| — | `home_widget` | 값은 크지만 네이티브 UI 를 두 번 짜야 한다 |
| — | 알림 | 서버가 순위를 계산해 푸시해야 한다. 패키지 문제가 아니다 |

1·2 는 **코드를 거의 안 건드린다.** Crashlytics 는 이미 있는 `catch` 블록에
한 줄씩, Analytics 는 기존 notifier 에 이벤트 한 줄씩이다. Firebase 가
들어와 있어 설정도 적다.

3 은 화면 작업이 붙는다 — 공유 문구를 만들고, 들어온 링크를 받는 자리를
`TabHost` 에 넣어야 한다.

---

## 출처

- [share_plus](https://pub.dev/packages/share_plus) · [app_links](https://pub.dev/packages/app_links) · [firebase_crashlytics](https://pub.dev/packages/firebase_crashlytics) · [firebase_analytics](https://pub.dev/packages/firebase_analytics)
- [home_widget](https://pub.dev/packages/home_widget) · [mobile_scanner](https://pub.dev/packages/mobile_scanner) · [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) · [firebase_messaging](https://pub.dev/packages/firebase_messaging)
- [in_app_review](https://pub.dev/packages/in_app_review) · [flutter_slidable](https://pub.dev/packages/flutter_slidable) · [shimmer](https://pub.dev/packages/shimmer) · [screenshot](https://pub.dev/packages/screenshot) · [cached_network_image](https://pub.dev/packages/cached_network_image)
