# TechPicks 재구축 계획서

> 작성 2026-08-07 · 갱신 2026-08-08 · 브랜치 `feat/design-handoff` · v1.0.1beta → v2.0.0
>
> **화면 열넷과 데이터 계층이 다 올라왔다.** 아래 계획 중 실제로 채택한 것과
> 바꾼 것을 §3.1 과 §8 에 적어뒀다. 남은 일은 §9.

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
  main.dart                      Firebase·번역 초기화 후 앱 실행
  app/
    app.dart                     온보딩 → 로그인 → 탭
    tab_host.dart                탭 5개 + 푸시 화면(상세·선택·스캔·뷰어)
    providers.dart               Riverpod 프로바이더 전부
    locale_controller.dart       언어 전환
    shell/                       크롬(헤더·탭 바·인셋), 탭 정의
    theme/                       토큰·타이포·ThemeData
  core/
    network/                     TechApiSource(덤프/REST), TechApiClient
    failure.dart  result.dart    Result<T> 와 실패 분류
  domain/
    model/                       TpIndex·TpWeights·Ranking·DeviceSpecs·
                                 Movers·ScanMatch·AskAnswer
    repository/                  추상 인터페이스
  data/
    dto/                         freezed + json_serializable
    repository/                  TechApiRepository, CatalogRepository
    service/                     AskService, AuthService
  feature/
    home/ rank/ compare/ detail/ ask/ you/
    login/ onboarding/ scan/ viewer/
  shared/
    copy_keys.dart               번역 키 상수
    spec_labels.dart             상세·비교 공용 라벨
    widgets/                     TpSurface·TpChip·TpScoreStrip·TpTapTarget
test/
  unit/  widget/  support/harness.dart
tool/
  build_catalog.dart             카탈로그 애셋 굽기
  gen_idea_libs.dart             IDE 설정 복구
  smoke_techapi.dart             원격 왕복 확인
