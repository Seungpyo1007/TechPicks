import 'dart:async' show unawaited;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../app/locale_controller.dart';
import '../../core/error_reporter.dart';
import '../../data/service/link_opener.dart';
import '../../shared/copy_keys.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../shared/widgets/tp_press.dart';

/// 내 정보.
///
/// v1 의 Profile / EditProfileScreen / ChangePassword / PhoneSetting 네 화면을
/// 하나로 합친다.
///
/// 카피는 아직 하드코딩이다.
class YouScreen extends ConsumerStatefulWidget {
  const YouScreen({
    super.key,
    this.onTabSelected,
    this.name,
    this.email,
    this.onEditProfile,
    this.onChangePassword,
    this.onLogout,
    this.onDeviceTap,
  });

  final ValueChanged<TpTab>? onTabSelected;

  /// 로그인 전에는 둘 다 null 이다. 인증 연결은 로그인 화면에서 한다.
  final String? name;
  final String? email;

  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogout;

  /// 내 기기가 카탈로그에 있으면 상세로 보낸다.
  final ValueChanged<String>? onDeviceTap;

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

  /// 이름 입력칸. 다이얼로그가 닫히는 애니메이션 중에도 살아 있어야 한다 —
  /// 닫자마자 버리면 사라지는 프레임에서 이미 버린 컨트롤러를 읽는다.
  final TextEditingController _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get name => widget.name;
  String? get email => widget.email;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final weights = ref.watch(weightsProvider);
    final locale = ref.watch(localeControllerProvider);
    final notifications = ref.watch(notificationsProvider);
    // 헤더가 "로그인 없이 사용 중"이라고 적는 것과 같은 조건이다.
    final hasAccount = name != null || (email?.isNotEmpty ?? false);

    return TpShell(
      title: t.isGlass ? null : K.you.tr(),
      tab: TpTab.you,
      onTabSelected: widget.onTabSelected,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          if (t.isGlass) ...<Widget>[
            Text(K.you.tr(), style: type.largeTitle),
            const SizedBox(height: 12),
          ],

          _ProfileHeader(
            name: name,
            email: email,
            // 계정이 없으면 고칠 프로필도 없다. 손님에게 이름 바꾸기 시트를
            // 열어 주면 저장이 조용히 실패한다.
            onEdit: hasAccount ? widget.onEditProfile ?? _editName : null,
          ),
          const SizedBox(height: 22),

          _YourDevice(onTap: widget.onDeviceTap),
          const SizedBox(height: 22),

          Text(K.priorities.tr().toUpperCase(), style: type.eyebrow),
          const SizedBox(height: 8),
          TpSurface(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              children: <Widget>[
                for (final kind in TpAxisKind.values)
                  _WeightSlider(
                    kind: kind,
                    value: kind.weightIn(weights),
                    onChanged: (v) =>
                        ref.read(weightsProvider.notifier).setAxis(kind, v),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(K.prioritiesNote.tr(), style: type.caption),
                    ),
                    const SizedBox(width: 10),
                    TpTapTarget(
                      onTap: () => ref.read(weightsProvider.notifier).reset(),
                      child: Text(
                        K.reset.tr(),
                        style: type.caption.copyWith(color: TpTokens.blueText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
          const SizedBox(height: 22),

          TpSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                _SettingRow(
                  label: K.language.tr(),
                  value: (locale?.current ?? TpLocale.en).label,
                  onTap: locale == null
                      ? null
                      : () => _pickLanguage(context, ref, locale),
                ),
                // 다크 모드는 명세에 토큰이 없다. 색을 지어내지 않고 자리만 둔다.
                _SettingRow(label: K.darkMode.tr(), value: K.off.tr()),
                _SettingRow(
                  label: K.notifications.tr(),
                  value: (notifications ? K.on : K.off).tr(),
                  onTap: () => ref
                      .read(notificationsProvider.notifier)
                      .set(!notifications),
                ),
                _SettingRow(label: K.currency.tr(), value: 'USD', last: true),
              ],
            ),
          ),
          const SizedBox(height: 14),

          TpSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                // 비밀번호가 없는 계정(익명·소셜)에는 보낼 곳이 없다.
                if (email != null && email!.isNotEmpty)
                  _SettingRow(
                    label: K.changePassword.tr(),
                    onTap:
                        widget.onChangePassword ??
                        () => unawaited(_resetPassword()),
                  ),
                _SettingRow(
                  // 손님에게 "로그아웃"은 나갈 곳이 없다는 뜻으로 읽힌다.
                  // 누르면 로그인 화면으로 가니 그렇게 적는다.
                  label: (hasAccount ? K.logout : K.signIn).tr(),
                  onTap: widget.onLogout,
                  last: true,
                ),
              ],
            ),
          ),
          if (_notice != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_notice!, style: type.caption),
          ],
          const SizedBox(height: 20),

          // 푸터 문구는 명세 §13 의 확정 카피다. 글자는 그대로 두고 누르면
          // Apache-2.0 본문이 열리게만 한다.
          Align(
            alignment: Alignment.centerLeft,
            child: TpTapTarget(
              link: true,
              minSize: 44,
              onTap: () => unawaited(_openLicense()),
              child: Text(
                YouScreen.versionLine,
                // 눌리는 줄이다. 본문과 같은 회색이면 알 방법이 없다.
                style: type.caption.copyWith(color: TpTokens.blueText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 비밀번호 재설정 메일을 보낸다.
  ///
  /// 지금 비밀번호를 묻지 않는다. 그건 별도 화면과 재인증이 필요한데, 메일
  /// 한 통이면 Firebase 가 그걸 다 해준다.
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

  /// 표시 이름만 바꾼다.
  ///
  /// v1 의 EditProfileScreen 은 화면 하나를 통째로 썼는데 바꿀 수 있는 게
  /// 이름뿐이다. 시트 하나로 충분하다.
  Future<void> _editName() async {
    _name.text = name ?? '';
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(K.editProfile.tr()),
        content: TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: K.nameLabel.tr()),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(K.cancel.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(_name.text),
            child: Text(K.save.tr()),
          ),
        ],
      ),
    );

    final trimmed = next?.trim() ?? '';
    if (trimmed.isEmpty || trimmed == name) return;

    final ok = await ref.read(currentUserProvider.notifier).updateName(trimmed);
    if (!mounted || ok) return;

    setState(() => _notice = K.authFailed.tr());
  }

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
    final t = context.tp;
    final type = context.tpText;
    final device = ref.watch(thisDeviceProvider).value;
    final match = ref.watch(thisDeviceMatchProvider);
    final weights = ref.watch(weightsProvider);

    final index = match == null
        ? null
        : TpIndex.of(match.device.score, weights);

    return TpSurface(
      onTap: match == null || onTap == null
          ? null
          : () => onTap!(match.device.slug),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(K.yourDevice.tr().toUpperCase(), style: type.eyebrow),
                const SizedBox(height: 4),
                Text(
                  device == null
                      ? K.yourDeviceUnavailable.tr()
                      : (match?.device.name ?? device.name),
                  style: type.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (device != null && match == null)
                  Text(K.yourDeviceUnknown.tr(), style: type.caption),
              ],
            ),
          ),
          if (index != null) ...<Widget>[
            const SizedBox(width: 10),
            Text(
              index.toString(),
              maxLines: 1,
              softWrap: false,
              style: type.cardTitle.copyWith(fontSize: 24),
            ),
          ] else
            Icon(Icons.smartphone, size: 20, color: t.dim),
        ],
      ),
    );
  }
}

