import 'dart:async' show unawaited;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gemma_builtin_ai/flutter_gemma_builtin_ai.dart'
    show BuiltInAiAvailability;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../app/locale_controller.dart';
import '../../core/error_reporter.dart';
import '../../data/service/link_opener.dart';
import '../../domain/model/tp_money.dart';
import '../../shared/copy_keys.dart';
import 'profile_edit_screen.dart';
import 'sources_screen.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_menu.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_button.dart';
import '../../shared/widgets/tp_pressable.dart';
import '../../shared/widgets/tp_sheet.dart';
import '../../shared/widgets/tp_slider.dart';
import '../../shared/widgets/tp_switch.dart';

/// 내 정보.
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({
    super.key,
    this.name,
    this.email,
    this.onEditProfile,
    this.onChangePassword,
    this.onLogout,
    this.onDeviceTap,
    this.onSources,
    this.onClose,
  });

  /// 시트 닫기.
  final VoidCallback? onClose;

  /// 로그인 전에는 둘 다 null 이다. 인증 연결은 로그인 화면에서 한다.
  final String? name;
  final String? email;

  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogout;

  /// 내 기기가 카탈로그에 있으면 상세로 보낸다.
  final ValueChanged<String>? onDeviceTap;

  /// 데이터 출처 화면으로. 라우팅은 바깥에서 한다.
  final VoidCallback? onSources;

  /// 앱 버전. 명세의 푸터 문구 그대로.
  /// 명세 §13 의 확정 카피. 숫자는 pubspec 의 version 과 같아야 한다
  /// (test/unit/version_test.dart 가 확인한다).
  static const String version = '2.0.0';
  static const String versionLine = 'TechPicks version $version · Apache-2.0';

  @override
  ConsumerState<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends ConsumerState<YouScreen> {
  /// 계정 카드 아래 한 줄. 재설정 메일을 보냈다거나 못 보냈다는 안내다.
  ///
  /// SnackBar 를 쓸 수 없다. 이 앱은 Scaffold 를 안 쓰고 TpShell 이 크롬을
  /// 직접 그린다. 로그인 화면도 같은 방식으로 오류를 본문에 붙인다.
  String? _notice;

  String? get name => widget.name;
  String? get email => widget.email;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final weights = ref.watch(weightsProvider);
    final locale = ref.watch(localeControllerProvider);
    final notifications = ref.watch(notificationsProvider);
    final currency = ref.watch(currencyProvider);
    final themeMode = ref.watch(themeModeProvider);
    final aiEngine = ref.watch(aiEngineProvider);
    final onDevice = ref.watch(onDeviceAiProvider).value;
    // 헤더가 "로그인 없이 사용 중"이라고 적는 것과 같은 조건이다.
    final hasAccount = name != null || (email?.isNotEmpty ?? false);

    final sys = context.sys;
    final glass = t.isGlass;
    final rate = ref.watch(fxRateProvider).value ?? FxRate.fallback;

    Widget menuRow(String label, String value, List<TpMenuItem> items) =>
        TpMenu(
          items: items,
          builder: (context, open) =>
              _SettingRow(label: label, value: value, onTap: open, menu: true),
        );

    return TpPage(
      title: K.you.tr(),
      largeTitle: false,
      actions: <TpBarAction>[
        if (widget.onClose != null)
          TpBarAction(label: K.done.tr(), text: true, onTap: widget.onClose),
      ],
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              TpGroup(
                children: <Widget>[
                  _ProfileHeader(
                    photoUrl: ref.watch(profileProvider).value?.photoUrl,
                    name: name,
                    email: email,
                    onEdit: hasAccount
                        ? widget.onEditProfile ?? _openProfile
                        : null,
                  ),
                ],
              ),
              TpGroup(
                header: K.priorities.tr(),
                footer: K.prioritiesNote.tr(),
                headerAction: _Link(
                  label: K.reset.tr(),
                  onTap: () => ref.read(weightsProvider.notifier).reset(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                children: <Widget>[
                  for (final kind in TpAxisKind.values)
                    _WeightSlider(
                      kind: kind,
                      value: kind.weightIn(weights),
                      onChanged: (v) =>
                          ref.read(weightsProvider.notifier).setAxis(kind, v),
                    ),
                ],
              ),
              TpGroup(
                header: K.yourDevice.tr(),
                children: <Widget>[_YourDevice(onTap: widget.onDeviceTap)],
              ),
              TpGroup(
                footer: _fxLine(rate),
                children: <Widget>[
                  if (locale != null)
                    menuRow(K.language.tr(), locale.current.label, <TpMenuItem>[
                      for (final option in TpLocale.values)
                        TpMenuItem(
                          label: option.label,
                          checked: option == locale.current,
                          onTap: () => unawaited(locale.set(option)),
                        ),
                    ])
                  else
                    _SettingRow(
                      label: K.language.tr(),
                      value: TpLocale.en.label,
                    ),
                  menuRow(
                    K.darkMode.tr(),
                    _themeLabel(themeMode).tr(),
                    <TpMenuItem>[
                      for (final mode in <ThemeMode>[
                        ThemeMode.system,
                        ThemeMode.light,
                        ThemeMode.dark,
                      ])
                        TpMenuItem(
                          label: _themeLabel(mode).tr(),
                          checked: mode == themeMode,
                          onTap: () => unawaited(
                            ref.read(themeModeProvider.notifier).set(mode),
                          ),
                        ),
                    ],
                  ),
                  _SettingRow(
                    label: K.aiEngine.tr(),
                    value: aiEngine.key.tr(),
                    onTap: () => _openAiEngine(context, aiEngine, onDevice),
                  ),
                  menuRow(
                    K.currency.tr(),
                    K.currencyOf(currency).tr(),
                    <TpMenuItem>[
                      for (final option in TpCurrency.values)
                        TpMenuItem(
                          label: K.currencyOf(option).tr(),
                          checked: option == currency,
                          onTap: () => unawaited(
                            ref.read(currencyProvider.notifier).set(option),
                          ),
                        ),
                    ],
                  ),
                  _SettingRow(
                    label: K.notifications.tr(),
                    switchValue: notifications,
                    toggled: notifications,
                    onTap: () => ref
                        .read(notificationsProvider.notifier)
                        .set(!notifications),
                  ),
                ],
              ),
              TpGroup(
                footer: _notice,
                children: <Widget>[
                  _SettingRow(
                    label: K.sources.tr(),
                    onTap: widget.onSources ?? _openSources,
                  ),
                  if (email != null && email!.isNotEmpty)
                    _SettingRow(
                      label: K.changePassword.tr(),
                      onTap:
                          widget.onChangePassword ??
                          () => unawaited(_resetPassword()),
                    ),
                ],
              ),
              TpGroup(
                children: <Widget>[
                  TpRow(
                    title: (hasAccount ? K.logout : K.signIn).tr(),
                    destructive: hasAccount,
                    titleStyle: hasAccount
                        ? null
                        : TextStyle(color: sys.accentText),
                    chevron: false,
                    onTap: widget.onLogout == null
                        ? null
                        : hasAccount
                        ? () => unawaited(
                            _confirmLogout(context, widget.onLogout!),
                          )
                        : widget.onLogout,
                  ),
                ],
              ),
              Center(
                child: _Link(
                  label: YouScreen.versionLine,
                  small: true,
                  onTap: () => unawaited(_openLicense()),
                ),
              ),
              if (!glass) const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openAiEngine(
    BuildContext context,
    TpAiEngine current,
    BuiltInAiAvailability? status,
  ) => Navigator.of(context).push(
    context.tp.isGlass
        ? CupertinoPageRoute<void>(
            builder: (_) => _AiEnginePage(status: status),
          )
        : MaterialPageRoute<void>(
            builder: (_) => _AiEnginePage(status: status),
          ),
  );

  Future<void> _resetPassword() async {
    final sent = await ref
        .read(currentUserProvider.notifier)
        .sendPasswordReset();
    if (!mounted) return;

    setState(() {
      _notice = sent
          ? K.pwResetSent.tr(args: <String>[email ?? ''])
          : K.pwResetFailed.tr();
    });
  }

  /// 프로필 편집 화면을 연다.
  ///
  /// 한동안 여기에 이름 한 줄짜리 알림창이 있었다. v1 은 사진과 다섯 칸을
  /// 갖고 있었고, 그게 없어진 건 기록조차 안 됐다.
  Future<void> _openProfile() => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (context) =>
          ProfileEditScreen(onBack: () => Navigator.of(context).pop()),
    ),
  );

  Future<void> _openSources() => Navigator.of(context).push(
    CupertinoPageRoute<void>(
      builder: (context) =>
          SourcesScreen(onBack: () => Navigator.of(context).pop()),
    ),
  );

  Future<void> _openLicense() async {
    try {
      await ref.read(linkOpenerProvider).open(TpUrls.appLicense);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'link.open');
    }
  }
}

