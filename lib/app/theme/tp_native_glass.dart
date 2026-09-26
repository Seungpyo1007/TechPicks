import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

/// OS 가 직접 그리는 유리.
///
/// 여태 크롬은 **유리 흉내**였다. `BackdropFilter` 는 흐리고 채도를 올릴 뿐이고,
/// `liquid_glass_widgets` 는 셰이더로 굴절을 그린다 — 둘 다 우리가 그린 그림이다.
/// iOS 26 의 진짜 Liquid Glass 는 OS 안에 있고, 렌즈처럼 배경을 빨아들이고
/// 기울기와 주변 밝기에 반응하고 서로 붙었다 떨어진다. 그건 흉내로 안 된다.
///
/// [native_liquid_glass] 가 SwiftUI 의 `.glassEffect()` 를 플랫폼 뷰로 꽂아준다.
/// **크롬에만 쓴다** — 화면당 두 장이다. 카드에 쓰면 목록 하나에 플랫폼 뷰가
/// 수십 개 생긴다.
abstract final class TpNativeGlass {
  /// 테스트가 켜고 끌 수 있게 열어둔다.
  @visibleForTesting
  static bool? debugOverride;

  /// 이 기기에서 진짜 유리를 쓸 수 있는가.
  ///
  /// iOS 26 미만이면 플러그인이 아무것도 안 그린다(빈 상자를 돌려준다). 그래서
  /// 여기서 미리 갈라두고, 안 되면 예전 경로가 그대로 그린다.
  static bool get enabled {
    if (debugOverride != null) return debugOverride!;
    if (kIsWeb) return false;
    // 플랫폼 뷰는 테스트에 없다. 크롬이 통째로 빈 상자가 된다.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return NativeLiquidGlassUtils.supportsLiquidGlass;
  }
}

/// 크롬 한 장을 진짜 유리 위에 얹는다.
///
/// 유리는 OS 가 그리고, 그 위의 글자·아이콘·파란 알약은 그대로 Flutter 가
/// 그린다. 명세가 못박은 치수(탭 62pt·반지름 999·좌우 12)는 우리 것으로 남는다 —
/// 패키지의 `LiquidGlassTabBar` 를 쓰면 애플 기본 탭 바 모양으로 덮인다.
class TpNativeGlassSurface extends StatelessWidget {
  const TpNativeGlassSurface({
    super.key,
    required this.child,
    required this.radius,
    this.capsule = false,
    this.tint,
    this.interactive = true,
  });

  final Widget child;

  /// 모서리 반지름. [capsule] 이면 무시된다.
  final double radius;

  /// 알약인가. 탭 바와 헤더 알약이 그렇다.
  final bool capsule;

  /// 유리에 섞을 색.
  ///
  /// **크롬 본체에는 안 쓴다** — 색을 얹는 순간 OS 유리가 그 아래로 사라진다.
  /// 고른 탭 알약처럼 색 자체가 뜻인 자리에만 준다.
  final Color? tint;

  /// 눌렸을 때 OS 가 유리를 눌러 줄지. 장식이면 끈다.
  final bool interactive;

  @override
  Widget build(BuildContext context) => LiquidGlassContainer(
    config: LiquidGlassConfig(
      // regular 는 배경을 더 많이 빨아들이고, clear 는 더 투명하다. 크롬 뒤로
      // 목록이 지나가야 하므로 regular 다.
      effect: LiquidGlassEffect.regular,
      shape: capsule
          ? LiquidGlassEffectShape.capsule
          : LiquidGlassEffectShape.rect,
      cornerRadius: capsule ? null : radius,
      tint: tint,
      // 누르면 OS 가 유리를 눌러 준다. 우리가 스케일을 흉내 내는 것보다
      // 훨씬 유리 같다 — 빛이 같이 움직인다.
      interactive: interactive,
    ),
    child: child,
  );
}

/// 시스템 탭 바 한 칸.
class TpNativeTabItem {
  const TpNativeTabItem({
    required this.label,
    required this.symbol,
    required this.activeSymbol,
  });

  final String label;
  final String symbol;
  final String activeSymbol;
}

