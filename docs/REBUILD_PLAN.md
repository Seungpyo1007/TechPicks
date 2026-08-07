# TechPicks 재구축 계획서

> 작성일 2026-08-07 · 대상 브랜치 `develop` · 현재 버전 v1.0.1beta → 목표 v2.0.0

---

## 1. 배경 — 왜 뒤엎는가

현재 TechPicks(v1)는 **데이터가 없는 앱**이다. 앱을 실제로 열어보면 세 가지 방식으로 정보를 채우고 있다.

| 화면 | 현재 데이터 출처 | 문제 |
|---|---|---|
| Phone | `Phone.dart` 안에 `Map` 리터럴로 하드코딩된 4개 기종 | 갱신 불가, 성능 점수는 임의 숫자 |
| CPU | `device_info_plus`로 읽은 **내 기기 정보** | 제품 DB가 아님 — 기능명과 실제 동작이 불일치 |
| Laptop / Ranking | `nanoreview.net` 등 외부 사이트를 WebView로 띄우고 JS로 헤더 제거 | 남의 사이트 구조에 종속, 오프라인 불가, 법적으로도 취약 |

즉 v1은 **UI 껍데기는 있으나 도메인 데이터 계층이 존재하지 않는다.** 여기에 상태관리 라이브러리 없이 `setState`만 쓰고, 모델 클래스 없이 `Map<String, dynamic>`을 직접 들고 다니며, 테스트 디렉터리가 없다. 화면 단위로 기능을 덧붙이는 방식은 이미 한계에 도달했다.

그 사이 **데이터 문제가 저장소 밖에서 해결됐다.** `GetTechAPI` 조직의 TechAPI(데이터)와 TechEngine(엔진)이 그것이다. TechEngine의 명세서는 TechPicks를 이렇게 정의한다:

> "TechAPI는 다양한 앱·웹 플랫폼·AI 에이전트가 소비자 전자기기 스펙을 공통으로 활용할 수 있도록 만든 무료·공개 RESTful API. **TechPicks 앱이 첫 사용자(reference consumer).**"
> — `TechEngine/docs/SPEC.md` §1.1

TechEngine의 `app/config.py`는 이미 CORS 허용 목록에 `https://techpicks.app`을 넣어두고 있다. 재구축은 이 생태계에 TechPicks를 제자리로 돌려놓는 작업이다.

---

## 2. TechEngine · TechAPI 분석 결과

### 2.1 역할 분담

```
GetTechAPI/TechAPI     — 데이터 + 공개 사이트        기본 브랜치: develop   (CC-BY-SA 4.0)
GetTechAPI/TechEngine  — 검증·수집·서빙 엔진 (Python) 기본 브랜치: main      (MIT)
```

두 저장소는 서로를 git submodule로 물고 있고, 7개의 GitHub Actions가 양방향 동기화·주간 갱신·커버리지 리포트를 자동으로 돌린다. TechPicks는 이 중 **소비자(consumer) 위치**에만 붙으면 된다.

### 2.2 확보 가능한 데이터 (실측)

`https://gettechapi.github.io/TechAPI/v1/index.json` 응답 기준:

| 컬렉션 | 레코드 수 | 점수 산출됨 |
|---|---:|---:|
| smartphones | 93,396 | 93,396 |
| software | 42,493 | – |
| websites | 40,084 | – |
| cpus | 3,977 | 841 |
| tablets | 3,455 | – |
| socs | 2,104 | 195 |
| gpus | 2,030 | 1,768 |
| laptops | 1,951 | – |
| monitors | 882 | – |
| watches | 433 | – |
| brands | 207 | – |
| pdas | 140 | – |

### 2.3 핵심 발견 — 점수 스키마가 현재 UI와 거의 일치한다

`Phone.dart`가 하드코딩한 레이더 차트 축은 `performance / camera / display / battery / features`다. TechAPI가 내려주는 `score` 객체는 다음과 같다:

```json
"score": {
  "algorithm_version": "2.0.0",
  "overall": 60.8, "performance": 88.9, "camera": 36.1,
  "battery": 54.4, "display": 63.8, "value": 59.0,
  "perf": { "index": 88.9, "percentile": 92.0, "tier": "A",
            "era": "2024-2026", "source": "geekbench" }
}
```