/// 내 기기 한 줄.
///
/// 읽히면 이름을 보여주고, 카탈로그에 있으면 지수를 붙여 상세로 보낸다.
/// 대부분은 모델 코드(SM-S931B)만 읽혀 못 찾는다.
class _YourDevice extends ConsumerWidget {
  const _YourDevice({this.onTap});

  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDevice = ref.watch(thisDeviceProvider);
    final device = asyncDevice.value;
    final match = ref.watch(thisDeviceMatchProvider);
    final weights = ref.watch(weightsProvider);
    // .value 는 **읽는 중에도** null 이다. 그걸 "못 읽었다"로 그려서, 이 탭의
    // 첫 프레임은 늘 실패 문구였다가 곧 진짜 이름으로 바뀌었다.
    final reading = asyncDevice is AsyncLoading && !asyncDevice.hasError;

    final index = match == null
        ? null
        : TpIndex.of(match.device.score, weights);

    return TpRow(
      title: device != null
          ? (match?.device.name ?? device.name)
          : reading
          ? ''
          : K.yourDeviceUnavailable.tr(),
      subtitle: device != null && match == null
          ? K.yourDeviceUnknown.tr()
          : null,
      leading: TpIconTile(
        icon: context.tp.isGlass
            ? CupertinoIcons.device_phone_portrait
            : Icons.smartphone,
        color: const Color(0xFF8E8E93),
      ),
      value: index?.toString(),
      valueStyle: const TextStyle(fontWeight: FontWeight.w600),
      onTap: match == null || onTap == null
          ? null
          : () => onTap!(match.device.slug),
    );
  }
}

