# 앱 아이콘

로고: 30° 기울어진 캡슐 셋, 맨 위는 켜진 토글(파란 채움 + 동그란 손잡이).

## iOS

- `ios/Runner/AppIcon.icon` — iOS 26 이상. Icon Composer 문서. 평평한 레이어만 두고
  유리(반사·굴절·그림자)와 다크·클리어·틴티드 모드는 시스템이 입힌다.
  - 레이어: `knob` / `toggle`(채움 + 토글 막대) / `bars`(가운데·아래 막대), 그룹 셋
  - 다크는 레이어마다 `-dark.svg` (막대가 밝아진다)
  - 다시 만들기: `python3 tool/icons/make_ios_icon.py ios/Runner/AppIcon.icon`
  - 미리 보기: `ictool ios/Runner/AppIcon.icon --export-image --output-file out.png
    --platform iOS --rendition Default|Dark|ClearLight|TintedLight --width 1024 --height 1024 --scale 1`
    (`/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool`)
- `AppIcon.appiconset` — iOS 16–18. 유리를 그려 넣은 1024 네모 두 장(라이트·다크).
- `ios_1024.png` — 위 라이트 원본.

## Android (Material 3)

- `mipmap-anydpi-v26/ic_launcher.xml` — 적응형 아이콘. 광택 없는 평면.
  - 배경 `@color/ic_launcher_background` (primaryContainer 톤 `#D8E2FF`)
  - 전경 `drawable/ic_launcher_foreground.xml` — 안전 영역(66/108dp) 안
  - 단색 `drawable/ic_launcher_monochrome.xml` — 테마 아이콘(13+), 손잡이는 구멍
- `mipmap-*/ic_launcher.png` — API 26 아래용 원형.
- `android_play_512.png` — Play 스토어용 네모 원본(스토어가 깎는다).

## 스플래시

`assets/logo/logo*.png` → `dart run flutter_native_splash:create`.
iOS 는 유리 아이콘, Android 는 M3 원형. `TpLaunch.logoFor` 가 같은 그림을 이어받는다.