/// 언어 목록. 지원 언어가 둘뿐이라 시트 하나로 끝난다.
Future<void> _pickLanguage(
  BuildContext context,
  WidgetRef ref,
  LocaleController controller,
) async {
  final t = context.tp;
  final type = context.tpText;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => TpSurface(
      strong: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(K.language.tr(), style: type.cardTitle),
          const SizedBox(height: 8),
          for (final option in TpLocale.values)
            TpPress(
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await controller.set(option);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(option.label, style: type.body)),
                    if (option == controller.current)
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: TpTokens.blueText,
                      )
                    else
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: ColoredBox(color: t.track.withValues(alpha: 0)),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.name, this.email, this.onEdit});

  final String? name;
  final String? email;
  final VoidCallback? onEdit;

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
    final type = context.tpText;

    return Row(
      children: <Widget>[
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: TpTokens.blue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials(name, email),
            style: type.cardTitle.copyWith(fontSize: 22, color: Colors.white),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                name ?? K.noAccountYet.tr(),
                style: type.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (email != null)
                Text(
                  email!,
                  style: type.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (onEdit != null) ...<Widget>[
                const SizedBox(height: 4),
                TpTapTarget(
                  onTap: onEdit,
                  child: Text(
                    K.editProfile.tr(),
                    style: type.caption.copyWith(color: TpTokens.blueText),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  SpecLabels.axis(kind),
                  style: type.body,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              Text(
                // 0.25 -> 25%. 합이 1 이 아니어도 되니 비율이 아니라 비중이다.
                '${(value * 100).round()}',
                maxLines: 1,
                softWrap: false,
                style: type.body.copyWith(fontWeight: t.boldWeight),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: TpTokens.blue,
              inactiveTrackColor: t.track,
              thumbColor: Colors.white,
              overlayShape: SliderComponentShape.noOverlay,
            ),
            child: Slider(value: value.clamp(0, 1), onChanged: onChanged),
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
    this.last = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Semantics(
      button: onTap != null,
      // 라벨과 값이 따로 읽히면 "알림", "켬" 이 무슨 관계인지 모른다.
      label: value == null ? label : '$label, $value',
      excludeSemantics: true,
      child: TpPress(
        onTap: onTap,
        semanticsButton: false,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: t.hairline)),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  // 못 누르는 줄은 그렇게 보여야 한다. 다크 모드와 통화는
                  // 자리만 잡아둔 줄인데 알림 줄과 똑같이 생겼었다.
                  style: onTap == null
                      ? type.body.copyWith(color: t.dim)
                      : type.body,
                ),
              ),
              if (value != null)
                Text(value!, style: type.secondary)
              else
                Icon(Icons.chevron_right, size: 18, color: t.dim),
            ],
          ),
        ),
      ),
    );
  }
}
