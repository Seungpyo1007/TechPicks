import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../shell/tp_tab.dart';
import 'tp_tokens.dart';

/// 크롬마다 다른 아이콘.
///
/// iOS 크롬에 Material 공유 아이콘(점 세 개를 잇는 선)이 나오면 바로 티가
/// 난다. iOS 사람은 네모 위로 화살표가 나가는 모양을 공유로 읽는다. 화면은
/// `context.icons.share` 만 부르고 어느 쪽인지는 여기서 정한다.
@immutable
class TpIcons {
  const TpIcons._({
    required this.back,
    required this.share,
    required this.search,
    required this.close,
    required this.send,
    required this.image,
  });

  final IconData back;
  final IconData share;
  final IconData search;

  /// 칸 비우기, 항목 빼기.
  final IconData close;
  final IconData send;
  final IconData image;

  static const TpIcons ios = TpIcons._(
    back: CupertinoIcons.chevron_back,
    share: CupertinoIcons.share,
    search: CupertinoIcons.search,
    close: CupertinoIcons.xmark_circle_fill,
    send: CupertinoIcons.arrow_up,
    image: CupertinoIcons.photo,
  );

  static const TpIcons android = TpIcons._(
    back: Icons.chevron_left,
    share: Icons.share,
    search: Icons.search,
    close: Icons.close,
    send: Icons.arrow_upward,
    image: Icons.image_outlined,
  );

  /// SF Symbol 을 못 쓰는 iOS 탭 바(26 미만, 테스트)의 아이콘.
  ///
  /// 네이티브 바가 쓰는 심볼([TpTab.symbol])과 같은 모양으로 맞췄다. 저울은
  /// CupertinoIcons 에 없어서 Material 것을 그대로 쓴다.
  static IconData iosTab(TpTab tab, {required bool active}) => switch (tab) {
    TpTab.today => active ? CupertinoIcons.house_fill : CupertinoIcons.house,
    TpTab.browse =>
      active
          ? CupertinoIcons.square_grid_2x2_fill
          : CupertinoIcons.square_grid_2x2,
    TpTab.compare => active ? tab.activeIcon : tab.icon,
    TpTab.search => CupertinoIcons.search,
  };
}

extension TpIconsX on BuildContext {
  TpIcons get icons => tp.isGlass ? TpIcons.ios : TpIcons.android;
}
