part of 'you_screen.dart';

/// 계정. 내 정보 맨 위 카드를 누르면 온다.
///
/// 지우거나 나가면 내 정보로 돌아가고, 무엇이 됐는지는 그쪽 머리 아래에 적힌다.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({
    super.key,
    this.name,
    this.email,
    this.method,
    this.emailVerified = true,
    this.onEditProfile,
    this.onChangePassword,
    this.onLogout,
    this.onBack,
  });

  final String? name;
  final String? email;
  final AuthMethod? method;
  final bool emailVerified;
  final VoidCallback? onEditProfile;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogout;
  final VoidCallback? onBack;

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  String? _notice;

  bool get _emailAccount =>
      (widget.method ?? AuthMethod.email) == AuthMethod.email;

  @override
  Widget build(BuildContext context) {
    final glass = context.tp.isGlass;
    IconData icon(IconData ios, IconData android) => glass ? ios : android;
    final email = widget.email;
    final VoidCallback? logout = widget.onLogout == null
        ? null
        : () => unawaited(
            _confirmLogout(context, () {
              widget.onLogout!();
              Navigator.of(context).maybePop();
            }),
          );
    void delete() => unawaited(_deleteAccount());
    return TpPage(
      title: K.account.tr(),
      largeTitle: false,
      onBack: widget.onBack,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              _AccountHero(
                photoUrl: ref.watch(profileProvider).value?.photoUrl,
                name: widget.name,
                email: email,
                method: widget.method,
                verified: (email?.isNotEmpty ?? false)
                    ? widget.emailVerified
                    : null,
              ),
              const SizedBox(height: 24),
              if (!widget.emailVerified)
                TpGroup(
                  children: <Widget>[
                    TpArrive(
                      index: 0,
                      child: TpRow(
                        title: K.verifyEmail.tr(),
                        leading: TpIconTile(
                          icon: icon(
                            CupertinoIcons.envelope_badge_fill,
                            Icons.mark_email_unread,
                          ),
                          color: const Color(0xFFFF9500),
                        ),
                        chevron: false,
                        trailing: _Link(
                          label: K.resend.tr(),
                          onTap: () => unawaited(_resendVerification()),
                        ),
                      ),
                    ),
                  ],
                ),
              TpGroup(
                footer: _notice,
                children: <Widget>[
                  TpArrive(
                    index: 1,
                    child: _SettingRow(
                      label: K.editProfile.tr(),
                      leading: TpIconTile(
                        icon: icon(
                          CupertinoIcons.person_crop_circle_fill,
                          Icons.person,
                        ),
                      ),
                      onTap: widget.onEditProfile ?? _openProfile,
                    ),
                  ),
                  if (_emailAccount && (email?.isNotEmpty ?? false))
                    TpArrive(
                      index: 2,
                      child: _SettingRow(
                        label: K.changePassword.tr(),
                        leading: TpIconTile(
                          icon: icon(CupertinoIcons.lock_fill, Icons.lock),
                          color: const Color(0xFF8E8E93),
                        ),
                        onTap:
                            widget.onChangePassword ??
                            () => unawaited(_resetPassword()),
                      ),
                    ),
                ],
              ),
              // iOS 는 로그아웃과 계정 삭제가 카드 두 장이고, 삭제 아래에
              // 무엇이 지워지는지 한 줄. Android 는 면 없는 빨간 줄 둘.
              if (glass) ...<Widget>[
                TpArrive(
                  index: 3,
                  child: _AccountAction(label: K.logout.tr(), onTap: logout),
                ),
                TpArrive(
                  index: 4,
                  child: _AccountAction(
                    label: K.deleteAccount.tr(),
                    destructive: true,
                    footer: K.deleteNote.tr(),
                    onTap: delete,
                  ),
                ),
              ] else
                TpGroup(
                  children: <Widget>[
                    TpRow(
                      title: K.logout.tr(),
                      destructive: true,
                      chevron: false,
                      onTap: logout,
                    ),
                    TpRow(
                      title: K.deleteAccount.tr(),
                      destructive: true,
                      chevron: false,
                      onTap: delete,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _resetPassword() async {
    final address = widget.email ?? '';
    final failure = await ref
        .read(currentUserProvider.notifier)
        .sendPasswordReset(address);
    if (!mounted) return;
    setState(() {
      _notice = failure == null
          ? K.pwResetSent.tr(args: <String>[address])
          : K.pwResetFailed.tr();
    });
  }

  Future<void> _resendVerification() async {
    final failure = await ref
        .read(currentUserProvider.notifier)
        .resendVerification();
    if (!mounted) return;
    setState(() {
      _notice = failure == null
          ? K.verifySent.tr()
          : authMessage(failure) ?? K.authFailed.tr();
    });
  }

  /// 확인 → (이메일 가입이면) 비밀번호 → 삭제. Apple·Google 은 삭제 중에
  /// 시스템 로그인 창이 한 번 더 뜬다(다시 인증).
  Future<void> _deleteAccount() async {
    final answer = await _confirmDelete(context, askPassword: _emailAccount);
    if (answer == null || !mounted) return;
    final failure = await ref
        .read(currentUserProvider.notifier)
        .deleteAccount(password: _emailAccount ? answer : null);
    if (!mounted) return;
    if (failure == AuthFailure.canceled) return;
    if (failure == null) {
      TpHaptics.commit();
      await Navigator.of(context).maybePop(K.deleted.tr());
      return;
    }
    setState(() => _notice = authMessage(failure) ?? K.authFailed.tr());
  }

  /// 프로필 편집 화면. v1 은 사진과 다섯 칸을 갖고 있었다.
  Future<void> _openProfile() => Navigator.of(context).push(
    context.tp.isGlass
        ? CupertinoPageRoute<void>(
            builder: (context) =>
                ProfileEditScreen(onBack: () => Navigator.of(context).pop()),
          )
        : MaterialPageRoute<void>(
            builder: (context) =>
                ProfileEditScreen(onBack: () => Navigator.of(context).pop()),
          ),
  );
}

/// iOS 계정 화면의 로그아웃·삭제 한 장. 가운데 글자 카드.
class _AccountAction extends StatelessWidget {
  const _AccountAction({
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.footer,
  });

  final String label;
  final VoidCallback? onTap;
  final bool destructive;

  /// 카드 아래 한 줄.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, footer == null ? 10 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Semantics(
            button: onTap != null,
            label: label,
            excludeSemantics: true,
            onTap: onTap,
            child: TpTappable(
              onTap: onTap,
              press: true,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: sys.cell,
                  borderRadius: BorderRadius.circular(TpGroup.radius),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: onTap == null
                        ? sys.label3
                        : destructive
                        ? sys.destructive
                        : sys.label,
                  ),
                ),
              ),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
              child: Text(
                footer!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.38, color: sys.label2),
              ),
            ),
        ],
      ),
    );
  }
}

