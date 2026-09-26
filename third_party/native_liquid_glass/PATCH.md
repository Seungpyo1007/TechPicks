# native_liquid_glass 0.2.14 — 우리 패치

pub.dev 판을 그대로 두고 이 사본을 쓴다(`pubspec.yaml` 의 `dependency_overrides`).
`example/` 와 `test/` 는 안 가져왔다.

## 고친 것

`LiquidGlassTabBar` 가 **고르지도 않은 칸을 알려온다.**

- 바를 세울 때 다섯 칸 전부에 대해 같은 밀리초에 알려온다(4·0·2·3·1).
- Flutter 가 `currentIndex` 를 내려보낸 뒤에도 100ms 쯤 뒤에 예전 칸을 한 번 더.

그대로 받으면 홈을 눌렀는데 내 정보가 켜진다.

원인은 `UITabBarControllerDelegate` 의 `didSelect` / `didSelectTab` 이 **프로그램이
바꾼 선택에도 불린다**는 것이다. 탭을 처음 심을 때(`tabBarController.tabs = ...`)와
`setSelectedIndex` 가 그 경로다.

UIKit 은 사람이 고른 경우에만 `shouldSelect` / `shouldSelectTab` 을 부른다. 그래서
거기서 표시를 남기고, `didSelect*` 는 그 표시가 있을 때만 Dart 로 알린다.

```
ios/.../LiquidGlassTabBar/LiquidGlassTabBarView.swift
  + private var selectionIsUserInitiated = false
  shouldSelect(_:)      → selectionIsUserInitiated = true
  shouldSelectTab(_:)   → selectionIsUserInitiated = true
  didSelect(_:)         → guard selectionIsUserInitiated else { return }
  didSelectTab(_:)      → guard selectionIsUserInitiated else { return }
```

`LiquidGlassContainer` 가 **안전 영역에 걸치면 유리가 눌린다.**

`UIHostingController` 가 창의 안전 영역만큼 SwiftUI 내용을 안쪽으로 민다. 홈 인디케이터
위에 놓인 원 버튼은 아래 13pt 가 비고 납작하게 그려졌다. 호스팅 컨트롤러가 안전 영역을
무시하게 한다.

```
ios/.../LiquidGlassContainer/LiquidGlassContainerView.swift
  + hc.safeAreaRegions = []
```

`LiquidGlassTabBar` 의 검색 원이 **검색 탭 흉내**였다.

`UISearchTab` 으로 그려 놓고 `shouldSelectTab` 에서 막은 뒤 Flutter 로 탭만 넘겼다.
그래서 iOS 26 의 검색 모션(칸이 밀려나고 검색창이 바 자리로 펼쳐지는 것)이 없었다.
`iosNativeSearch` 를 켜면 검색 탭을 진짜로 고르게 두고, 탭 내용에 투명한 화면 +
`UISearchController` 를 붙인다. UIKit 이 모션과 키보드 위 자리를 맡는다.

```
ios/.../LiquidGlassTabBar/LiquidGlassTabBarConfig.swift
  + nativeSearch, searchPlaceholder
ios/.../LiquidGlassTabBar/LiquidGlassTabBarView.swift
  makeActionTab        → nativeSearch 면 makeSearchContent. 키보드는 검색창을 눌러야(automaticallyActivatesSearch = false)
  shouldSelectTab      → 검색 탭도 true
  didSelectTab         → onSearchActive(true) / 검색에서 돌아오면 onSearchActive(false)
  setSelectedIndex     → 검색 탭이 켜져 있으면 같은 칸이어도 다시 고른다
  + setSearchActive, dismissSearchKeyboard, UISearchBarDelegate
  채널: onSearchActive, onSearchChanged, onSearchSubmitted / setSearchActive, dismissSearchKeyboard
lib/src/liquid_glass_tab_bar.dart
  + iosNativeSearch, searchPlaceholder, searchActive, onSearchActiveChanged,
    onSearchChanged, onSearchSubmitted, searchKeyboardDismissToken
```

플랫폼 뷰는 바 높이뿐이라, 앱 쪽(`TpTabBar`)이 검색 중에는 키보드 높이만큼 뷰를 늘린다.
늘어난 자리는 키보드가 덮고 있어 Flutter 터치를 뺏지 않는다.

`LiquidGlassSegmentedControl` 이 **좌우 16 을 한 번 더** 준다.

SwiftUI `Picker` 에 `.padding(.horizontal, 16)` 이 붙어 있어 Flutter 가 준 여백과 겹쳤다.
지우고, 호스팅 컨트롤러도 안전 영역을 무시하게 한다.

```
ios/.../LiquidGlassSegmentedControl/LiquidGlassSegmentedControlSwiftUI.swift
  - .padding(.horizontal, 16)
ios/.../LiquidGlassSegmentedControl/LiquidGlassSegmentedControlView.swift
  + hc.safeAreaRegions = []
```

`LiquidGlassMenu` 가 체크 표시와 iOS 26 유리 버튼을 못 그린다.

```
lib/src/liquid_glass_menu.dart   + LiquidGlassMenuItem.isChecked, glass, accessibilityLabel
ios/.../LiquidGlassMenu/LiquidGlassMenuView.swift
  UIAction.state = .on (isChecked)
  glass 면 UIButton.Configuration.glass(), 캡슐, 칸을 채운다
```

세그먼트와 메뉴의 제스처를 `EagerGestureRecognizer` 로. `TapGestureRecognizer` 면 스크롤 안에서
손을 뗄 때까지 터치가 묶여 눌림이 안 보였다.

## 언제 지우나

위 패치가 upstream 에 들어간 판이 나오면 이 디렉터리와 `dependency_overrides` 를
지우고 pub 판으로 돌아간다. 확인은 탭을 눌러보는 것으로 충분하다 — 홈을 눌렀을 때
홈이 켜지면 된 것이다.

`LiquidGlassMenu` 에 **글자 뒤 아이콘**(`imageTrailing`)을 더했다. 내 정보의 언어·다크 모드·
통화 줄이 설정 앱처럼 "값 ⌃⌄" 유리 풀다운이 된다.

```
lib/src/liquid_glass_menu.dart            + imageTrailing (생성 인자에 실음)
ios/.../LiquidGlassMenu/LiquidGlassMenuView.swift
  glass 설정에서 imageTrailing 이면 imagePlacement = .trailing, 11pt 화살표
```