`features` → `value`로 축 하나만 바꾸면 **데이터 매핑이 1:1로 맞는다.** 게다가 `tier`, `percentile`, `era` 같은 v1에 없던 축이 추가로 들어온다.

표현 형태는 레이더 차트를 쓰지 않는다. 단일 기기는 62px 히어로 숫자 + 5구간 막대 스트립, 비교는 스펙 표에서 행마다 이긴 셀을 강조한다. 확정 명세는 `docs/DESIGN_HANDOFF.md`.

한 가지 차이가 있다. 디자인의 **TP Index는 사용자가 가중치를 조정하는 값**이라 TechAPI의 `score.overall`을 그대로 쓰지 않는다. 5개 축만 받아 앱에서 계산한다.

```
idx = round(perf*0.25 + cam*0.25 + disp*0.20 + batt*0.20 + val*0.10)
```

기본 가중치가 이렇고, You 화면의 슬라이더로 바꾸면 화면에 보이는 모든 지수가 즉시 다시 계산된다.

### 2.4 데이터 접근 경로 — 지금 당장 쓸 수 있는 것

| 경로 | 상태 (2026-08-07 실측) | 판단 |
|---|---|---|
| `https://api.techapi.dev/v1/` | **DNS 미해결 (연결 실패)** | 아직 미배포. SPEC상 Railway/Fly.io 배포는 미완료 항목 |
| `https://gettechapi.github.io/TechAPI/v1/**/index.json` | **HTTP 200, 정상 서빙** | ✅ 즉시 사용 가능 |
| `raw.githubusercontent.com/.../data/**.json` | HTTP 200 | 원본 큐레이션 파일 (조인 안 된 형태) |

> **결정: v2는 GitHub Pages 정적 덤프를 1차 데이터 소스로 삼는다.**
> 서버 배포를 기다릴 필요가 없고, 덤프는 실제 엔드포인트를 인프로세스로 replay해 생성되므로 **REST API와 응답 스키마가 동일하다.** 나중에 `api.techapi.dev`가 뜨면 `baseUrl` 한 줄과 URL 조립 규칙만 바꾸면 된다.

덤프 URL 규칙 (일반 REST와 다른 유일한 지점):

```
REST   GET /v1/smartphones/galaxy-s25
덤프   GET /v1/smartphones/galaxy-s25/index.json     ← 경로 끝에 /index.json
```

정적 덤프는 `search`·`compare` 같은 쿼리 엔드포인트를 제공하지 않는다. 대응은 §5 참조.

### 2.5 상세 레코드 형태

`/v1/smartphones/galaxy-s25/index.json`은 브랜드와 SoC가 **이미 조인되어** 내려온다. 클라이언트에서 N+1 요청이 필요 없다.

```
id, slug, base_model_slug, name,
brand{ slug, name, country, url },
soc{ slug, name, manufacturer{...}, process_nm, gpu_name, url },
release_date, msrp_usd, ram_gb, storage_options_gb, variant,
display{ size_inch, resolution, refresh_hz, type, brightness_nits },
cameras[], battery_mah, charging_wired_w, charging_wireless_w,
weight_g, dimensions, ip_rating, os, os_version, connectivity,
image_url, images[], score{...}, verified, source_urls[],
created_at, updated_at
```

`source_urls`와 `verified` 필드가 있으므로 **출처 표기 UI**를 만들 수 있다. CC-BY-SA 4.0 조건상 "Data from TechAPI" 귀속 표기가 **의무**이므로 이건 선택이 아니라 필수 화면이다.

---

## 3. 목표 아키텍처

