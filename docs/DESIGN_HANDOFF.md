# Handoff: TechPicks — mobile app redesign (iOS + Android)

## Overview

TechPicks helps someone **decide which device to buy**, not browse a catalogue. This handoff covers a full
redesign of the existing Flutter app (`github.com/Seungpyo1007/TechPicks`) as **13 screens on two platform
chromes** (iOS 26 "Liquid Glass" and Android Material 3), in **two languages** (en-US, ko-KR).

The product model changed from the current app:

| Today | This design |
| --- | --- |
| Home is 8 circular icons + a "Where to?" search bar left over from a maps template | Home is a working **shortlist** — the devices you are deciding between, with a live verdict |
| Rankings are a `WebView` of `nanoreview.net` with elements deleted by injected JS | Rankings are **in-app**, sortable on 5 axes, from the TechPicks dataset |
| Comparison = tap a list, read a Syncfusion radial chart | Comparison is a **tab** — two devices, one spec table, the winner marked per row |
| Five category tabs (Home / CPU / Phone / Laptop / Profile) | Five **task** tabs (Home / Rank / Compare / Ask / You); categories live inside Rank |
| Scan + 3D listed as "지원 예정" | Both designed as full-bleed takeover screens |
| Scores appear with no explanation | One **TP Index** with its five components always visible, and user-editable weights |

---

## About the Design Files

**The bundled HTML is a design reference, not production code.** `index.html` is a browser
prototype: React-in-HTML with inline styles, rendered twice (once per platform) inside device-frame
components. It exists to show intended look and behaviour precisely.

**The task is to recreate these designs in the target codebase.** The target here is the existing
**Flutter** app (`pubspec.yaml`, `lib/`), so:

- Build with Flutter widgets and the app's existing packages. Do **not** port the HTML/CSS.
- iOS chrome → Cupertino-flavoured widgets + `BackdropFilter` for the glass. Android chrome → Material 3
  (`useMaterial3: true`, `SliverAppBar.large`, `NavigationBar`).
- Copy already lives in `assets/translations/en-US.json` / `ko-KR.json` via `easy_localization`. Extend
  those files with the new keys in the **Copy** table below; keep `.tr()` call sites.
- If a screen has no equivalent today (Compare, Scan result, 3D viewer), create it under
  `lib/MainPage/MenuPage/`.

If you are implementing outside Flutter, pick the platform-native path (SwiftUI + Jetpack Compose) rather
than a web layer — the design leans on platform chrome that a webview cannot fake.

---

## Fidelity

**High-fidelity.** Colours, type, spacing, radii, shadows and copy are final and listed below. Recreate
faithfully. Two deliberate placeholders remain:

1. **Product photography** — the detail screen has an empty image slot. No device photos were available.
   Supply real 3:2 product shots or keep the slot.
2. **3D models** — the viewer screen shows the chrome and controls around a model, with the model itself
   drawn as a wireframe stand-in.

---

## Design Tokens

### Shared

| Token | Value | Use |
| --- | --- | --- |
| `blue` | `#0C78D8` | Primary. Sampled from the app's own `NBlogo_black.png` mark. |
| `blueDark` | `#0B5490` | Gradient end, pressed state. |
| `blueLight` | `#0090F0` | Gradient start on bars/highlights. |
| `graphite` | `#484848` | Neutral ink from the same logo. |
| `ink` | `#14161A` | Body text. |
| Tab bar fill (both platforms) | `#E6EBF4` | Android nav bar; iOS uses the glass capsule instead. |

There is **no red anywhere.** The palette comes out of the logo.

### iOS — Liquid Glass

