# 인계

2026-08-13 기준. 이어받는 사람이 먼저 읽을 것.

## 지금 상태

브랜치 `feat/design-handoff`, 워킹 트리 깨끗, 미푸시 커밋 92개.
사용자가 모아뒀다 직접 푸시하는 방식이다. **푸시·PR·머지·CI 는 시키기 전까지 하지 않는다.**

`flutter analyze` 이슈 0, `flutter test` 587건 통과(골든 24장 포함).
iOS·Android 디버그 빌드 둘 다 통과한다.
iOS 시뮬레이터와 Android 에뮬레이터 둘 다에서 뜬다. 실기기는 못 해봤다 — 연결된 기기도, 코드사인 인증서도 없다.

명세 8단계(`DESIGN_HANDOFF.md` 의 Suggested build order)는 전부 끝났다.

## 최근에 한 일

| 커밋 | 무엇 |
|---|---|
| `6fc95c6` | Firebase 4.x/6.x, `firebase_vertexai` → `firebase_ai`, iOS SPM 전환(배포 타깃 15.0) |
| `732c250` | 안 쓰는 위치·사진 권한 선언 제거 |
| `af11ca8` | Crashlytics 로 삼킨 실패 11군데, Analytics 로 제품 가설 |
| `e87cedb` `7d465b6` `085b477` `bf6e6a9` | 모션 토큰(`TpMotion`), 동작 줄이기, 진행 막대 통합, 화면 모션 |
| `6e1f06d` | 패키지 이름 `com.example.techpicks` → `com.techpicks.app` |
| `cc9b197` | 골든 테스트 — 화면 11종 × 두 크롬 + 공용 위젯 한 장 |
| `454cd12` | 공유 + 딥링크(`techpicks://`), TpShell 헤더 오른쪽 슬롯 |
| `55c0df5` | 오프라인이면 실패 문구를 바꾼다 |
| `93c6323` | Remote Config 로 카탈로그 갱신 (주소만 내려받는다) |
| `b675cf7` | 로그인 시 관심 목록 동기화 (문서 단위 LWW) |
| `89ce171` | `PrivacyInfo.xcprivacy` (Xcode Resources 단계까지) |
| `27fb6a1` | 출처·라이선스 표기를 실제 링크로 |
| `78f8d4f` | Google·Apple 로그인, Facebook 제거, 취소와 실패 분리 |
| `de458b9` | 릴리스 서명을 `android/key.properties` 로 받는다 |
| `6a42707` | 비밀번호 재설정 메일, 이름 바꾸기 |
| `e8c1c29` | 카탈로그 폰 154·CPU 40·SoC 30·브랜드 16, 랭킹 상한 50 |
| `e5612ba` | 비교 선택 시트 검색 |

## 손대기 전에 알아야 할 것

**`android/app/google-services.json` 은 로컬에서 손본 상태다.** 이 파일은
`.gitignore` 대상이라 git 에 안 보인다. 패키지 이름을 바꾸고 Android 빌드를
통과시키려고 `package_name` 만 `com.techpicks.app` 으로 맞춰뒀고, `appId` 는
여전히 옛 패키지 것이다. 그래서 빌드는 되지만 Firebase 가 이 앱을 못 알아본다 —
로그인이 안 되는 건 정상이다. 초기화 실패는 삼키므로 나머지 화면은 다 돈다.
콘솔에서 새 파일을 받으면 통째로 갈아 끼운다.

`/tmp` 의 `.bak` 파일들에 의존하지 말 것. 해당 변경은 커밋됐거나 gitignore
대상이고, `/tmp` 는 어차피 비워진다.

**카탈로그를 다시 구우면 테스트가 아니라 데이터가 바뀐다.**
`dart tool/build_catalog.dart` 는 TechAPI 에서 다시 골라 담는다. 기대값을
기기 이름으로 박아둔 테스트는 그때 다 깨지므로, 새 테스트는 하네스의
`readCatalog()` · `readRanking()` 으로 데이터에서 끌어와야 한다.

랭킹 화면은 상위 50만 그린다 (`RankScreen.maxRows`). 재서 정한 값이다 —
행당 프레임 비용이 0.25ms 씩 붙어 154행이면 기기에서 슬라이더가 끊긴다.
근거는 `ROADMAP.md` §P3.6. 화면 아래쪽 요소를
찾는 테스트는 스크롤하거나 화면을 키워야 한다.

**SnackBar 를 쓰지 말 것.** 이 앱은 Scaffold 가 없다 — TpShell 이 크롬을
직접 그린다. 안내는 로그인·내 정보처럼 본문에 한 줄로 붙인다.