```
lib/
  main.dart                      앱 부트스트랩만 (ProviderScope + router)
  app/
    router.dart                  go_router 라우트 정의
    theme/                       디자인 토큰 → ThemeData (iOS/Android 두 크롬)
    localization/
  core/
    network/tech_api_client.dart  덤프/REST 양쪽을 흡수하는 단일 클라이언트
    result.dart                   Result<T, Failure>
    cache/                        Hive 또는 Drift 로컬 캐시
  domain/
    entity/                       Smartphone, Cpu, Gpu, Soc, Brand, Score
    repository/                   추상 인터페이스
  data/
    dto/                          freezed + json_serializable
    repository_impl/
  feature/
    home/  rank/  compare/  ask/  you/
    detail/  picker/  scan/  viewer/  onboard/  login/
      ├ presentation/  (widget)
      ├ controller/    (riverpod notifier)
      └ ...
  shared/                        재사용 위젯 (SpecRow, ScoreStrip, IndexNumeral …)
test/
  unit/  widget/  golden/
```

### 3.1 스택 결정

| 영역 | 채택 | 이유 |
|---|---|---|
| 상태관리 | **Riverpod (code-gen)** | v1의 `setState` 난립 해소, 비동기 캐싱 내장 |
| 라우팅 | **go_router** | 딥링크(`techpicks://device/galaxy-s25`) 필요 |
| 모델 | **freezed + json_serializable** | 위 스키마를 손으로 파싱하지 않음 |
| 네트워크 | **dio** + 재시도/캐시 인터셉터 | 정적 덤프는 ETag 캐싱이 잘 먹는다 |
| 로컬 | **Drift** | 93,396개 폰 오프라인 검색 인덱스 |
| 차트 | **없음** | 확정 디자인에 차트가 없다. 점수는 5구간 막대 스트립이라 `Container` + `FractionallySizedBox`로 충분하다. fl_chart는 제거했고 syncfusion도 `Phone.dart`와 함께 사라진다 |
| AI | **firebase_vertexai** 유지, 모델 ID 교체 | §5.4 |
| 인증 | Firebase Auth 유지 | 재작성 불필요 |

---

## 4. 기능 매핑 — v1 → v2

| v1 화면 | v2 처리 |
|---|---|
| `Phone.dart` 하드코딩 4종 | `/v1/smartphones` 93,396종 + 필터/정렬 |
| `CPU.dart` (내 기기 정보) | `/v1/cpus` 3,977종 제품 DB로 **의미 자체를 교체**. 내 기기 정보는 "내 기기 비교" 보조 기능으로 강등 |
| `Laptop.dart` WebView | `/v1/laptops` 1,951종 네이티브 화면. **WebView 전면 제거** |
| `RankingCPU/Phone/Laptop.dart` WebView 3종 | 인앱 `rank` 화면 하나로 통합. 5개 축(TP Index/배터리/카메라/가치/가격) 정렬. 이 셋을 지우면 필요 없던 위치 권한 요청도 같이 사라진다 |
| `Model3D.dart` WebView | 다크 테이크오버 `viewer` 화면으로 재설계됨. 모델 파일은 아직 없어 와이어프레임 대역 |
| `Scan.dart` (동작 안 함, §5.4) | Gemini 멀티모달로 재작성 → 인식 결과를 `/v1/search`로 연결 |
| `ChatAI.dart` | TechAPI 레코드를 컨텍스트로 주입하는 RAG형 상담 |
| `Test.dart`, `More.dart`(0바이트), `CPUTutorial.dart`(0바이트) | 삭제 |
| 파일마다 중복된 `main()` 5개 | 삭제 |

---

## 5. 알려진 리스크와 대응

### 5.1 정적 덤프에는 검색·비교 엔드포인트가 없다
`/v1/smartphones/index.json`(전체 목록)을 최초 1회 받아 Drift에 인덱싱하고, 검색·비교는 **로컬에서 수행**한다. 목록 인덱스는 slug/name/brand 정도의 경량 필드만 담기므로 현실적인 크기다. 실제 응답 크기는 Phase 1 착수 시 반드시 계측할 것 — 예상보다 크면 브랜드별 샤딩으로 전환한다.

### 5.2 `api.techapi.dev`는 아직 없다
`TechApiClient`를 **덤프 모드 / REST 모드** 두 전략으로 추상화해 두고, 기본값은 덤프. 서버가 뜨면 설정 한 줄로 전환.

### 5.3 라이선스 의무
데이터는 CC-BY-SA 4.0. 앱 내 "데이터 출처" 화면과 각 상세 화면의 `source_urls` 노출은 **법적 요구사항**이다. 누락 시 라이선스 위반.