/// 계정 화면 머리. 큰 사진, 이름, 주소와 로그인 방법.
class _AccountHero extends StatelessWidget {
  const _AccountHero({
    this.photoUrl,
    this.name,
    this.email,
    this.method,
    this.verified,
  });

  final String? photoUrl;
  final String? name;
  final String? email;
  final AuthMethod? method;

  /// 메일 확인 여부. 주소가 없으면 null 이고 알약도 없다.
  final bool? verified;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final via = switch (method) {
      AuthMethod.apple => K.viaApple.tr(),
      AuthMethod.google => K.viaGoogle.tr(),
      AuthMethod.email || null => null,
    };
    final initials = Text(
      _ProfileHeader.initials(name, email),
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
    return Column(
      children: <Widget>[
        TpPopIn(
          child: Container(
            width: 92,
            height: 92,
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
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => initials,
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          name ?? email ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: sys.label,
          ),
        ),
        if ((email?.isNotEmpty ?? false) || via != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            <String>[if (email?.isNotEmpty ?? false) email!, ?via].join(' · '),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: sys.label2),
          ),
        ],
        // iOS 만. Android 보드는 주소 줄로 끝난다.
        if (verified != null && context.tp.isGlass) ...<Widget>[
          const SizedBox(height: 8),
          verified!
              ? _Badge(
                  label: K.emailConfirmed.tr(),
                  icon: CupertinoIcons.checkmark_seal,
                  color: const Color(0xFF248A3D),
                )
              : _Badge(
                  label: K.unverified.tr(),
                  icon: CupertinoIcons.envelope,
                  color: const Color(0xFFD04E00),
                ),
        ],
      ],
    );
  }
}