```

### 3.1 스택 결정

| 영역 | 채택 | 비고 |
|---|---|---|
| 상태관리 | **Riverpod** (수동 프로바이더) | 계획은 code-gen 이었다. build_runner 를 하나 더 태울 만큼 얻는 게 없어 손으로 쓴다 |
| 라우팅 | **Navigator** | 계획은 go_router 였다. 명세에 딥링크 요구가 없고 back stack 이 한 단계뿐이라 필요가 없었다. 딥링크가 생기면 그때 바꾼다 |
| 모델 | freezed + json_serializable | 그대로 |
| 네트워크 | dio | 그대로 |
| 로컬 | **없음** | 계획은 Drift 로 93,396개를 인덱싱하는 것이었다. 목록 인덱스가 19MB 라 앱에서 받을 수 없어 폐기했다. §5.1 참조 |
| 차트 | **없음** | 확정 디자인에 차트가 없다. 점수는 5구간 막대라 `Container` + `FractionallySizedBox` 로 충분하다 |
| 번역 | easy_localization | EN/KO 133키. 언어 전환은 즉시 반영 |
| AI | firebase_vertexai + 로컬 대체 구현 | 기본은 로컬. Firebase 설정이 없어도 화면이 죽지 않아야 한다 |
| 인증 | Firebase Auth | 인터페이스로 감싸 테스트가 Firebase 를 띄우지 않는다 |

---

## 4. 기능 매핑 — v1 → v2

| v1 화면 | v2 처리 |
|---|---|
| `Phone.dart` 하드코딩 4종 | `/v1/smartphones` 93,396종 + 필터/정렬 |
| `CPU.dart` (내 기기 정보) | 제품 DB 는 랭킹 화면이 맡는다. 내 기기 정보는 You 화면의 한 줄로 옮겼고, 카탈로그에 있으면 지수를 붙여 상세로 보낸다 |
| `Laptop.dart` WebView | `/v1/laptops` 1,951종 네이티브 화면. **WebView 전면 제거** |
| `RankingCPU/Phone/Laptop.dart` WebView 3종 | 인앱 `rank` 화면 하나로 통합. 5개 축(TP Index/배터리/카메라/가치/가격) 정렬. 이 셋을 지우면 필요 없던 위치 권한 요청도 같이 사라진다 |
| `Model3D.dart` WebView | 다크 테이크오버 `viewer` 화면으로 재설계됨. 모델 파일은 아직 없어 와이어프레임 대역 |
| `Scan.dart` (동작 안 함, §5.4) | Gemini 멀티모달로 재작성 → 인식 결과를 `/v1/search`로 연결 |
| `ChatAI.dart` | TechAPI 레코드를 컨텍스트로 주입하는 RAG형 상담 |
| `Test.dart`, `More.dart`(0바이트), `CPUTutorial.dart`(0바이트) | 삭제 |
| 파일마다 중복된 `main()` 5개 | 삭제 |

---

## 5. 알려진 리스크와 대응

### 5.1 목록 인덱스가 19MB 다

계획은 `/v1/smartphones/index.json` 을 받아 Drift 에 인덱싱하는 것이었다.
실측하니 **19,797,065 바이트 / 93,396건**이라 앱에서 받을 수 없다. 게다가 그
인덱스에는 `slug`/`name`/`url` 만 있고 점수가 없어서 정렬에도 못 쓴다.
관계 엔드포인트(`/brands/{slug}/smartphones`)는 덤프에 없다 — 404 다.

명세가 같은 상황을 예상하고 답을 적어뒀다.

> until then ship it as a versioned JSON asset so scores can be updated
> without a store release

`tool/build_catalog.dart` 가 큐레이션한 slug 목록으로 상세를 받아
`assets/catalog/v1.json` 을 굽는다. 2025 플래그십 10종 + CPU 2 + SoC 1,
30.7KB. 상세 화면처럼 기기 하나만 필요한 곳은 카탈로그를 거치지 않고
`TechApiRepository` 로 직접 받는다.

데이터셋에 정제되지 않은 레코드가 섞여 있다. 목록 첫 항목이
`slug: "1", name: "1"` 이고 `socs` 에도 `slug: "0"` 이 있다. 검색을 붙일 때
걸러야 한다.

### 5.2 `api.techapi.dev`는 아직 없다
`TechApiClient`를 **덤프 모드 / REST 모드** 두 전략으로 추상화해 두고, 기본값은 덤프. 서버가 뜨면 설정 한 줄로 전환.

### 5.3 라이선스 의무
데이터는 CC-BY-SA 4.0. 앱 내 "데이터 출처" 화면과 각 상세 화면의 `source_urls` 노출은 **법적 요구사항**이다. 누락 시 라이선스 위반.

### 5.4 v1 에서 이월된 버그 — 처리됨

파일이 통째로 사라져 자연히 해결된 것과, 새로 쓰면서 고친 것이 섞여 있다.

| 버그 | 처리 |
|---|---|
| `Scan.dart:79` 이미지를 base64 문자열로 프롬프트에 이어붙임 | 파일 삭제. 새 스캔은 인식 결과를 `ScanMatcher` 로 카탈로그에 맞춘다 |
| 모델 ID `gemini-flash-experimental` (존재하지 않음) | `GeminiAskService.modelId` 를 유효한 값으로. 테스트가 `experimental` 포함 여부를 막는다 |
| `LoginPage.dart:20` 개발자 이메일 평문·클라이언트 권한 검사 | 파일 삭제. v2 로그인에는 그런 분기가 없다 |
| `firebase_options.dart` 커밋됨 | 그대로다. 클라이언트 키라 공개돼도 치명적이지 않지만 **보안 규칙 점검은 남아 있다** (§9) |

### 5.5 미사용 의존성 — 정리됨

v1 화면과 함께 11개를 걷어냈다. `webview_flutter` 와 `permission_handler` 가
나가면서 랭킹 웹뷰가 요구하던 위치 권한도 사라졌고, `syncfusion_flutter_charts`
가 나가면서 상용 라이선스 문제도 끝났다.

디버그 APK 295MB → 75MB.

`device_info_plus` 는 다시 넣었다. 명세가 "내 기기 정보는 You 화면에 속한다"고
했고 그 자리에 붙였다. `google_sign_in` 은 `google-services.json` 이
온전해지면 쓴다.

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

### 6.2 실제로 나간 순서

`feat/design-handoff` 한 브랜치에 쌓았다. 계획은 기능마다 브랜치를 자르는
것이었는데, 화면이 서로 물려 있어 쪼개도 따로 리뷰할 수 없었다.

```
디자인 핸드오프 반입          TechPicks-Web 에서 옮기고 그 저장소는 삭제
토큰 + 두 크롬 셸
TP Index + 가중치
카탈로그 애셋 + 랭킹 계산
랭킹 → 상세 → 비교/선택 → 홈 → 내 정보 → 상담 → 온보딩/로그인 → 스캔/뷰어
화면 연결 (탭 호스트, main.dart 교체)
v1 화면 26개와 의존성 11개 삭제
번역 이관 (EN/KO 133키)
언어 즉시 전환, 이메일 로그인
접근성 — 탭 타깃·라벨·대비·스크린 리더 문장
```

---

## 7. 명세의 빌드 순서 — 전부 완료

`docs/DESIGN_HANDOFF.md` 의 "Suggested build order" 여덟 단계를 그 순서대로 했다.

| # | 내용 | 결과 |
|---|---|---|
| 1 | 토큰 + 두 크롬 셸 | iOS 유리 / Android M3, 안전 영역 기준으로 환산 |
| 2 | 데이터 모델 + TP Index | 빈 축은 0점이 아니라 계산에서 제외 |
| 3 | 랭킹 → 상세 → 비교 | 웹뷰 3개와 위치 권한이 사라졌다 |
| 4 | 홈 | 결론 카드·shortlist·이번 주 변동 |
| 5 | 내 정보 | 가중치 슬라이더가 앱 전체 지수를 다시 계산한다 |
| 6 | 상담 | 응답을 `{pick, reason, rows[]}` 로 받아 표로 그린다 |
| 7 | 온보딩 + 로그인 | 되돌릴 수 없던 건너뛰기 경고를 없앴다 |
| 8 | 스캔 + 3D 뷰어 | 인식 결과를 카탈로그에 맞춘다 |

빌드 순서에 없던 화면 두 개가 명세 본문에는 있다. §5 Processors 는 만들었고
(§9), §6 Laptops 는 데이터가 없다.

### 7.1 화면을 다 만든 뒤에 나온 것들

명세 본문과 코드를 한 줄씩 대조하면서 나온 것들이다. 대부분 "만들어는 놨는데
연결이 없다" 쪽이었다.

| 무엇 | 어땠나 |
|---|---|
| 이번 주 변동 | 순위 스냅샷을 저장하는 곳이 없어 섹션이 한 번도 안 떴다 |
| 비교의 "왜?" | 두 기기를 상담에 넘기는 메서드가 있는데 버튼은 탭만 바꿨다 |
| 계정 없이 둘러보기 | 익명 로그인이 실패하면 앱에 들어갈 방법이 없었다 |
| `Sign up` 링크 | 가입 화면 대신 로그인을 건너뛰었다 |
| 온보딩 | 저장값을 읽기 전에 한 프레임 스쳐 지나갔다 |
| 카드 누름 | 두 플랫폼 다 리플이었다 (명세는 iOS 밝기 +4%) |
| 푸시 전환 | Android 가 zoom 이었다 (명세는 shared axis X) |
| shortlist 지우기 | 스와이프만 있고 길게 누르기가 없었다 |
| 헤더 앱 마크 | 빠져 있었다 |
| 상담 답 | 모델이 카탈로그 밖의 기기를 골라도 그대로 띄웠다 |

접근성 쪽은 따로 적어둔다. 맨 `GestureDetector` 는 시맨틱 트리에 탭 액션을
만들지 않아서 기존 `labeledTapTargetGuideline` 검사를 통째로 빠져나갔다.
칩·설정 행·로그인 버튼·탭 바 13 군데가 스크린 리더에는 그냥 글자였다.

---

## 8. 계획과 다르게 간 것

| 계획 | 실제 | 이유 |
|---|---|---|
| go_router | Navigator | 딥링크 요구가 없고 back stack 이 한 단계다 |
| Drift 로컬 인덱스 | 큐레이션 카탈로그 애셋 | 목록 인덱스가 19MB (§5.1) |
| fl_chart 로 단일화 | 차트 라이브러리 없음 | 확정 디자인에 차트가 없다. 정작 미사용이던 쪽이 fl_chart 였다 |
| Riverpod code-gen | 수동 프로바이더 | build_runner 를 하나 더 태울 이유가 없다 |
| 기능별 브랜치 | 한 브랜치 | 화면이 서로 물려 있어 따로 리뷰가 안 된다 |

명세 값을 바꾼 곳은 색 세 군데뿐이다. 전부 WCAG AA 미달이라 최소로 조정했고
실측값을 `lib/app/theme/tp_tokens.dart` 주석에 남겼다.

---

## 9. 남은 일

- **다크 모드** — 명세의 토큰 표가 라이트 한 벌뿐이다. 색을 지어내지 않고
  자리만 뒀다. 디자인 쪽에서 다크 토큰을 받아야 한다.
- **`google-services.json`** — `oauth_client` 가 비어 Google 로그인이 안 된다.
  Firebase 콘솔의 실제 파일이 필요하다.
- **iOS/macOS 빌드** — CocoaPods 미설치, `ios/Runner/GoogleService-Info.plist` 없음.
- **릴리스 서명·applicationId** — `com.example.techpicks` 는 스토어가 거부한다.
- **Firestore/Storage 보안 규칙** — v1.0.1beta 가 공개돼 있고 실제 프로젝트를 문다.
- **카메라·OCR** — 스캔 화면은 인식 결과를 받아 맞추는 부분까지만 있다.
- **Laptops 화면 (명세 §6)** — TechAPI `laptops` 는 1,951종인데 점수가 하나도
  없다. 25종을 뽑아 보니 `score` 0/25, 무게 13/25, 가격 12/25 다. 명세는 카드마다
  지수를 요구하는데 그걸 만들려면 없는 값을 지어내야 한다. 랭킹 탭의 Laptops
  칩은 그래서 눌리지 않는다.
- **검색** — 카탈로그 10종 밖을 찾으려면 서버 쿼리나 브랜드별 샤딩이 필요하다.
- **제품 사진·3D 모델** — 명세도 "Not supplied" 라고 적어뒀다.

### 확인 방법

```
flutter test        408건
flutter analyze     이슈 0
dart tool/smoke_techapi.dart   원격 왕복
```

접근성 테스트는 네 갈래다.

| 파일 | 보는 것 |
|---|---|
| `a11y_test.dart` | 탭 타깃 크기·라벨·대비 가이드라인 |
| `tap_semantics_test.dart` | 탭 액션이 있는 노드가 버튼으로, 이름을 갖고 읽히는지 |
| `semantics_test.dart` | 숫자가 많은 화면이 문장으로 읽히는지 |
| `a11y_naming_test.dart` | 입력창 이름이 글자를 쳐도 남는지, 새 답을 알리는지 |

레이아웃은 `layout_test.dart` 가 명세 프레임(402×874 / 412×892)에서,
`text_scale_test.dart` 가 글자 배율 1.6 에서 넘치는지 본다.

CI 는 사용자 요청으로 꺼져 있다. 위 숫자는 로컬 결과이고 검증이 아니다.

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
