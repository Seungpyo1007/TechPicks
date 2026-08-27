# Web design fidelity

이 문서는 `site/` 의 화면이 어떤 원본을 따르는지, 어디서 의도적으로 벗어났는지를 적는다.

## 정본

디자인 정본은 **`TechPicks Web M3.dc.html`** 하나다. (`TechPicks 웹 버전 디자인.zip`)

- 로그인 화면은 같은 스타일의 `login-c.dc.html` 을 함께 참조한다.
- 팔레트·타이포·그림자: 번들된 Industry 디자인 시스템 `_ds/industry-…/styles.css` 의 `:root`
- 라운드/알약/틴트 오버라이드: 정본 문서의 `<style>` 블록
- 다크 값: 정본 스크립트 상단의 `DARK` 맵
- 구버전 `TechPicks Web.dc.html`(Barlow Condensed, 각진 blueprint)은 **쓰지 않는다.**

ZIP 안의 `support.js` / `techpicks-data.js` / `_ds_bundle.js` 는 디자인 캔버스 런타임이라
제품 코드에 넣지 않았다. 마크업 구조, 픽셀 값, 애니메이션 타이밍만 옮겼다.

## 팔레트가 앱과 다른 이유

| | 값 | 출처 |
| --- | --- | --- |
| 앱 (Flutter) | `#0C78D8` | 로고 `NBlogo_black.png` 샘플링 — `lib/app/theme/tp_tokens.dart` |
| 웹 | `#5980a6` | 디자인 정본의 액센트 |

정본은 `accent` 를 교체 가능한 prop 으로 선언해 뒀지만, 기본값인 슬레이트를 그대로 쓰기로 했다.
그래서 `shared/tokens/techpicks.css`(앱 브랜드 계약)는 **웹이 import 하지 않는다.**
웹 토큰은 `site/styles/tokens.css` 에 따로 있다.

## 화면 대응

| 정본 화면 | 웹 경로 | 색인 |
| --- | --- | --- |
| 홈 / 대시보드 | `/` | O |
| 스마트폰 | `/phones`, `/phones/[slug]` | O (154 SSG) |
| CPU | `/cpus`, `/cpus/[slug]` | O (40 SSG) |
| 노트북 | `/laptops` | O |
| 비교 | `/compare?type=phone\|cpu\|laptop&ids=a,b[,c]` | O |
| (원본에 없음) 조립 견적 | `/build?use=&budget=&cpu=&gpu=` | O |
| OCR 스캔 | `/scan` | X |
| 3D 뷰어 | `/viewer` | X |
| 프로필 | `/profile` | X |
| 로그인 | `/login` | X |

로그인은 **게이트가 아니다.** 랭킹·상세·비교는 로그인 없이 열린다.

정본은 클라이언트 상태로 화면과 선택 제품을 바꿨지만, 웹에서는 제품마다 실제 URL 이 있어야
검색에 잡힌다. 그래서 마스터-디테일의 선택은 라우팅으로, 데스크톱/모바일 분기는 JS 대신
CSS 미디어쿼리로 처리한다(서버 HTML 이 하나여야 하이드레이션이 어긋나지 않는다).

## 의도적 편차

정본 프로토타입의 `techpicks-data.js` 는 손으로 큐레이션한 15종이라 **원시 벤치마크 수치**를
갖고 있었다(예: Geekbench 멀티 10,558). 제품 데이터 원천인 TechAPI v1 은 원시 벤치를 발행하지
않고 **0–100 정규화 지수 + percentile + tier + source** 만 발행한다.

레이아웃·막대·표 구조는 정본 그대로 두고 **라벨과 단위만** 바꿨다. 없는 숫자를 만들지 않는다.

1. `Geekbench 싱글 / 멀티` → `Geekbench CPU 지수` / `AnTuTu 시스템 지수` (0–100)
   - 근거: SoC 레코드의 `score.cpu.source = "geekbench"`, `score.system.source = "antutu_score"`
2. 홈의 `CPU 멀티코어 상위 5` 캡션 → `Cinebench R23 멀티코어 지수 · TechAPI 채점값`
   - 근거: CPU 레코드의 `score.multi.source = "cinebench_r23_multi"`
3. 레이더 다섯 번째 축 `기능` → `가치`
   - 정본의 `기능` 은 방수·무선충전에서 파생한 값이었는데 카탈로그에 대응 채점 축이 없다.
     새 점수를 만드는 대신 카탈로그가 실제로 채점하는 `value` 를 쓴다. (`site/lib/score.ts`)

## 원본에 없던 추가

- **조립 견적 `/build`** — 원본 정본에 없는 화면이다. 사이드바가 8개에서 9개가 되고,
  홈 타일의 `북마크`(자리표시라 `/phones` 로 가던 항목)를 `조립` 으로 바꿨다.
  화면 언어는 정본 그대로 쓴다 — 용도 탭은 비교 화면의 알약, 요구사양 행은 노트북 카드의 행.
  실제 제품을 고르는 것은 CPU 와 GPU 뿐이다. TechAPI 에 메인보드·메모리·저장장치·파워·케이스가
  없어서, 그 부품들은 소켓·메모리 규격·권장 파워 같은 **도출 요구사양**으로만 제시한다.
  데이터는 `site/data/desktop-parts.json` (`pnpm sync:parts`).
- **대비 토큰** — 정본 팔레트를 그대로 두되 글자가 놓이는 조합만 WCAG AA 를 넘기게 고정했다.
  다크 모드에서 홈 히어로가 배경 `--color-accent-900` 에 글자 `--color-neutral-100` 이라
  대비 1.08 로 사실상 보이지 않았다. 자세한 값은 `site/styles/tokens.css` 주석.
  검사는 `site/scripts/audit-contrast.mjs`.
- `Web beta 0.0.2` 표기는 제거했다.
- `@media (prefers-reduced-motion: reduce)` — 정본에는 없지만 접근성상 필요하다.
  `tp-*` 애니메이션을 전부 멈춘다.
- 상세 화면의 `앱에서 열기` 링크 (`techpicks://device/{slug}`) — 앱↔웹 URL 매핑을 화면에서도
  드러낸다. 매핑표는 `docs/HANDOFF.md`.

## 데이터 출처

- 스마트폰 154 · CPU 40 · SoC 30: `assets/catalog/v1.json` (Flutter 앱이 번들하는 것과 같은 파일)
- 상세 화면은 TechAPI 원격을 먼저 조회하고 실패하면 카탈로그로 폴백한다 (`site/lib/techapi.ts`)
- 노트북 9종: `site/data/laptops.json` — `pnpm sync:laptops` 로 TechAPI `/v1/laptops/` 에서 갱신.
  카탈로그에 노트북이 없고 빌드는 네트워크 없이도 같은 결과를 내야 해서 스냅샷을 커밋한다.
- 데스크톱 CPU 69종 · GPU 101종: `site/data/desktop-parts.json` — `pnpm sync:parts`.
  앱 카탈로그의 CPU 40건은 전부 노트북용(`segment: "laptop"`)이라 조립에 쓸 수 없다.
