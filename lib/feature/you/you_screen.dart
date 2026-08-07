import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../app/locale_controller.dart';
import '../../shared/copy_keys.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_surface.dart';

/// 내 정보.
///
/// v1 의 Profile / EditProfileScreen / ChangePassword / PhoneSetting 네 화면을
/// 하나로 합친다.
///
/// 카피는 아직 하드코딩이다.
class YouScreen extends ConsumerWidget {
  const YouScreen({
    super.key,
    this.onTabSelected,
    this.name,
    this.email,
    this.onEditProfile,
    this.onChangePassword,
    this.onLogout,
  });

  final ValueChanged<TpTab>? onTabSelected;

  /// 로그인 전에는 둘 다 null 이다. 인증 연결은 로그인 화면에서 한다.
  final String? name;
  final String? email;

  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogout;

  /// 앱 버전. 명세의 푸터 문구 그대로.
  static const String versionLine = 'TechPicks version 2.0.0 · Apache-2.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tp;
    final type = context.tpText;
    final weights = ref.watch(weightsProvider);
    final locale = ref.watch(localeControllerProvider);
    final notifications = ref.watch(notificationsProvider);

    return TpShell(
      title: t.isGlass ? null : K.you.tr(),
      tab: TpTab.you,
      onTabSelected: onTabSelected,
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
            onEdit: onEditProfile,
          ),
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
                      child: Text(
                        K.prioritiesNote.tr(),
                        style: type.caption,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => ref.read(weightsProvider.notifier).reset(),
                      child: Text(
                        K.reset.tr(),
                        style: type.caption.copyWith(color: TpTokens.blue),
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
                _SettingRow(
                  label: K.changePassword.tr(),
                  onTap: onChangePassword,
                ),
                _SettingRow(
                  label: K.logout.tr(),
                  onTap: onLogout,
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(versionLine, style: type.caption),
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
            GestureDetector(
              behavior: HitTestBehavior.opaque,
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
                      const Icon(Icons.check, size: 18, color: TpTokens.blue)
                    else
                      SizedBox(width: 18, height: 18, child: ColoredBox(
                        color: t.track.withValues(alpha: 0),
                      )),
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
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1)
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
            style: type.cardTitle.copyWith(
              fontSize: 22,
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
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onEdit,
                child: Text(
                  K.editProfile.tr(),
                  style: type.caption.copyWith(color: TpTokens.blue),
                ),
              ),
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
            child: Slider(
              value: value.clamp(0, 1),
              onChanged: onChanged,
            ),
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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: t.hairline)),
        ),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label, style: type.body)),
            if (value != null)
              Text(value!, style: type.secondary)
            else
              Icon(Icons.chevron_right, size: 18, color: t.dim),
          ],
        ),
      ),
    );
  }
}