### 5.4 v1에서 이월된 실제 버그 (재구축 시 반드시 수정)
- `Scan.dart:79` — 이미지를 base64 문자열로 만들어 **텍스트 프롬프트에 이어붙이고** 있다. Gemini에 이미지를 넘기려면 `Content.multi([TextPart(...), InlineDataPart('image/jpeg', bytes)])` 형태여야 한다. 현재 코드는 동작할 수 없다.
- `ChatAI.dart:95`, `Scan.dart:46` — 모델 ID `gemini-flash-experimental`은 유효한 식별자가 아니다.
- `LoginPage.dart:20` — 개발자 이메일이 평문 하드코딩되어 있고 권한 검사가 클라이언트에서 이뤄진다. v2에서는 Firebase Custom Claims로 이전.
- `firebase_options.dart`와 `macos/Runner/GoogleService-Info.plist`가 저장소에 커밋되어 있다. Firestore/Storage 보안 규칙 점검 필요.

### 5.5 미사용 의존성
`google_ml_kit`, `tflite_flutter`, `camera`, `firebase_ml_model_downloader`가 pubspec에 있으나 코드에서 전혀 쓰이지 않는다. 이들이 Android 빌드 시간의 상당 부분을 차지한다. v2 pubspec에서 제외하고, OCR이 실제로 필요해질 때 다시 넣는다.

---

## 6. Git-flow 브랜치 구조

TechAPI가 이미 git-flow를 쓰고 있으므로 **조직 전체 규칙을 그대로 따른다.**

```
main         릴리스 상태. 태그(v2.0.0)와 스토어 배포만 여기서.
             develop → main 릴리스 PR로만 이동.
develop      통합 브랜치. 모든 작업 브랜치의 타깃. 기본 브랜치로 지정.
feat/*       기능        예: feat/device-detail
fix/*        버그        예: fix/score-radar-overflow
chore/*      빌드·설정   예: chore/gradle-9-upgrade
docs/*       문서
release/*    릴리스 준비 (버전 범프, 체인지로그)
hotfix/*     main에서 잘라 main+develop 양쪽에 머지
```

### 6.1 전환 절차

```bash
# 1) 현재 작업(Gradle 9 마이그레이션)을 chore 브랜치로 분리
git switch -c chore/gradle-9-upgrade
git add -A && git commit -m "chore: migrate to Gradle 9.1 / AGP 8.13 toolchain"

# 2) develop 생성 (main 기준)
git switch main
git switch -c develop
git push -u origin develop

# 3) 기본 브랜치를 develop으로 변경
gh repo edit Seungpyo1007/TechPicks --default-branch develop

# 4) main 보호 — 릴리스 PR 외 직접 푸시 차단
gh api -X PUT repos/Seungpyo1007/TechPicks/branches/main/protection \
  -f "required_pull_request_reviews[required_approving_review_count]=0" \
  -F "enforce_admins=true" -F "restrictions=null" \
  -F "required_status_checks=null"

# 5) chore 브랜치를 develop으로 PR
git switch chore/gradle-9-upgrade
git push -u origin chore/gradle-9-upgrade
gh pr create --base develop --title "chore: Gradle 9.1 / AGP 8.13 toolchain" --fill
```

> `gh repo edit`과 브랜치 보호는 원격 저장소 설정을 바꾸는 작업이다. 실행 전 확인 필요.

### 6.2 v2 작업 브랜치 계획

`develop`에서 잘라 아래 순서로 진행. 각각 독립 PR.

```
feat/v2-skeleton          디렉터리 구조 + Riverpod/go_router 골격
feat/techapi-client       TechApiClient + freezed DTO + 단위 테스트
feat/design-system        디자인 토큰 → ThemeData + 공용 위젯
feat/device-list          목록/필터/정렬
feat/device-detail        상세 + 스코어 스트립 + 출처 표기
feat/compare              비교 화면
feat/search               Drift 로컬 인덱스 검색
feat/chat-rag             TechAPI 컨텍스트 주입 AI 상담
chore/remove-legacy       v1 화면·미사용 의존성 제거
```