| Token | Value |
| --- | --- |
| Font | `-apple-system, "SF Pro Text", "SF Pro Display", system-ui` |
| Semibold weight | `600` |
| Page background | `linear-gradient(180deg,#eef3fa 0%,#e4ecf6 42%,#eaf1f9 78%,#f1f5fb 100%)` |
| Card fill | `rgba(255,255,255,.58)` |
| Card fill (strong) | `rgba(255,255,255,.72)` |
| Blur | `blur(26px) saturate(180%)` |
| Card shadow | `inset 0 1px 0 rgba(255,255,255,.85), 0 1px 2px rgba(18,38,68,.06), 0 10px 28px rgba(18,38,68,.08)` |
| Glass edge (chrome) | `inset 0 1px 0 rgba(255,255,255,.92), inset 0 -0.5px 0 rgba(20,40,70,.06), 0 6px 22px rgba(15,35,65,.15)` |
| Chrome blur | `blur(34px) saturate(200%)` |
| Chrome fill | `rgba(250,251,253,.62)` (controls) / `rgba(250,251,253,.66)` (tab capsule) |
| Button shadow | `0 6px 18px rgba(12,120,216,.32)` |
| Specular highlight | `linear-gradient(90deg,transparent,rgba(255,255,255,.95),transparent)` — 1px, top edge of cards |
| Radii | card `28`, inner `22`, control `999`, icon tile `26` |
| Hairline | `rgba(20,40,70,.08)` · Track `rgba(20,40,70,.09)` |
| Bar fill | `linear-gradient(90deg,#0C78D8,#0090F0)` |
| Tint fill | `rgba(12,120,216,.12)` · Chip `rgba(255,255,255,.7)` · Input `rgba(255,255,255,.72)` |
| Hero fill | `linear-gradient(135deg,#0C78D8,#0B5490)`, ink `#fff`, chip `rgba(255,255,255,.22)` |
| Dim text | `rgba(20,30,45,.55)` |

**Concentric radii rule:** an inner element inside a 28px card uses 22px, inside that 16px. Never equal,
never larger than the parent.

**How the glass is drawn — the chrome is the OS's own glass.** On iOS 26+ the tab capsule and the
header pill are `native_liquid_glass` platform views, i.e. SwiftUI's `.glassEffect()`: the real Liquid
Glass, drawn by the system, which bends and samples the backdrop in ways no shader of ours reproduces.
**Nothing of ours is painted on top of it** — no tint, no specular hairline, no fill, no shadow.
A first pass kept the token fill at 35% opacity and that single thin film was enough to turn the
material back into an imitation: real glass reads through what is behind it, not through a colour.
The container is `interactive`, so pressing it is the OS's own glass response rather than our scale. Geometry stays ours: 62pt tall, `left/right: 12`, capsule corners, blue pill, our
labels — all Flutter widgets stacked on top of the platform view. The package's own `LiquidGlassTabBar`
is deliberately unused: it would replace the spec'd bar with Apple's stock one.

The selected tab pill is glass too, with `blue` going in as a **tint** rather than a fill — on a glass
bar an opaque pill reads like a sticker stuck to the material. It does not *merge* with the bar the way
iOS 26's own tab bar does (`glassEffectUnion` only works inside one `GlassEffectContainer`, and each
platform view carries its own namespace), so the pill is a second glass layer riding on the first.

**The tab bar is the system's own `UITabBar`** (`LiquidGlassTabBar`), which is the only way to get the
merge and morph between the bar and its selection bubble — that happens inside one
`GlassEffectContainer`, and stacking two platform views cannot fake it. Icons are SF Symbols; the
labels, the accent and the 62pt height are still ours.

Two things had to be handled to make it usable:

- The plugin sizes its view `height + 20` so the glass can bleed past the bar. Give it only `height`
  and the platform view overflows its box and **taps land at the wrong offset**.
- It reported selections that nobody made: one for *every* item when the bar was first laid out (five
  callbacks in the same millisecond), and one more with the previous index ~100ms after each change.
  Taken at face value, tapping Home lands on You. The cause is `didSelect` / `didSelectTab` firing for
  programmatic selection as well as taps; UIKit only calls `shouldSelect` for a real tap, so that is
  the signal to gate on. Fixed in [`third_party/native_liquid_glass`](../third_party/native_liquid_glass/PATCH.md),
  which the app uses through a `dependency_overrides` until the fix lands upstream.

Cards keep the shader glass below — one platform view per card would mean dozens in a list.

**How the glass is drawn (fallback).** CSS `backdrop-filter` gives blur and saturation but not refraction — the
prototype's edges bend the background, and a `BackdropFilter` cannot. On iOS the app renders these
tokens through `liquid_glass_widgets` (pinned `0.29.6`): chrome at `premium` (full shader — texture
capture, edge light, chromatic aberration), cards at `standard` (lightweight shader). Colour, blur and
shadow still come from the table above; the package only adds the refraction and the edge light.

