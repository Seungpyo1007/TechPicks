import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
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

    return TpShell(
      title: t.isGlass ? null : 'You',
      tab: TpTab.you,
      onTabSelected: onTabSelected,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          if (t.isGlass) ...<Widget>[
            Text('You', style: type.largeTitle),
            const SizedBox(height: 12),
          ],

          _ProfileHeader(
            name: name,
            email: email,
            onEdit: onEditProfile,
          ),
          const SizedBox(height: 22),

          Text('What you care about'.toUpperCase(), style: type.eyebrow),
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
                        'These weights are yours. Change them and every index '
                        'recalculates.',
                        style: type.caption,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => ref.read(weightsProvider.notifier).reset(),
                      child: Text(
                        'Reset',
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

          const TpSurface(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                _SettingRow(label: 'Language', value: 'English'),
                _SettingRow(label: 'Dark mode', value: 'Off'),
                _SettingRow(label: 'Notifications', value: 'On'),
                _SettingRow(label: 'Currency', value: 'USD', last: true),
              ],
            ),
          ),
          const SizedBox(height: 14),

          TpSurface(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: <Widget>[
                _SettingRow(
                  label: 'Change password',
                  onTap: onChangePassword,
                ),
                _SettingRow(
                  label: 'Log out',
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
                name ?? 'Browsing without an account',
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
                  'Edit profile',
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
                  SpecLabels.axis[kind] ?? kind.key,
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