**골든을 고치기 전에 그림부터 본다.** `test/golden/goldens/` 의 PNG 24장이
기준선이고 macOS 에서만 맞춘다. 화면을 손대면 여기가 깨지는 게 정상이다.
`flutter test test/golden --update-goldens` 로 다시 굽되, **다시 굽기 전에
바뀐 그림이 의도한 것인지 눈으로 확인한다.** 아무 기계에서나 `--update-goldens`
를 돌리면 기준선이 그 기계 것으로 덮인다.

**딥링크는 시뮬레이터에서 확인했다.** 앱이 꺼진 상태와 떠 있는 상태 둘 다
연다. 확인할 때는 `xcrun simctl openurl booted "techpicks://device/galaxy-s25"`
를 쓰고, 처음 한 번은 iOS 가 "'Techpicks'에서 열겠습니까?"를 묻는다 — 그걸
취소하면 링크가 앱까지 안 온다.

**탭 전환에 모션을 넣지 않는다.** 명세 Interactions 표가 `Instant; no cross-fade`
로 못박았다. 한 번 계획에 넣었다가 뺐다.

## 기다리는 것

| 무엇 | 누가 |
|---|---|
| Firebase 앱 재등록 (`com.techpicks.app`), `GoogleService-Info.plist` | 사용자 — 콘솔 |
| Remote Config `catalog_url`·`catalog_version`, 카탈로그 JSON 호스팅 | 사용자 — 콘솔 |
| Firestore 보안 규칙 (`users/{uid}` 는 본인만) | 사용자 — 콘솔 |
| 실기기 테스트 (기기 연결 + Xcode 로그인) | 사용자 |
| `techpicks.com` 도메인 | 사용자 — 구매 예정 |
| Apple Developer 에서 Sign in with Apple 켜기 | 사용자 — 계정 작업 |
| Firebase 콘솔에서 Google·Apple 공급자 켜기, Android SHA-1 등록 | 사용자 — 콘솔 |
| Android 릴리스 키스토어(`android/key.properties`), 개인정보 처리방침 URL | 사용자 |
| 노트북 점수, 제품 사진, 원화 가격, 다크 토큰 | TechAPI / 디자인 |

패키지 이름은 스토어에 한 번 올리면 못 바꾼다. 지금 값이 최종이다.

## 기한

10월에 Firebase 가 CocoaPods 발행을 멈추고 Gemini 2.5 계열이 종료된다.
둘 다 `6fc95c6` 으로 대응이 끝났다. Play 의 API 36 요건도 이미 충족.
표는 `ROADMAP.md` §1.

## 시뮬레이터로 본 것

iPhone 17 Pro(iOS 27) 에서 화면을 하나씩 돌려 보고 고친 것:

| 화면 | 결함 | 커밋 |
|---|---|---|
| 스캔·3D 뷰어 | 어두운 인수 화면 아래에 밝은 띠 — 셸이 안전 영역을 비웠다 | `9567713` |
| 홈 관심 목록 | 다 들어간 스펙 줄까지 흐려져 끝 글자가 잘려 보임 | `9567713` |
| 상세 출처 줄 | 링크인데 본문과 같은 회색 | `9567713` |
| 비교 선택 | 84, 84, 85 — 카탈로그 순서(원점수)와 화면의 지수가 어긋남 | `297c520` |
| 내 정보 | 계정이 없는데 "프로필 수정"과 "로그아웃" | `297c520` |
| 로그인 | 마크가 없는 이메일 버튼만 라벨이 왼쪽으로 튀어나옴 | `6cd5493` |
| 이메일 로그인 | 빈 칸으로 눌러도 "이메일 주소 형식이 아닙니다" | `6cd5493` |

**이번 주 변동은 실제로는 안 뜬다.** 카탈로그가 고정이라 지난 실행의 순위와
이번 순위가 같다. 데이터가 바뀌어야(애셋 재생성·Remote Config) 뜬다. 눈으로
보려면 앱을 끈 뒤 스냅샷을 손으로 심는다 — 컨테이너 안 plist 를 시뮬레이터
쪽 `defaults` 로 써야 한다. 파일을 직접 고치면 cfprefsd 캐시가 덮어쓴다.

```
C=$(xcrun simctl get_app_container <udid> com.techpicks.app data)
xcrun simctl spawn <udid> defaults write "$C/Library/Preferences/com.techpicks.app" \
  flutter.rank_snapshot_slugs -array iphone-16-pro-max galaxy-s25-ultra pixel-10-pro
```

아직 안 본 것: Android 크롬 실물(에뮬레이터 없이 `main.dart` 에서 강제로 한 번
봤다).

## iOS 를 먼저 낸다

2026-08-15 에 iOS 쪽만 훑어 마감했다. 코드로 할 수 있는 건 다 했고, 남은
셋은 사용자 계정이 있어야 한다.