The shader is gated in [`tp_glass.dart`](../lib/app/theme/tp_glass.dart) — off on Android (M3 is tonal,
blur `0`), off on web (Skia draws nothing), and off in tests (a shader that redraws every frame never
lets `pumpAndSettle` finish). When the gate is closed the same tokens render through `BackdropFilter`,
so closing it costs refraction and nothing else. Only two files import the package; a test enforces it.

**Dark theme.** The spec has no dark token table, so the values are **derived by rule, not invented**:
the page background drops to the darkest end of the same navy family (`#141E2D`), glass becomes white
at low alpha instead of white at high alpha, ink flips to near-white, and shadows get heavier because a
soft shadow is invisible on a dark ground. One token moves against the grain — the blue used for *text*
goes from `blueDark` to a light blue, since on a dark ground the contrast requirement inverts. Fills
(buttons, bars, chips) keep `blue` in both themes. Every screen is checked against the WCAG AA text
guideline in both themes (`test/widget/a11y_test.dart`); two screens are also baked as dark goldens.

The choice — System / Light / Dark — lives in You → Dark mode and is stored in `theme_mode`.

**Launch.** *(Changing the splash assets? iOS caches the launch image per device; the simulator will
keep showing the old one until you `xcrun simctl erase` it. A reinstall and a build-number bump are
not enough — this cost an afternoon once.)*

**Launch.** The native splash holds while Firebase, translations and the glass shaders warm up
(`preserve`/`remove`), and the app takes over with the *same* logo at the *same* size — 125pt, which is
`LaunchImage@3x` (375px) ÷ 3 — so the handoff is invisible. The logo then grows and fades while the
first screen rises under it. Before this there was a blank frame between the two, and the first screen
appeared with no transition. The splash has a dark variant (`#121A24`), so a dark-mode launch no
longer flashes white.

**On-device AI.** Ask runs three implementations in order — the phone's own model
(`flutter_gemma` + `flutter_gemma_builtin_ai`: Apple Foundation Models on iOS, Gemini Nano on
Android), then cloud Gemini, then a catalogue-only fallback. The user picks the order in You → AI
engine (Automatic / On this phone only / Cloud); "on this phone only" means the question never
leaves the device. Requirements are narrow — iPhone 15 Pro or newer with Apple Intelligence on,
Pixel 9 / Galaxy S25 or newer — so the sheet says why it can't be used when it can't. This raises
the iOS deployment target to **16.0**.

**Profile.** You → Edit profile opens a full screen with the photo and five fields (display name,
username, pronouns, phone, gender) — the set v1 had before the rebuild dropped everything but the
name. Pronouns are typed, not picked from a list: a list always leaves someone out. Everything but
the display name lives in Firestore `users/{uid}` under v1's own key names, so returning users still
see their values; the photo goes to Storage `profile_images/{uid}`. Both degrade to a message rather
than an error if the console side isn't set up.

**Reduce Transparency.** Flutter exposes no such flag, so the app reads `MediaQuery.highContrast` —
the neighbouring switch in the same iOS settings pane — and drops every surface to an opaque fill.
This is deliberately separate from Reduce Motion: motion sickness is not a reason to take away glass.

### Android — Material 3

| Token | Value |
| --- | --- |
| Font | `"Roboto Flex", Roboto, system-ui` |
| Medium weight | `500` (M3 never uses 600–800 for UI) |
| Page background | `#F6F8FC` (surface) |
| Container | `#EDF1F7` · Container-high `#E6EDF6` |
| Blur / card shadow / specular | none — M3 is **tonal, not translucent** |
| Button shadow | `0 1px 2px rgba(0,0,0,.18)` |
| FAB shadow | `0 3px 6px rgba(0,0,0,.16), 0 8px 20px rgba(12,120,216,.34)` |
| Radii | card `20`, inner `16`, control `999`, icon tile `24`, FAB `16` |
| Hairline | `rgba(20,40,70,.07)` · Track `#D6E2F2` |
| Bar fill | `#0C78D8` (flat) |
| Tint fill | `#D6E5F9` · Chip `#E3EBF6` · Input `#E6EDF6` |
| Hero fill | `#D6E5F9`, ink `#0A2F52`, chip `rgba(12,120,216,.16)` |
| Dim text | `rgba(20,30,45,.58)` |