/// 기기 안 AI 를 못 쓰는 이유를 한 줄로. 쓸 수 있으면 null.
String? _onDeviceNote(BuiltInAiAvailability? status) => switch (status) {
  null ||
  BuiltInAiAvailability.available ||
  BuiltInAiAvailability.downloadable ||
  BuiltInAiAvailability.downloading => null,
  BuiltInAiAvailability.unavailableDisabled => K.aiEngineDisabled,
  _ => K.aiEngineUnavailable,
};

String _themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => K.themeLight,
  ThemeMode.dark => K.themeDark,
  ThemeMode.system => K.themeSystem,
};

String _fxLine(FxRate rate) {
  final won = rate.krwPerUsd.round().toString();
  final grouped = StringBuffer();
  for (var i = 0; i < won.length; i++) {
    if (i > 0 && (won.length - i) % 3 == 0) grouped.write(',');
    grouped.write(won[i]);
  }
  final day = rate.asOf.toIso8601String().split('T').first;
  final key = rate.origin == RateOrigin.live ? K.fxNote : K.fxNoteOffline;
  return key.tr(args: <String>[grouped.toString(), day]);
}

/// AI 엔진. 선택지마다 설명이 필요해서 메뉴가 아니라 페이지다.
class _AiEnginePage extends ConsumerWidget {
  const _AiEnginePage({required this.status});

