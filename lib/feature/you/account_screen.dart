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
              TpGroup(
                children: <Widget>[
                  TpArrive(
                    index: 3,
                    child: TpRow(
                      title: K.logout.tr(),
                      destructive: true,
                      chevron: false,
                      onTap: widget.onLogout == null
                          ? null
                          : () => unawaited(
                              _confirmLogout(context, () {
                                widget.onLogout!();
                                Navigator.of(context).maybePop();
                              }),
                            ),
                    ),
                  ),
                  TpArrive(
                    index: 4,
                    child: TpRow(
                      title: K.deleteAccount.tr(),
                      destructive: true,
                      chevron: false,
                      onTap: () => unawaited(_deleteAccount()),
                    ),
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

/// 계정 화면 머리. 큰 사진, 이름, 주소와 로그인 방법.
class _AccountHero extends StatelessWidget {
  const _AccountHero({this.photoUrl, this.name, this.email, this.method});

  final String? photoUrl;
  final String? name;
  final String? email;
  final AuthMethod? method;

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
      ],
    );
  }
}