/// iOS 26 의 시스템 탭 바.
///
/// 유리를 우리 알약 뒤에 깔아주는 것과 **바가 통째로 시스템 것**인 것은 다르다.
/// 고른 칸의 방울이 바에 녹아들었다 떨어지는 그 움직임은 한 유리 컨테이너
/// 안에서만 나오고, 그건 `UITabBar` 안에 있다.
///
/// 명세의 치수는 여기서도 우리가 준다: 높이 62, 좌우 12(셸이 잡는다), 파란
/// 강조, 우리 라벨과 타이포. 아이콘만 SF Symbol 이다 — Material 아이콘을 PNG 로
/// 구워 넘기면 선 굵기도 선택 상태 전환도 OS 것이 아니게 된다.
class TpNativeTabBar extends StatelessWidget {
  const TpNativeTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
    required this.height,
    required this.tint,
    this.onSearch,
    this.searchLabel,
    this.labelStyle,
    this.iconSize,
    this.nativeSearch = false,
    this.searchActive = false,
    this.searchPlaceholder,
    this.onSearchChanged,
    this.onSearchKeyboard,
    this.keyboardDismissToken = 0,
    this.searchText = '',
    this.searchTextToken = 0,
    this.searchFocusToken = 0,
    this.hitTestTransparent = false,
    this.acceptsAt,
  });

  /// 뷰 뒤의 Flutter 위젯도 히트되게.
  final bool hitTestTransparent;

  /// 이 전역 좌표의 터치를 네이티브 바가 받을지. null 이면 전부 받는다.
  final bool Function(Offset global)? acceptsAt;

  /// [searchTextToken] 이 바뀔 때 검색창 글자를 이걸로.
  final String searchText;
  final int searchTextToken;

  /// 바뀔 때 검색창에 초점.
  final int searchFocusToken;

  /// 검색 중 키보드의 최종 높이. 움직이기 시작할 때 온다.
  final ValueChanged<double>? onSearchKeyboard;

  /// 검색 원을 진짜 검색 탭으로. 누르면 UIKit 이 칸을 밀어내고 검색창을 펼친다.
  final bool nativeSearch;

  /// 검색 탭이 켜져 있어야 하는가.
  final bool searchActive;
  final String? searchPlaceholder;
  final ValueChanged<String>? onSearchChanged;

  /// 바뀔 때마다 검색창 키보드를 내린다.
  final int keyboardDismissToken;

  final List<TpNativeTabItem> items;
  final int index;
  final ValueChanged<int>? onSelected;
  final double height;

  /// 고른 칸의 강조색.
  final Color tint;

  /// 바 오른쪽 검색 원. iOS 26 은 이걸 `UISearchTab` 으로 그린다.
  final VoidCallback? onSearch;
  final String? searchLabel;

  /// 라벨 타이포. null 이면 시스템 기본.
  ///
  /// 우리 값을 넘기면 시스템 바의 치수와 어긋난다 — 10pt 라벨은 헐렁하고,
  /// 아이콘을 28 로 키우면 라벨과 겹친다. 간격·크기는 UIKit 이 자기 규칙대로
  /// 잡게 두는 것이 결국 제일 네이티브다.
  final TextStyle? labelStyle;

  /// 아이콘 한 변. null 이면 시스템 기본.
  final double? iconSize;

  /// 플러그인이 유리를 흘려보내려고 상자를 `height + 20` 으로 잡는다. 위쪽
  /// 20pt 는 비고 바는 아래에 붙는다. 담는 쪽이 62 로 잘라두면 그만큼 넘쳐서
  /// **터치가 어긋난 자리에 떨어진다.**
  static const double overflow = 20;

  @override
  Widget build(BuildContext context) => LiquidGlassTabBar(
    currentIndex: index,
    onTabSelected: (i) => onSelected?.call(i),
    height: height,
    selectedItemColor: tint,
    iconSize: iconSize,
    iosItemPositioning: LiquidGlassTabBarItemPositioning.fill,
    iosActionButton: onSearch == null
        ? null
        : LiquidGlassTabItem(
            label: searchLabel ?? '',
            icon: NativeLiquidGlassIcon.sfSymbol('magnifyingglass'),
          ),
    onActionButtonPressed: onSearch,
    iosNativeSearch: nativeSearch,
    searchActive: searchActive,
    searchPlaceholder: searchPlaceholder,
    // 켜질 때만 알린다. 꺼질 때는 onTabSelected 가 돌아갈 칸을 같이 준다.
    onSearchActiveChanged: (active) {
      if (active) onSearch?.call();
    },
    onSearchChanged: onSearchChanged,
    onSearchSubmitted: onSearchChanged,
    onSearchKeyboard: onSearchKeyboard,
    searchKeyboardDismissToken: keyboardDismissToken,
    searchText: searchText,
    searchTextToken: searchTextToken,
    searchFocusToken: searchFocusToken,
    iosHitTestTransparent: hitTestTransparent,
    iosGestureRecognizers: acceptsAt == null
        ? null
        : <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => _RegionEager(acceptsAt!),
            ),
          },
    labelTextStyle: labelStyle,
    items: <LiquidGlassTabItem>[
      for (final item in items)
        LiquidGlassTabItem(
          label: item.label,
          icon: NativeLiquidGlassIcon.sfSymbol(item.symbol),
          selectedIcon: NativeLiquidGlassIcon.sfSymbol(item.activeSymbol),
        ),
    ],
  );
}

