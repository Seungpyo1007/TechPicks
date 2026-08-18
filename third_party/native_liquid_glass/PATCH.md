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

## 언제 지우나

위 패치가 upstream 에 들어간 판이 나오면 이 디렉터리와 `dependency_overrides` 를
지우고 pub 판으로 돌아간다. 확인은 탭을 눌러보는 것으로 충분하다 — 홈을 눌렀을 때
홈이 켜지면 된 것이다.