---

## 7. 단계별 로드맵

| Phase | 산출물 | 완료 기준 |
|---|---|---|
| **0. 정지 작업** | `chore/gradle-9-upgrade` 머지, git-flow 전환 | `develop`이 기본 브랜치, CI 통과 |
| **1. 데이터 계층** | `TechApiClient`, DTO, 리포지토리 | 위젯 없이 **테스트만으로** galaxy-s25를 파싱해 score 5축을 뽑아낼 수 있음 |
| **2. 디자인 시스템** | 토큰·테마·공용 위젯 | 라이트/다크 골든 테스트 통과 |
| **3. 핵심 화면** | 목록 / 상세 / 비교 | 하드코딩 데이터 0줄 |
| **4. 검색·랭킹** | Drift 인덱스, 랭킹 | 오프라인에서 검색 동작 |
| **5. AI·부가** | RAG 상담, OCR 스캔 | 실제 이미지로 기종 인식 성공 |
| **6. 릴리스** | `release/v2.0.0` → `main` | 서명키 적용, `applicationId` 확정 |

---

## 8. 지금 즉시 해결할 것 — `main.dart`에 뜨는 X 표시

**코드 문제가 아니다.** 확인 결과:

```
$ dart analyze lib/main.dart
   info - main.dart:38:9 - Parameter 'key' could be a super parameter … use_super_parameters
1 issue found.
```

에러는 0건이고 `info` 1건뿐이다. `.dart_tool/package_config.json`에도 `permission_handler`, `firebase_core`, `firebase_vertexai`, `rive`가 모두 정상 등록돼 있다.

원인은 **IDE(Android Studio/IntelliJ)의 Dart 분석 서버 캐시**다. 이번에 `pubspec.yaml`(permission_handler 10 → 12)과 Gradle 툴체인을 바꿨는데, 열려 있던 IDE가 예전 패키지 구성을 붙들고 있으면 해결되지 않은 import가 있는 것처럼 빨간 X를 띄운다.

해결 순서:

1. **File → Invalidate Caches… → Invalidate and Restart**
2. 재시작 후 **Tools → Flutter → Flutter Pub Get**
3. 그래도 남으면 **Help → Find Action → "Restart Dart Analysis Server"**

`use_super_parameters` info를 없애려면 `lib/main.dart:38`을 이렇게 고친다:

```dart
// before
const MyApp({ Key? key, required this.isDarkMode, required this.isTutorialCompleted })
    : super(key: key);

// after
const MyApp({ super.key, required this.isDarkMode, required this.isTutorialCompleted });
```

다만 v2에서 `main.dart`는 어차피 전면 재작성되므로 우선순위는 낮다.

---

## 9. 검증 방법

- **데이터 계층**: `dart test test/unit/tech_api_client_test.dart` — 실제 덤프 URL 픽스처로 galaxy-s25 파싱, score 5축 검증
- **디자인**: 골든 테스트로 라이트/다크 스냅샷 비교
- **엔드투엔드**: `flutter run -d emulator-5554` 후 홈 → 검색 → 상세 → 비교 경로를 실기기에서 확인
- **회귀**: `flutter analyze`가 **에러 0, 경고 0** (v1은 경고 8건 + info 355건)

---

## 부록 A. TechApiClient 인터페이스 초안

```dart
abstract class TechApiSource {
  Uri detail(String collection, String slug);
  Uri list(String collection);
}

/// GitHub Pages 정적 덤프 — 현재 유일하게 살아있는 경로
class DumpSource implements TechApiSource {
  static const base = 'https://gettechapi.github.io/TechAPI';
  @override Uri detail(String c, String s) => Uri.parse('$base/v1/$c/$s/index.json');
  @override Uri list(String c)             => Uri.parse('$base/v1/$c/index.json');
}

/// api.techapi.dev 배포 후 전환
class RestSource implements TechApiSource {
  const RestSource(this.base);
  final String base;
  @override Uri detail(String c, String s) => Uri.parse('$base/v1/$c/$s');
  @override Uri list(String c)             => Uri.parse('$base/v1/$c');
}
```
