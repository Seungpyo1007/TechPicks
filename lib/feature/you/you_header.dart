part of 'you_screen.dart';

/// 내 기기의 지수와 순위. 카탈로그에 없으면 둘 다 null.
({int? index, int? rank}) _thisPhoneScore(WidgetRef ref) {
  final match = ref.watch(thisDeviceMatchProvider);
  if (match == null) return (index: null, rank: null);
  final weights = ref.watch(weightsProvider);
  final ranked = ref.watch(pickerRankedProvider);
  final at = ranked.indexWhere((d) => d.slug == match.device.slug);
  return (
    index: TpIndex.of(match.device.score, weights),
    rank: at < 0 ? null : at + 1,
  );
}

/// iOS 머리 카드. 84 원, 이름, 주소와 로그인 방법, 통계 띠.
class _ProfileCard extends ConsumerWidget {
  const _ProfileCard({
    this.name,
    this.email,
    this.method,
    this.photoUrl,
    this.unverified = false,
    this.onEdit,
  });

  final String? name;
  final String? email;
  final AuthMethod? method;
  final String? photoUrl;
  final bool unverified;
  final VoidCallback? onEdit;

  static const double avatar = 84;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sys = context.sys;
    final shortlist = ref.watch(shortlistProvider).length;
    final recent = ref.watch(recentHitsProvider).length;
    final phone = _thisPhoneScore(ref).index;
    final initials = Text(
      _ProfileHeader.initials(name, email),
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
    final via = switch (method) {
      AuthMethod.apple => K.viaApple.tr(),
      AuthMethod.google => K.viaGoogle.tr(),
      AuthMethod.email || null => null,
    };
    final stats = <(String, String)>[
      ('$shortlist', K.shortlist.tr()),
      ('$recent', K.recent.tr()),
      (phone?.toString() ?? '–', K.thisPhone.tr()),
    ];

    final card = Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      decoration: BoxDecoration(
        color: sys.cell,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: <Widget>[
          TpPopIn(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Container(
                width: avatar,
                height: avatar,
                clipBehavior: Clip.antiAlias,
                decoration: const BoxDecoration(
                  color: TpTokens.blue,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: photoUrl == null
                    ? initials
                    : Image.network(
                        photoUrl!,
                        width: avatar,
                        height: avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => initials,
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name ?? email ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: sys.label,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: <Widget>[
              if (name != null && (email?.isNotEmpty ?? false))
                Text(email!, style: TextStyle(fontSize: 15, color: sys.label2)),
              if (unverified)
                _Badge(
                  label: K.unverified.tr(),
                  icon: CupertinoIcons.envelope,
                  color: const Color(0xFFD04E00),
                )
              else if (via != null)
                _Badge(
                  label: via,
                  icon: method == AuthMethod.apple ? Icons.apple : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: sys.fill3,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: <Widget>[
                for (final (value, label) in stats)
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          value,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: sys.label,
                            fontFeatures: const <FontFeature>[
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: sys.label2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Semantics(
        button: onEdit != null,
        label: <String>[
          ?name,
          if (email?.isNotEmpty ?? false) email!,
          ?via,
          if (unverified) K.unverified.tr(),
          for (final (value, label) in stats) '$label $value',
        ].join(', '),
        excludeSemantics: true,
        onTap: onEdit,
        child: TpTappable(onTap: onEdit, press: true, child: card),
      ),
    );
  }
}

/// 주소 옆 작은 알약. 로그인 방법, 메일 확인 여부.
class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;

  /// null 이면 회색 바탕에 글자색.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final fg = color ?? sys.label;
    return Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: .14) ?? sys.fill3,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// "내 선택" 두 칸. 가중치 모양과 이 기기 지수.
class _YourPicks extends ConsumerWidget {
  const _YourPicks({required this.onWeights, this.onDeviceTap});

  final VoidCallback onWeights;
  final ValueChanged<String>? onDeviceTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(weightsProvider);
    final asyncDevice = ref.watch(thisDeviceProvider);
    final device = asyncDevice.value;
    final match = ref.watch(thisDeviceMatchProvider);
    final score = _thisPhoneScore(ref);
    final reading = asyncDevice is AsyncLoading && !asyncDevice.hasError;

    final title = device != null
        ? (match?.device.name ?? device.name)
        : reading
        ? ''
        : K.yourDeviceUnavailable.tr();
    final subtitle = match == null
        ? (device != null ? K.yourDeviceUnknown.tr() : null)
        : <String>[
            K.thisPhone.tr(),
            if (score.rank != null) '#${score.rank}',
          ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _BigHeader(K.yourPicks.tr(), inset: 4),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _PickTile(
                    title: K.weights.tr(),
                    subtitle: _weightsSummary(weights),
                    tile: const TpIconTile(
                      icon: CupertinoIcons.slider_horizontal_3,
                    ),
                    corner: ExcludeSemantics(
                      child: SizedBox.square(
                        dimension: 64,
                        child: CustomPaint(
                          painter: _RadarPainter(
                            values: _radarValues(weights),
                            labels: const <String>[],
                            sys: context.sys,
                            compact: true,
                          ),
                        ),
                      ),
                    ),
                    onTap: onWeights,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickTile(
                    title: title,
                    subtitle: subtitle,
                    tile: const TpIconTile(
                      icon: CupertinoIcons.device_phone_portrait,
                      color: Color(0xFF8E8E93),
                    ),
                    corner: score.index == null
                        ? null
                        : TpNumber(
                            '${score.index}',
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 44,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.76,
                              color: TpSys.accent,
                            ),
                          ),
                    value: score.index?.toString(),
                    onTap: match == null || onDeviceTap == null
                        ? null
                        : () => onDeviceTap!(match.device.slug),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 내 선택 한 칸. 위에 아이콘과 그림, 아래에 제목 두 줄.
class _PickTile extends StatelessWidget {
  const _PickTile({
    required this.title,
    required this.tile,
    this.subtitle,
    this.corner,
    this.value,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget tile;
  final Widget? corner;

  /// 그림 대신 읽힐 값(지수).
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final body = Container(
      constraints: const BoxConstraints(minHeight: 140),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sys.cell,
        borderRadius: BorderRadius.circular(TpGroup.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[tile, ?corner],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: sys.label,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: sys.label2),
                ),
            ],
          ),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      label: <String>[title, ?subtitle, ?value].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: TpTappable(onTap: onTap, press: true, child: body),
    );
  }
}

/// 카드 묶음 위 큰 제목("내 선택", "설정"). 화면 끝에서 20.
class _BigHeader extends StatelessWidget {
  const _BigHeader(this.text, {this.inset = 20});

  final String text;
  final double inset;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(inset, 0, inset, 10),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: context.sys.label,
        ),
      ),
    ),
  );
}