### Type scale (both platforms)

| Role | iOS | Android |
| --- | --- | --- |
| Large title (screen `h1`) | 34 / 1.1 / w700 / `-0.032em` | — (lives in the large app bar) |
| Large app bar title | — | 28 / 1.15 / w400 / `0` |
| Small app bar title | 15 / w600 (in the glass pill) | 20 / 1.2 / w500 |
| Card title | 17 / w600 | 17 / w500 |
| Body | 15 / 1.4 | 15 / 1.4 |
| Secondary | 13.5 | 13.5 |
| Caption / meta | 11.5 | 11.5 |
| Tab label | 10 / w600 active | 10 / w500 |
| Section eyebrow | 11 / uppercase / `.13em` tracking | same |
| Index numeral (hero) | 62 / w700 / `-0.035em` | 62 / w500 |

### Chrome geometry

| | iOS | Android |
| --- | --- | --- |
| Frame | 402 × 874 | 412 × 892 |
| Status bar | 54px, **overlays** content | 48px, **in flow** |
| Header | floating glass controls at `top:52`, 42×42; plus a scrim gradient 0→106px, `pointer-events:none` | app bar row 64px; large-title block +88px (152px total) |
| Content padding-top | 114 (normal) / 54 (onboard, login) / **0** (scan, viewer) | 152 large bar / 64 small bar / 0 bare |
| Content padding-bottom | 122 (normal) / 190 (Ask) / 40 (bare) | 90 (normal) / 164 (with FAB) / 172 (Ask) / 0 (bare) |
| Tab bar | floating capsule, `left/right:12`, `bottom:44`, height 62, radius 999, glass | fixed bar, height 78, `#E6EBF4`, flush bottom |
| Active tab | pill fill `#0C78D8`, white icon + label | icon + label in `#0C78D8`, no pill (add the M3 pill indicator if you prefer strict M3) |
| Primary action | inline button inside content | extended FAB, 56px tall, `right:16 bottom:94`, radius 16 |

---

## Navigation & State

### State

```
platform : 'ios' | 'android' | 'both'      // prototype only — real app picks by OS
lang     : 'en' | 'ko' | 'both'            // real app: easy_localization locale
screen   : one of the 13 screen ids
prev     : screen id — single-level back stack
onb      : 0 | 1 | 2                       // onboarding pane
rankCat  : 'phones' | 'cpus' | 'laptops'
rankAxis : 'index' | 'batt' | 'cam' | 'val' | 'price'
cpuTab   : 'mobile' | 'laptop'
detailId : device id
cmpA     : device id (left column)
cmpB     : device id (right column)
pickSlot : 'a' | 'b'                       // which compare column the picker writes to
short    : device id[]                     // the shortlist — persist to SharedPreferences/Firestore
chat     : message[] | null
input    : string
scanState: 'idle' | 'done'
dark     : bool
notif    : bool
```

### Tab map

| Screen | Tab highlighted |
| --- | --- |
| `home` | Home |
| `rank`, `cpu`, `laptop` | Rank |
| `compare`, `picker` | Compare |
| `ask` | Ask |
| `you` | You |
| `onboard`, `login`, `scan`, `viewer`, `detail` | none (takeover / pushed) |

`bare` screens (`onboard`, `login`, `scan`, `viewer`) draw **no** app chrome.
`scan` and `viewer` additionally set the frame to **dark mode** (light status-bar glyphs) and start content
at y=0 so the camera view runs under the status bar.

---

## Screens

### 1. Onboarding — `onboard`

Three panes, swipe or **Next**; **Skip** top-right; pane dots at the bottom. Each pane: a large two-line
title (34/1.1/w700, `\n` is a hard break) over a 15/1.5 body, both flush left, with a schematic figure above.

| Pane | EN title | EN body |
| --- | --- | --- |
| 1 | `Every spec.\nOne number.` | TechPicks scores every device on performance, camera, display, battery and value — and always shows the parts behind the score. |
| 2 | `Two devices.\nOne table.` | Put any two side by side and read who wins each row. No charts to decode. |
| 3 | `Ask.\nThen decide.` | Tell the assistant your budget and the one thing you care about. It answers with a table, not a paragraph. |