/// OS 가 그리는 유리 검색 바. 펼친 채로 두고 취소 버튼은 안 쓴다.
class TpNativeSearchBar extends StatelessWidget {
  const TpNativeSearchBar({
    super.key,
    required this.placeholder,
    required this.height,
    this.onChanged,
    this.onSubmitted,
    this.tint,
    this.textColor,
    this.placeholderColor,
    this.iconColor,
  });

  final String placeholder;
  final double height;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Color? tint;
  final Color? textColor;
  final Color? placeholderColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => LiquidGlassSearchBar(
    placeholder: placeholder,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    expandable: false,
    initiallyExpanded: true,
    expandedHeight: height,
    showCancelButton: false,
    tint: tint,
    textColor: textColor,
    placeholderColor: placeholderColor,
    iconColor: iconColor,
  );
}

/// iOS 26 의 `UISegmentedControl`. 고른 칸이 유리 캡슐로 미끄러진다.
///
/// Flutter 의 `CupertinoSlidingSegmentedControl` 은 iOS 13 모양이다 — 모서리가
/// 각지고 두껍다. 26 에서는 캡슐이고 32pt 다.
class TpNativeSegmented extends StatelessWidget {
  const TpNativeSegmented({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  static const double height = 32;

  @override
  Widget build(BuildContext context) => LiquidGlassSegmentedControl(
    labels: labels,
    selectedIndex: index,
    onValueChanged: onChanged,
    height: height,
  );
}

/// 풀다운 메뉴 한 줄(네이티브용).
class TpNativeMenuEntry {
  const TpNativeMenuEntry({
    required this.label,
    this.checked = false,
    this.destructive = false,
    this.symbol,
  });

  final String label;
  final bool checked;
  final bool destructive;

  /// 줄 오른쪽 SF Symbol.
  final String? symbol;
}

/// iOS 26 툴바의 메뉴 버튼. 유리 원을 누르면 `UIMenu` 가 펼쳐진다.
///
/// Flutter 의 `CupertinoMenuAnchor` 는 iOS 13 메뉴 모양이다. 이건 시스템 것이라
/// 유리 번짐, 체크 표시, 여는 모션이 전부 OS 그대로다.
class TpNativeMenuButton extends StatelessWidget {
  const TpNativeMenuButton({
    super.key,
    required this.symbol,
    required this.label,
    required this.entries,
    required this.onSelected,
    this.tint,
  });

  /// SF Symbol 이름.
  final String symbol;

  /// 스크린 리더 이름.
  final String label;
  final List<TpNativeMenuEntry> entries;
  final ValueChanged<int> onSelected;

  /// 아이콘 색. 필터가 걸려 있을 때 액센트.
  final Color? tint;

  @override
  Widget build(BuildContext context) => LiquidGlassMenu.icon(
    icon: NativeLiquidGlassIcon.sfSymbol(symbol),
    glass: true,
    accessibilityLabel: label,
    color: tint,
    height: 44,
    items: <LiquidGlassMenuItem>[
      for (var i = 0; i < entries.length; i++)
        LiquidGlassMenuItem(
          id: '$i',
          title: entries[i].label,
          isChecked: entries[i].checked,
          isDestructive: entries[i].destructive,
        ),
    ],
    onItemSelected: (id) => onSelected(int.parse(id)),
  );
}

/// 정해진 자리의 터치만 곧바로 네이티브에 넘긴다. 나머지는 참가하지 않아서
/// 뒤의 Flutter 위젯이 받는다.
class _RegionEager extends EagerGestureRecognizer {
  _RegionEager(this.acceptsAt);

  final bool Function(Offset global) acceptsAt;

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      acceptsAt(event.position) && super.isPointerAllowed(event);
}

/// iOS 26 툴바의 아이콘 버튼. 시스템 유리 버튼이라 누르면 유리가 OS 식으로
/// 눌렸다 튀어 오른다.
class TpNativeIconButton extends StatelessWidget {
  const TpNativeIconButton({
    super.key,
    required this.symbol,
    required this.onTap,
    this.tint,
  });

  /// SF Symbol 이름.
  final String symbol;
  final VoidCallback? onTap;

  /// 아이콘 색. null 이면 글자색.
  final Color? tint;

  @override
  Widget build(BuildContext context) => LiquidGlassButton.icon(
    icon: NativeLiquidGlassIcon.sfSymbol(symbol),
    onPressed: onTap,
    size: 44,
    iconSize: 18,
    iconColor: tint,
  );
}

/// 설정 줄 오른쪽의 풀다운 값 버튼. 유리 캡슐에 "값 ⌃⌄", 누르면 UIMenu.
class TpNativeMenuPicker extends StatelessWidget {
  const TpNativeMenuPicker({
    super.key,
    required this.value,
    required this.label,
    required this.entries,
    required this.onSelected,
  });

  /// 지금 값. 캡슐에 보인다.
  final String value;

  /// 줄 이름(스크린 리더).
  final String label;
  final List<TpNativeMenuEntry> entries;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => LiquidGlassMenu(
    // 값이 바뀌면 캡슐 글자도 바뀌어야 한다. 네이티브는 처음 값만 받으므로
    // 새로 만든다.
    key: ValueKey<String>(value),
    label: value,
    icon: NativeLiquidGlassIcon.sfSymbol('chevron.up.chevron.down'),
    iconSize: 11,
    glass: true,
    imageTrailing: true,
    height: 36,
    labelTextStyle: const TextStyle(fontSize: 15),
    accessibilityLabel: '$label, $value',
    items: <LiquidGlassMenuItem>[
      for (var i = 0; i < entries.length; i++)
        LiquidGlassMenuItem(
          id: '$i',
          title: entries[i].label,
          isChecked: entries[i].checked,
        ),
    ],
    onItemSelected: (id) => onSelected(int.parse(id)),
  );
}

/// 글자 버튼에서 펼쳐지는 시스템 풀다운. 프로필 수정의 "사진 바꾸기".
///
/// 유리 캡슐이 아니라 링크 색 글자다. 누르면 그 자리에서 UIMenu 가 펼쳐진다.
class TpNativeMenuLink extends StatelessWidget {
  const TpNativeMenuLink({
    super.key,
    required this.label,
    required this.entries,
    required this.onSelected,
    this.color,
  });

  final String label;
  final List<TpNativeMenuEntry> entries;
  final ValueChanged<int> onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) => LiquidGlassMenu(
    // 항목이 바뀌면(사진이 생기면 "지우기") 새로 만든다.
    key: ValueKey<int>(entries.length),
    label: label,
    color: color,
    labelTextStyle: const TextStyle(fontSize: 17),
    accessibilityLabel: label,
    height: 44,
    items: <LiquidGlassMenuItem>[
      for (var i = 0; i < entries.length; i++)
        LiquidGlassMenuItem(
          id: '$i',
          title: entries[i].label,
          icon: entries[i].symbol == null
              ? null
              : NativeLiquidGlassIcon.sfSymbol(entries[i].symbol!),
          isDestructive: entries[i].destructive,
        ),
    ],
    onItemSelected: (id) => onSelected(int.parse(id)),
  );
}
