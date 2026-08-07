# TechPicks — mobile app design

Interactive design prototype for the TechPicks app redesign.
13 screens, two platform chromes (iOS 26 · Android Material 3), two languages (en-US · ko-KR).

**Live:** https://seungpyo1007.github.io/TechPicks-Web/design/

## Contents

| Path | What |
| --- | --- |
| `index.html` | The prototype. Screen buttons at the top; platform and language switches beside them. |
| `v1.html` | Earlier direction (flat Swiss grid). Superseded. |
| `handoff/README.md` | Implementation spec — tokens, geometry, screen-by-screen behaviour, data model, copy. |
| `_ds/` | Stylesheet + bundle used by `v1.html`. |
| `assets/logo/` | App mark. |
| `support.js`, `*-frame.jsx`, `image-slot.js` | Prototype runtime and device frames. Not app code. |

## Running locally

Any static server, from this directory:

```
python3 -m http.server 8000
```

Then open http://localhost:8000/ . Opening `index.html` straight off the filesystem will not work —
the page fetches sibling files, which `file://` blocks.

## Notes

- The design files are **references**, not production code. The target app is Flutter; see
  `handoff/README.md` for how to rebuild each screen there.
- Device data is the 2026 flagship set. Product photography and 3D models are not included.
- The repository root `.nojekyll` keeps GitHub Pages from dropping `_ds/`; Jekyll ignores
  directories that start with an underscore.
- Licensed under Apache-2.0, matching the app repo.