Pane 3's button reads **Get started** and goes to `login`.
Maps to today's `lib/NewPage/FirstTutorial.dart` + `SecondTutorial.dart`; keep the
`is_tutorial_completed` SharedPreferences flag.

### 2. Login — `login`

Title `Welcome to\nTechPicks` (34/1.1/w700) + sub. Five stacked full-width buttons, 52px tall, 12px gap,
radius `rCtl` on iOS / `rCard` on Android, **left-aligned labels with the provider mark at the left**:

1. Continue with Google · 2. Continue with Apple · 3. Continue with Facebook · 4. Continue with email
   (primary blue fill) · 5. Browse without an account (text button)

Footer: `No account yet?` + `Sign up` link. Wire to the existing `firebase_auth` + `google_sign_in` flows
in `lib/LoginPage/`; `Browse without an account` → `signInAnonymously()`.

### 3. Home — `home` (the hero screen)

Scroll order:

1. **Large title** `Today` + sub `Three phones on your shortlist, one decision left.`
   (Android: the title moves into the large app bar; the sub stays in content.)
2. **Verdict card** — full-width, `cardStrong` fill. Eyebrow `Where this lands`; the leading device name
   at 22/w700; the 62px **TP Index** numeral with `TP Index` beside it; one sentence of reasoning; a
   5-segment bar strip (perf / camera / display / battery / value) each with its own track + fill;
   two actions: `Compare all` (primary) and `Ask why` (secondary).
3. **Shortlist** — section header `Shortlist` + `Add`. One row per device: index numeral (34/w700),
   name, price, chipset; a horizontal edge-fade gradient at the right of the row's spec line.
   Tap → `detail`. Swipe/long-press → remove.
4. **Movers this week** — 3 rows with position delta (`▲2` in blue, `▼1` in graphite), tap → `rank`.

Replaces `lib/MainPage/MenuPage/Home.dart` entirely. The `where_to`, `choose_bookmark` and
`set_destination_on_map` strings are dead — remove them from the translation files.

### 4. Rankings — `rank`

- Category chips row (horizontal scroll): `Phones` · `Processors` · `Laptops` → `rank` / `cpu` / `laptop`.
- **Rank by** axis chips: `TP Index` · `Battery` · `Camera` · `Value` · `Price`. Active chip = blue fill,
  white label. Re-sorts in place with a 220ms position transition.
- Rows: rank number (28/w700, blue for 1–3), name, the value on the active axis right-aligned and
  emphasised, a 3px progress track underneath scaled to the axis maximum.
- Footer note: `Ranked in-app from the TechPicks dataset — no webview, no handoff.`

This deletes the three `RankingPage/*.dart` webviews and the injected-JS DOM surgery, and with them the
location-permission prompt those screens requested (it was never needed).

### 5. Processors — `cpu`

Segmented control `Mobile` / `Laptop`, then 5 ranked rows: name, `sub` line, index numeral + track.
Footer note explains the index. Replaces `CPU.dart`, which currently shows `device_info_plus` output about
the user's own handset — that belongs on the **You** screen, not a category tab.

### 6. Laptops — `laptop`

5 cards: brand eyebrow, name, then a 4-cell spec grid (chip / screen / weight / price) and the index.

### 7. Compare — `compare`

Two device columns chosen via the header; each column head is tappable → `picker` (sets `pickSlot`).
Below, one spec table, one row per attribute:

`TP Index · Price · Screen · Chipset · Camera · Battery · OS · Weight · Thickness · Released`

The winning cell per row gets the blue tint fill + w600/w500 weight; the loser stays plain. Numeric rows
(index, price, battery) compare numerically; textual rows are marked only where a winner is unambiguous.
Bottom: `Ask why` → seeds the assistant with the two devices.

### 8. Device picker — `picker`

Pushed sheet. Title `Choose a device`, `Cancel` to dismiss. List of all devices with index + price;
tapping writes to `cmpA` or `cmpB` and pops back to `compare`.

### 9. Product detail — `detail`

1. **Image slot**, 196px tall, full card width, `slotBg` fill. Drop target in the prototype; real product
   photography in the app.
