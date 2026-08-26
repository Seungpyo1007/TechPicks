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
same application identifiers.

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
- Deployment target: Vercel with `site/` as the project root
- Production origin: supplied through `NEXT_PUBLIC_SITE_URL`
- First public surfaces: phone ranking, detail, and two-phone comparison