  final BuiltInAiAvailability? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(aiEngineProvider);
    final note = _onDeviceNote(status);
    return TpPage(
      title: K.aiEngine.tr(),
      largeTitle: false,
      onBack: () => Navigator.of(context).pop(),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TpGroup(
              footer: note?.tr(),
              children: <Widget>[
                for (final option in TpAiEngine.values)
                  TpRow(
                    title: option.key.tr(),
                    checked: option == current,
                    dimmed: option == TpAiEngine.onDevice && note != null,
                    chevron: false,
                    onTap: () => unawaited(
                      ref.read(aiEngineProvider.notifier).set(option),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.name, this.email, this.onEdit, this.photoUrl});

  final String? name;
  final String? email;
  final VoidCallback? onEdit;

  /// 올린 사진. 없으면 이니셜 원이다.
  final String? photoUrl;

  /// 이름에서 이니셜 두 글자. 없으면 이메일 첫 글자.
  static String initials(String? name, String? email) {
    final parts = (name ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length >= 2) {
      return (parts.first[0] + parts[1][0]).toUpperCase();
    }
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    final e = (email ?? '').trim();
    return e.isEmpty ? '?' : e[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final avatar = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Container(
        width: 56,
        height: 56,
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: TpTokens.blue,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: photoUrl == null
            ? _initials(name, email)
            : Image.network(
                photoUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initials(name, email),
              ),
      ),
    );
    return TpRow(
      title: name ?? K.noAccountYet.tr(),
      subtitle: email,
      value: onEdit == null ? null : K.editProfile.tr(),
      valueStyle: const TextStyle(fontSize: 15),
      titleStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: sys.label,
      ),
      leading: avatar,
      onTap: onEdit,
      semanticsLabel: <String>[
        name ?? K.noAccountYet.tr(),
        ?email,
        if (onEdit != null) K.editProfile.tr(),
      ].join(', '),
    );
  }

  static Widget _initials(String? name, String? email) => Text(
    initials(name, email),
    maxLines: 1,
    softWrap: false,
    style: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
  );
}

/// 축 하나의 비중. 움직이면 앱 전체 지수가 즉시 다시 계산된다.
class _WeightSlider extends StatelessWidget {
  const _WeightSlider({
    required this.kind,
    required this.value,
    required this.onChanged,
  });

  /// 0–1 을 나누는 걸음 수. 5% 씩이다.
  static const int steps = 20;

  final TpAxisKind kind;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 슬라이더가 축 이름과 값을 같이 읽는다. 글자 줄은 보이기만 한다.
          ExcludeSemantics(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    SpecLabels.axis(kind),
                    style: type.body,
                    maxLines: 1,
                    softWrap: false,
                    // softWrap 이 false 면 기본이 clip 이라 글리프 한가운데서
                    // 잘린다.
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  // 0.25 -> 25%. 합이 1 이 아니어도 되니 비율이 아니라 비중이다.
                  '${(value * 100).round()}',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: type.body.copyWith(fontWeight: t.boldWeight),
                ),
              ],
            ),
          ),
          TpSlider(
            value: value.clamp(0, 1),
            // **걸음을 준다.** 연속이면 손가락이 지나는 픽셀마다 onChanged 가
            // 울리고, 그때마다 카탈로그 154종이 다시 줄 세워진다. 탭 다섯이
            // IndexedStack 안에 다 살아 있어서 랭킹·비교·홈이 같이 돈다.
            // 5% 걸음이면 명세의 "손가락을 따라 지수가 다시 계산된다"는
            // 그대로 유지하면서 한 번 끄는 동안 300번이 20번이 된다.
            divisions: steps,
            // 축 이름이 옆줄에 따로 있어서, 스크린 리더는 그냥 퍼센트만
            // 읽었다 — 어느 축인지 알 수 없었다.
            label: '${SpecLabels.axis(kind)} ${(value * 100).round()}',
            semanticFormatterCallback: (v) =>
                '${SpecLabels.axis(kind)} ${(v * 100).round()}',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    this.value,
    this.onTap,
    this.toggled,
    this.switchValue,
    this.menu = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;

  /// 켜고 끄는 줄이면 지금 상태.
  final bool? toggled;
  final bool? switchValue;

  /// 누르면 풀다운 메뉴가 뜨는 줄. 오른쪽에 위아래 화살표.
  final bool menu;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return TpRow(
      title: label,
      value: value,
      onTap: onTap,
      toggled: toggled,
      dimmed: onTap == null,
      chevron: !menu && switchValue == null && onTap != null,
      semanticsLabel: value == null ? label : '$label, $value',
      trailing: switchValue != null
          ? TpSwitch(value: switchValue!, onChanged: (_) => onTap?.call())
          : menu
          ? Icon(
              context.tp.isGlass
                  ? CupertinoIcons.chevron_up_chevron_down
                  : Icons.unfold_more,
              size: 16,
              color: sys.label3,
            )
          : null,
    );
  }
}

/// 글자 버튼(되돌리기, 버전 줄).
class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onTap, this.small = false});

  final String label;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: TpTappable(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: small ? 13 : 15,
              color: context.sys.accentText,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 로그아웃 확인. 경고색이 없는 팔레트라 버튼 순서와 문구로 구분한다.
Future<void> _confirmLogout(BuildContext context, VoidCallback onLogout) async {
  if (context.tp.isGlass) {
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (popup) => CupertinoActionSheet(
        message: Text(K.logoutConfirm.tr()),
        actions: <Widget>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(popup).pop(true),
            child: Text(K.logout.tr()),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(popup).pop(false),
          child: Text(K.cancel.tr()),
        ),
      ),
    );
    if (confirmed ?? false) onLogout();
    return;
  }
  final type = context.tpText;
  final confirmed = await showTpSheet<bool>(
    context: context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            K.logoutConfirm.tr(),
            style: type.secondary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TpButton(
            label: K.logout.tr(),
            kind: TpButtonKind.secondary,
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: 8),
          TpButton(
            label: K.cancel.tr(),
            kind: TpButtonKind.plain,
            haptic: TpHaptic.none,
            onTap: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    ),
  );
  if (confirmed ?? false) onLogout();
}