2. Brand eyebrow, name (28/w700), price, index numeral.
3. Spec rows (same attribute list as Compare).
4. 5-segment score strip.
5. Actions: `Add to shortlist` / `On your shortlist` (state-dependent), `Compare`, `View in 3D`.

### 10. Ask — `ask`

- Message list. AI messages: `cardStrong` bubble, radius `rInner`, left-aligned. User messages: blue fill,
  white ink, right-aligned. Both max-width 78%.
- AI answers are **structured**: a one-line pick, one sentence of reasoning, then a 4-row mini table
  (TP Index / Price / Battery / Camera) and a tap-through to that device.
- Seed message: `Give me a budget and the one thing you care about most. I will answer with a table.`
- Above the input: a horizontally scrolling row of suggestion chips.
- Input bar: pill field + circular blue send button. iOS bottom inset 190px, Android 172px.

Keep `firebase_vertexai` from `ChatAI.dart`, but the response contract changes: the model must return
`{pick, reason, rows[]}` so the UI can render the table. Do not render raw markdown.

### 11. Scan — `scan`

Full-bleed dark takeover (`#0B0D10`), **content starts at y=0 under a light-content status bar**.

- Viewfinder: 4 corner brackets, blue, 3px, on a 260×160 region; a scan line animates top→bottom, 1.6s,
  `ease-in-out`, infinite alternate.
- Back chevron + title `Scan` at y≈161, both white.
- Idle hint: `Point at the model number on the back of the device.`
- On match (`scanState: 'done'`): a result card rises from the bottom (240ms, `cubic-bezier(.2,.8,.2,1)`)
  with eyebrow `Detected`, device name, index, and `Open device` → `detail`.
- Done hint: `Matched against the TechPicks catalogue.`

Builds on `Scan.dart` + `google_ml_kit`; the OCR result should be matched against the catalogue, not shown raw.

### 12. 3D viewer — `viewer`

Same dark takeover treatment. A stage with the model centred, a horizon line, and a soft radial ground
shadow. Bottom: part chips — `Display` · `Battery` · `Chipset` · `Camera module` — which highlight
sub-assemblies. Note: `Drag to orbit, pinch to zoom. Models stream on demand and cache for offline viewing.`
Replaces `Model3D.dart`.

### 13. You — `you`

- Header: 64px avatar (blue circle, initials `SP`), name, email, `Edit profile`.
- **What you care about** — five sliders (performance / camera / display / battery / value) with the note
  `These weights are yours. Change them and every index recalculates.` **This is the important one:** the
  TP Index is not a fixed number, it is the user's own weighting. Changing a slider recomputes every index
  in the app.
- Settings rows: `Language` (English / 한국어), `Dark mode`, `Notifications`, `Currency`.
- `Change password`, `Log out`.
- Footer: `TechPicks version 2.0.0 · Apache-2.0`.

Merges `Profile.dart`, `EditProfileScreen.dart`, `ChangePassword.dart` and `PhoneSetting.dart`.
Note the current app **restarts** to change language (`restart_app`); with `easy_localization` this can be
live — drop the "Restart Required" dialog and its strings.

---

## Interactions & Behavior

| Interaction | Spec |
| --- | --- |
| Tab switch | Active tab: iOS pill slides to the new cell in 180ms; Android icon+label to blue. **Deviation:** the spec says the body switches instantly, but with the pill sliding, an instant body read as a glitch — the body now fades in (200ms, 96%→100% scale) while the chrome stays put. Set `contentSwap` to zero to get the spec behaviour back. |
| Push (detail, picker, scan, viewer) | Platform default — iOS slide-from-right, Android shared-axis X. |
| Back | iOS: glass chevron top-left **and** edge swipe. Android: app-bar arrow **and** system back. Single-level: returns to `prev`. |
| Rank re-sort | Rows animate to new positions, 220ms `cubic-bezier(.2,.8,.2,1)`. |
| Add to shortlist | Button label flips to `On your shortlist`; the Home shortlist gains a row. |
| Weight slider | Every visible index recomputes live as the thumb moves. |
| Send message | Optimistic user bubble, then the AI bubble. Scroll to bottom. |
| Scan | `idle → done` after a match; result card rises 240ms. |
| Chip press | Scale to 0.97 for 90ms. |
| Card press | iOS: brightness up 4%. Android: standard M3 ripple. |
| Loading | Skeleton rows at the card's own radius — never a centred spinner (the current app uses `CircularProgressIndicator` on a blank page; replace it). |
| Empty shortlist | Card with `Nothing on your shortlist yet` + `Add a device` — do not show the verdict card. |

