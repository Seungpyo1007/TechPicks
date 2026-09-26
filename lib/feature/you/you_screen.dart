import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gemma_builtin_ai/flutter_gemma_builtin_ai.dart'
    show BuiltInAiAvailability;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../app/locale_controller.dart';
import '../../core/error_reporter.dart';
import '../../data/service/auth_service.dart';
import '../../data/service/link_opener.dart';
import '../../domain/model/tp_money.dart';
import '../../domain/model/tp_weights.dart';
import '../../shared/coach/tp_coach.dart';
import '../../shared/copy_keys.dart';
import '../login/login_screen.dart' show authMessage;
import 'profile_edit_screen.dart';
import 'sources_screen.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/spec_labels.dart';
import '../../shared/tp_haptics.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_menu.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_button.dart';
import '../../shared/widgets/tp_sheet.dart';
import '../../shared/widgets/tp_slider.dart';
import '../../shared/widgets/tp_switch.dart';
import '../../shared/widgets/tp_number.dart';
import '../../shared/widgets/tp_arrive.dart';
import '../../shared/widgets/tp_pop_in.dart';

part 'account_screen.dart';
part 'priorities_screen.dart';

/// 내 정보.
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({
    super.key,
    this.name,
    this.email,
    this.method,
    this.emailVerified = true,
    this.onEditProfile,
    this.onChangePassword,
    this.onLogout,
    this.onSignIn,
    this.onDeviceTap,
    this.onSources,
    this.onClose,
    this.onBack,
  });

  /// 시트 닫기.
  final VoidCallback? onClose;

  /// 밀어 올린 화면에서 뒤로.
  final VoidCallback? onBack;

  /// 로그인 전에는 둘 다 null 이다. 인증 연결은 로그인 화면에서 한다.
  final String? name;
  final String? email;

  /// 어떻게 로그인했는지. 이메일 가입만 비밀번호를 바꿀 수 있다.
  final AuthMethod? method;

  /// 이메일 가입인데 아직 확인 링크를 안 눌렀으면 false.
  final bool emailVerified;

  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogout;

  /// 로그인 시트를 연다.
  final VoidCallback? onSignIn;

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
    final hasAccount = name != null || (email?.isNotEmpty ?? false);

    final glass = t.isGlass;
    final rate = ref.watch(fxRateProvider).value ?? FxRate.fallback;
    IconData icon(IconData ios, IconData android) => glass ? ios : android;

    Widget menuRow(
      String label,
      String value,
      Widget leading,
      List<TpMenuItem> items,
    ) => TpMenu(
      items: items,
      builder: (context, open) => _SettingRow(
        label: label,
        value: value,
        leading: leading,
        onTap: open,
        menu: true,
      ),
    );

    var row = 0;
    Widget arrive(Widget child) => TpArrive(index: row++, child: child);

    return TpPage(
      title: K.you.tr(),
      // 밀려 들어온 화면이면 큰 제목과 뒤로 버튼, 시트면 작은 제목과 완료.
      largeTitle: widget.onBack != null,
      onBack: widget.onBack,
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
                footer: _notice,
                children: <Widget>[
                  arrive(
                    hasAccount
                        ? _ProfileHeader(
                            photoUrl: ref
                                .watch(profileProvider)
                                .value
                                ?.photoUrl,
                            name: name,
                            email: email,
                            method: widget.method,
                            unverified: !widget.emailVerified,
                            onEdit: () => unawaited(_openAccount()),
                          )
                        : _SignedOut(onSignIn: widget.onSignIn),
                  ),
                ],
              ),
              TpGroup(
                children: <Widget>[
                  arrive(
                    _SettingRow(
                      label: K.weights.tr(),
                      value: _weightsSummary(weights),
                      leading: TpIconTile(
                        icon: icon(
                          CupertinoIcons.slider_horizontal_3,
                          Icons.tune,
                        ),
                      ),
                      onTap: () => unawaited(_openPriorities()),
                    ),
                  ),
                  arrive(_YourDevice(onTap: widget.onDeviceTap)),
                ],
              ),
              TpGroup(
                footer: _fxLine(rate),
                children: <Widget>[
                  arrive(
                    locale != null
                        ? menuRow(
                            K.language.tr(),
                            locale.current.label,
                            TpIconTile(
                              icon: icon(CupertinoIcons.globe, Icons.language),
                              color: const Color(0xFF007AFF),
                            ),
                            <TpMenuItem>[
                              for (final option in TpLocale.values)
                                TpMenuItem(
                                  label: option.label,
                                  checked: option == locale.current,
                                  onTap: () => unawaited(locale.set(option)),
                                ),
                            ],
                          )
                        : _SettingRow(
                            label: K.language.tr(),
                            value: TpLocale.en.label,
                            leading: TpIconTile(
                              icon: icon(CupertinoIcons.globe, Icons.language),
                              color: const Color(0xFF007AFF),
                            ),
                          ),
                  ),
                  arrive(
                    menuRow(
                      K.darkMode.tr(),
                      _themeLabel(themeMode).tr(),
                      TpIconTile(
                        icon: icon(CupertinoIcons.moon_fill, Icons.dark_mode),
                        color: const Color(0xFF5856D6),
                      ),
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
                  ),
                  arrive(
                    menuRow(
                      K.currency.tr(),
                      K.currencyOf(currency).tr(),
                      TpIconTile(
                        icon: icon(
                          CupertinoIcons.money_dollar_circle_fill,
                          Icons.payments,
                        ),
                        color: const Color(0xFF34C759),
                      ),
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
                  ),
                  arrive(
                    _SettingRow(
                      label: K.aiEngine.tr(),
                      value: aiEngine.key.tr(),
                      leading: TpIconTile(
                        icon: icon(CupertinoIcons.sparkles, Icons.auto_awesome),
                        color: const Color(0xFFAF52DE),
                      ),
                      onTap: () => _openAiEngine(context, aiEngine, onDevice),
                    ),
                  ),
                  arrive(
                    _SettingRow(
                      label: K.notifications.tr(),
                      leading: TpIconTile(
                        icon: icon(
                          CupertinoIcons.bell_fill,
                          Icons.notifications,
                        ),
                        color: const Color(0xFFFF3B30),
                      ),
                      switchValue: notifications,
                      toggled: notifications,
                      onTap: () => ref
                          .read(notificationsProvider.notifier)
                          .set(!notifications),
                    ),
                  ),
                ],
              ),
              TpGroup(
                footer: _coachNotice,
                children: <Widget>[
                  arrive(
                    _SettingRow(
                      label: K.coachReplay.tr(),
                      leading: TpIconTile(
                        icon: icon(
                          CupertinoIcons.lightbulb_fill,
                          Icons.lightbulb,
                        ),
                        color: const Color(0xFFFF9500),
                      ),
                      onTap: () => unawaited(_replayCoach()),
                      plain: true,
                    ),
                  ),
                  arrive(
                    _SettingRow(
                      label: K.sources.tr(),
                      leading: TpIconTile(
                        icon: icon(CupertinoIcons.doc_text_fill, Icons.article),
                        color: const Color(0xFF8E8E93),
                      ),
                      onTap: widget.onSources ?? _openSources,
                    ),
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

  /// "안내 다시 보기" 아래 한 줄.
  String? _coachNotice;

  /// 소개 화면부터 다시. 화면 안 안내도 각 탭에서 다시 뜬다.
  Future<void> _replayCoach() async {
    await TpCoach.resetAll();
    TpHaptics.commit();
    if (!mounted) return;
    setState(() => _coachNotice = K.coachReplayed.tr());
    await ref.read(onboardingDoneProvider.notifier).replay();
  }

  Route<T> _route<T>(WidgetBuilder builder) => context.tp.isGlass
      ? CupertinoPageRoute<T>(builder: builder)
      : MaterialPageRoute<T>(builder: builder);

  Future<void> _openPriorities() => Navigator.of(context).push(
    _route<void>(
      (context) => PrioritiesScreen(onBack: () => Navigator.of(context).pop()),
    ),
  );

  /// 계정 화면. 지우고 나오면 무엇이 됐는지 머리 아래에 적는다.
  Future<void> _openAccount() async {
    final message = await Navigator.of(context).push<String>(
      _route<String>(
        (context) => AccountScreen(
          name: name,
          email: email,
          method: widget.method,
          emailVerified: widget.emailVerified,
          onEditProfile: widget.onEditProfile,
          onChangePassword: widget.onChangePassword,
          onLogout: widget.onLogout,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted && message != null) setState(() => _notice = message);
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

  Future<void> _openSources() => Navigator.of(context).push(
    _route<void>(
      (context) => SourcesScreen(onBack: () => Navigator.of(context).pop()),
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
      numeric: true,
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
  const _ProfileHeader({
    this.name,
    this.email,
    this.method,
    this.onEdit,
    this.photoUrl,
    this.unverified = false,
  });

  final String? name;
  final String? email;
  final AuthMethod? method;
  final VoidCallback? onEdit;

  /// 메일 주소를 아직 확인 안 했으면 이름 옆 한 마디.
  final bool unverified;

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
    final guest = photoUrl == null && initials(name, email) == '?';
    final avatar = MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: Container(
        width: 56,
        height: 56,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // 손님은 "?" 대신 시스템 연락처처럼 회색 원에 사람 모양.
          color: guest ? sys.fill : TpTokens.blue,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: guest
            ? Icon(
                context.tp.isGlass ? CupertinoIcons.person_fill : Icons.person,
                size: 30,
                color: Colors.white,
              )
            : photoUrl == null
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
    // 이메일 옆에 어떻게 들어왔는지. Apple 의 가린 주소는 알아보기 어렵다.
    final via = switch (method) {
      AuthMethod.apple => K.viaApple.tr(),
      AuthMethod.google => K.viaGoogle.tr(),
      AuthMethod.email || null => null,
    };
    final subtitle = <String>[
      if (email?.isNotEmpty ?? false) email!,
      ?via,
      if (unverified) K.unverified.tr(),
    ].join(' · ');
    return TpRow(
      title: name ?? email ?? '',
      subtitle: subtitle.isEmpty ? null : subtitle,
      titleStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: sys.label,
      ),
      leading: avatar,
      onTap: onEdit,
      semanticsLabel: <String>[
        ?name,
        if (subtitle.isNotEmpty) subtitle,
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

/// 로그인 전 머리. 무엇이 따라오는지 한 줄, 그리고 로그인.
class _SignedOut extends StatelessWidget {
  const _SignedOut({this.onSignIn});

  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: sys.fill,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    glass ? CupertinoIcons.person_fill : Icons.person,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      K.guestTitle.tr(),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: sys.label,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      K.guestBody.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.3,
                        color: sys.label2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TpPill(
            label: K.signIn.tr(),
            height: glass ? 44 : 40,
            onTap: onSignIn,
          ),
        ],
      ),
    );
  }
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
                TpNumber(
                  // 0.25 -> 25%. 합이 1 이 아니어도 되니 비율이 아니라 비중이다.
                  '${(value * 100).round()}',
                  maxLines: 1,
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
    this.leading,
    this.plain = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;

  /// 설정 앱식 색 아이콘 타일.
  final Widget? leading;

  /// 누르면 바로 일이 일어나는 줄(화면이 안 바뀜). 화살표가 없다.
  final bool plain;

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
      leading: leading,
      chevron: !menu && !plain && switchValue == null && onTap != null,
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

/// 계정 삭제 확인. 이메일 가입이면 비밀번호도 받는다(다시 인증).
///
/// 지우기로 하면 비밀번호(없으면 빈 문자열), 그만두면 null.
Future<String?> _confirmDelete(
  BuildContext context, {
  required bool askPassword,
}) {
  final password = TextEditingController();
  final body = Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Text(K.deleteConfirm.tr()),
      if (askPassword) ...<Widget>[
        const SizedBox(height: 8),
        Text(K.deletePassword.tr()),
        const SizedBox(height: 10),
        if (context.tp.isGlass)
          CupertinoTextField(
            controller: password,
            obscureText: true,
            autofocus: true,
            autofillHints: const <String>[AutofillHints.password],
            placeholder: K.passwordLabel.tr(),
          )
        else
          TextField(
            controller: password,
            obscureText: true,
            autofocus: true,
            autofillHints: const <String>[AutofillHints.password],
            decoration: InputDecoration(labelText: K.passwordLabel.tr()),
          ),
      ],
    ],
  );
  final Future<String?> shown = context.tp.isGlass
      ? showCupertinoDialog<String>(
          context: context,
          builder: (dialog) => CupertinoAlertDialog(
            title: Text(K.deleteAccount.tr()),
            content: body,
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.of(dialog).pop(),
                child: Text(K.cancel.tr()),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.of(dialog).pop(password.text),
                child: Text(K.delete.tr()),
              ),
            ],
          ),
        )
      : showDialog<String>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: Text(K.deleteAccount.tr()),
            content: body,
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(),
                child: Text(K.cancel.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialog).pop(password.text),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialog).colorScheme.error,
                ),
                child: Text(K.delete.tr()),
              ),
            ],
          ),
        );
  return shown.whenComplete(password.dispose);
}