| 남은 것 | 왜 우리가 못 하나 |
|---|---|
| Firebase 에 `com.techpicks.app` 로 iOS 앱 등록 → `flutterfire configure` | 콘솔 로그인 |
| Apple Developer 에서 Sign in with Apple 켜기 | 유료 계정 |
| 개인정보 처리방침 URL | 게시할 곳 |

**Google 로그인은 지금 상태로 안 된다.** `firebase_options.dart` 의
`iosBundleId` 가 `com.example.techpicks` 라 OAuth 클라이언트가 안 맞는다.
실행하면 Firebase 가 로그로 그렇게 말한다 (`I-COR000008`). 앱은 뜬다.

명세와 다르게 간 것 하나: **스캔(§11)이 카메라가 아니라 이름 입력이다.**
카메라도 OCR 도 붙은 적이 없어 실기기에서는 검은 화면에 조준틀만 돌았다.
`ScanMatcher` 는 그대로 쓰고, 카메라가 붙는 날 `ScanScreen.recognizedText` 로
읽은 글자를 넣어주면 같은 화면이 결과를 띄운다. 카탈로그에 `SM-S931B` 같은
모델 코드가 없어 받는 것은 **기기 이름**이다.

아이콘은 `tool/icons/ios_1024.png` 에서 굽는다 — `assets/logo/logo.png` 의
둥근 모서리를 그라디언트로 메운 네모난 원본이다. 알파가 있으면 App Store
Connect 가 반려한다.

## 두 번째로 훑어 찾은 것 (2026-08-16)

로그를 켜 놓고 화면을 돌면서 잡았다. 화면만 봐서는 안 보이던 것들이다.

| 무엇 | 어떻게 드러났나 |
|---|---|
| 상담이 모델을 한 번도 안 불렀다 | `askServiceProvider` 가 로컬 구현만 물고 있었다 |
| "100만원 이하"를 100달러로 읽었다 | 칩을 눌렀더니 $99 짜리 Galaxy A05 를 추천했다 |
| Analytics 가 bool 을 보내 어서션이 터졌다 | 실행 로그에 Crashlytics 리포트가 찍혔다 |
| 보내기 버튼이 입력창과 같은 이름 | 코드에서 `K.send` 가 아무 데서도 안 쓰였다 |
| 브랜드 표기가 섞여 있었다 | 랭킹에 `Vivo X300 Pro` 와 `vivo X200 Pro` 가 나란히 |

이름 표기는 `tool/build_catalog.dart` 의 `canonicalName` 이 정한다. 이미 구운
애셋만 다시 맞추려면:

```bash
dart run tool/normalize_names.dart
```

**상담은 App Check 를 켜야 모델을 쓴다.** 지금은 Gemini 가 거절당하고
(`Firebase AI Logic has been deactivated`) 로컬 답이 대신 나간다. 화면은 같고
답의 출처만 다르다 — ROADMAP §P1 에 로그 원문을 적었다.

## 다음에 할 만한 것

`ROADMAP.md` §2 가 작업 큐다. **P1·P3 의 코드는 다 끝났다.** 코드로 혼자 진전시킬 수
있는 것은 남아 있지 않다. P1 과 P3.2·P3.5 의 콘솔 값이 다음 차례다.

P3.2·P3.5 는 코드가 다 들어갔지만 **콘솔 값이 없으면 안 도는 상태**다.
Remote Config 가 비어 있으면 애셋만 쓰고, Firestore 가 막혀 있으면 로컬만
쓴다 — 둘 다 조용히 지금까지대로 동작한다.

`riverpod_lint` 은 못 넣는다. `custom_lint` 과 `json_serializable` 이 요구하는
analyzer 버전이 겹치지 않는다. §2 에 표가 있다.

## 문서

| 파일 | 내용 |
|---|---|
| `DESIGN_HANDOFF.md` | 확정 명세. 값이 적혀 있으면 그대로 따른다 |
| `FUNCTIONAL_SPEC.md` | 앱이 무엇을 하는가 |
| `DEPENDENCIES.md` | 지금 쓰는 패키지 |
| `PLUGIN_RESEARCH.md` | 넣을 만한 패키지 30종 |
| `ROADMAP.md` | 언제 무엇을 — 작업 큐 |
| `REBUILD_PLAN.md` | 재구축 경위 |

## 작업 규칙

- 커밋은 conventional commits, `Co-Authored-By` 트레일러 없음
- 브랜치는 머지 후에도 지우지 않는다
- CI 는 사용자가 "앱 다 만들었다"고 할 때까지 돌리지 않는다. 로컬 `flutter test` /
  `analyze` 결과는 보고하되 검증이라고 부르지 않는다
- 글은 분량을 변경 크기에 맞춘다. 논증하거나 마무리 문장을 붙이지 않는다