---

## Data model

```
Device {
  id, brand, name, ko,               // ko = Korean display name
  usd:int, krw:string,
  screen, soc, cam, batt, os, weight, thick, rel,   // display strings
  s: { perf, cam, disp, batt, val },  // 0–100 component scores
  idx,                                // derived, see below
  prevPos:int                         // last week's rank, for Movers
}
```

**TP Index** (default weights — user-editable on the You screen):

```
idx = round(perf*0.25 + cam*0.25 + disp*0.20 + batt*0.20 + val*0.10)
```

Seed data in the prototype: 5 phones (Galaxy S26 Ultra, iPhone 17 Pro Max, OnePlus 15, Pixel 10 Pro XL,
Galaxy Z Fold7), 10 processors (5 mobile, 5 laptop), 5 laptops. All values are in the `PHONES`, `CPUS` and
`LAPTOPS` constants at the top of the logic block in `index.html`. **The repo's current data is
the 2024 set — this is refreshed to 2026.** Long-term this is what the planned "TechPicks API" should serve;
until then ship it as a versioned JSON asset so scores can be updated without a store release.

---

## Copy

Full EN/KO strings are the `T` object in `index.html` (search for `const T = {`). Add them to
`assets/translations/en-US.json` and `ko-KR.json` under the same keys. Notes:

- Korean is **not** a transliteration — `Rankings` → `2026 순위`, `Where this lands` → `지금의 결론`,
  `Movers this week` → `이번 주 변동`. Device names have Korean forms (`갤럭시 S26 울트라`).
- Prices are localised, not converted at runtime: `$1,300` / `₩1,798,000`.
- Korean is roughly 15% shorter than English at these sizes; both were checked against the same layout
  and neither wraps. Do not shrink type for Korean.
- Existing keys that are now dead: `where_to`, `choose_bookmark`, `set_destination_on_map`, `around_you`,
  `reserve`, `restart_required`, `restart_confirm_message`.

---

## Assets

| Asset | Source | Use |
| --- | --- | --- |
| `assets/logo/NBlogo_black.png` | the repo | The app mark in both headers (13×19 iOS, 16×22 Android) and the doc header. The palette was sampled from it. |
| Icons | Inline 24×24 stroke SVGs, `stroke-width` 1.9–2 | Home, Rank, Compare, Ask, You, Scan, Back. In Flutter use Material/Cupertino icons at the same weight. |
| Product photography | **Not supplied** | 3:2, on a light neutral ground, no drop shadow. |
| 3D models | **Not supplied** | The `rive`/model pipeline from the current app. |

---

## Files

| File | What it is |
| --- | --- |
| `index.html` | **The design.** All 13 screens × 2 platforms × 2 languages, interactive. Tokens and data are in the script block at the bottom; markup is above it. |
| `v1.html` | v1 — an earlier flat/Swiss-grid direction on the Modernist design system. Reference only; **v2 supersedes it.** |
| `ios-frame.jsx`, `android-frame.jsx` | Device bezels + status bars used by the prototype. Not part of the app. |
| `image-slot.js` | The drag-and-drop image placeholder on the detail screen. Not part of the app. |
| `support.js` | Prototype runtime. Not part of the app. |
| `assets/logo/NBlogo_black.png` | App mark. |

All paths above are relative to `design/`. Serve that directory over HTTP (`python -m http.server`)
and open `index.html` — the page fetches sibling files, which `file://` blocks. Use the screen
buttons at the top to move between screens, and the platform/language controls to switch chrome
and locale.

---

## Suggested build order

1. Tokens + both chrome shells (app bar, tab bar, insets) — everything else sits inside them.
2. The device data model + TP Index, as a plain repository over a bundled JSON asset.
3. Rankings → Detail → Compare (the core loop; also the biggest deletion — the three webviews).
4. Home (depends on shortlist + index).
5. You (weights feed back into the index).
6. Ask (needs the structured response contract).
7. Onboarding + Login (mostly rewiring existing Firebase code).
8. Scan + 3D viewer.
