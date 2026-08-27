# App and web handoff

## Current application baseline

- Package and bundle identifier: `com.techpicks.app`
- Flutter deep links: `techpicks://device/{slug}` and
  `techpicks://compare/{a}/{b}`
- Catalog: `assets/catalog/v1.json`, generated from TechAPI
- Current scan experience: manual device-name search; camera/OCR is not enabled

## External setup required

The Android and iOS applications must be registered in Firebase under
`com.techpicks.app`. After registration, run `flutterfire configure` for the
`techpicks-project` project and commit the regenerated `firebase.json` and
`lib/firebase_options.dart`. Google and Apple sign-in registrations must use the
same application identifiers. Store the base64-encoded Android download in the
GitHub Actions secret `FIREBASE_ANDROID_CONFIG_BASE64`; the Android CI job fails
closed when this real configuration is unavailable.

Do not invent replacement Firebase application IDs or commit downloaded
`google-services.json` / `GoogleService-Info.plist` files.

Local verification on 2026-08-26 stopped at
`:app:processDebugGoogleServices` because `android/app/google-services.json`
is intentionally absent. The Firebase CLI and FlutterFire CLI were also not
available on the Windows development host. Android debug and iOS no-codesign
builds remain release-gate checks after the real Firebase registrations are
available; the iOS build must run on macOS.

The Firebase-independent checks passed on the same baseline: `flutter analyze`
reported no issues, and the Flutter suite passed 692 tests with 30 existing
golden tests skipped by their platform guards.

## Web delivery

- Source directory: `site/` (never Flutter's reserved `web/` directory)
- Design source of truth: `TechPicks Web M3.dc.html` — see `docs/WEB_DESIGN_FIDELITY.md`
- Deployment target: Vercel with `site/` as the project root
- Production origin: supplied through `NEXT_PUBLIC_SITE_URL`
- Public surfaces: home, phone ranking and detail, CPU ranking and detail, laptop
  configurations, comparison, and the desktop build estimator. Scan, 3D viewer,
  profile, and login are shipped but excluded from the index.
- Data snapshots live under `site/data/` and are refreshed with `pnpm sync:laptops`
  and `pnpm sync:parts`. The committed snapshot is the build input so the site
  builds without network access.

### App and web URL map

| Resource | App deep link | Web |
| --- | --- | --- |
| Phone detail | `techpicks://device/{slug}` | `/phones/{slug}` |
| Comparison | `techpicks://compare/{a}/{b}` | `/compare?type=phone&ids={a},{b}` |
| Build estimate | not in the application | `/build?use={case}&budget={usd}&cpu={slug}&gpu={slug}` |

The web comparison also accepts `type=cpu` and `type=laptop`, and up to three
identifiers. The two-phone form above is unchanged.

### Deployment

Vercel, with `site` as the project root and `develop` as the production branch.
`vercel.json` already declares the Next.js framework. Two environment variables
are required: `NEXT_PUBLIC_SITE_URL` (the assigned origin, which drives canonical
URLs, the sitemap, and Open Graph tags) and `TECHAPI_BASE_URL`. Preview
deployments are excluded from the index by `isPreviewDeployment()` in
`site/lib/seo.ts`.

The comparison and build screens render on demand because they read query
parameters, so a static export target would lose them. That rules out GitHub
Pages for this site.

### Palette

The web deliberately does not share the application palette. The application uses
the logo blue `#0C78D8` from `lib/app/theme/tp_tokens.dart`; the web uses the
design source's slate accent `#5980a6` from `site/styles/tokens.css`.
`shared/tokens/techpicks.css` remains the application contract and is not
imported by the web.
