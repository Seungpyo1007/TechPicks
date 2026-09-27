import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../core/error_reporter.dart';
import '../../data/service/auth_service.dart';
import '../../data/service/link_opener.dart';
import '../../shared/copy_keys.dart';
import '../../shared/tp_haptics.dart';
import '../../shared/figures/tp_figure.dart';
import '../../shared/figures/tp_figures.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_pulse.dart';

/// 로그인이 안 된 까닭을 사람 말로. 취소면 null — 스스로 닫은 사람에게 오류를
/// 보여주지 않는다.
String? authMessage(AuthFailure failure) => switch (failure) {
  AuthFailure.canceled => null,
  AuthFailure.badCredentials => K.authBadCredentials.tr(),
  AuthFailure.emailInUse => K.authEmailInUse.tr(),
  AuthFailure.weakPassword => K.authWeakPassword.tr(),
  AuthFailure.invalidEmail => K.emailInvalid.tr(),
  AuthFailure.network => K.authNetwork.tr(),
  AuthFailure.tooMany => K.authTooMany.tr(),
  AuthFailure.otherProvider => K.authOtherProvider.tr(),
  AuthFailure.requiresRecentLogin => K.authRecentLogin.tr(),
  AuthFailure.disabled => K.authDisabled.tr(),
  AuthFailure.notConfigured => K.authNotConfigured.tr(),
  AuthFailure.unknown => K.authFailed.tr(),
};

/// 로그인 화면. 옆에서 밀려 들어온다(push). 방법 고르기 → 이메일 → 비밀번호
/// 재설정이 화면 안에서 옆으로 밀린다. 로그인은 선택이라 언제든 뒤로 나간다.
///
/// 성공하면 체크가 한 번 튀고 화면이 닫힌다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onClose, this.onSignedIn});

  final VoidCallback? onClose;
  final VoidCallback? onSignedIn;

  /// 최소 비밀번호 길이. Firebase 가 6자 미만을 거부한다.
  static const int minPasswordLength = 6;

  /// 눈에 띄게 틀린 입력만 거른다. 진짜 검증은 서버가 한다.
  static bool looksLikeEmail(String value) {
    final v = value.trim();
    final at = v.indexOf('@');
    if (at <= 0 || at == v.length - 1) return false;
    final domain = v.substring(at + 1);
    return domain.contains('.') &&
        !domain.startsWith('.') &&
        !domain.endsWith('.') &&
        !v.contains(' ');
  }

  /// 성공 체크를 보여주는 시간.
  static const Duration doneHold = Duration(milliseconds: 1400);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<NavigatorState> _nav = GlobalKey<NavigatorState>();
  bool _done = false;

  /// 안쪽 단계가 몇 겹 쌓였는지. 첫 단계면 밖의 뒤로(밀어서 뒤로 포함)가
  /// 이 화면을 닫고, 더 들어가 있으면 안쪽 한 단계만 돌아간다.
  late final _Depth _depth = _Depth(() {
    if (mounted) setState(() {});
  });

  Route<void> _route(Widget child) => context.tp.isGlass
      ? MaterialPageRoute<void>(builder: (_) => child)
      : MaterialPageRoute<void>(builder: (_) => child);

  Future<void> _signedIn() async {
    TpHaptics.commit();
    setState(() => _done = true);
    final hold = context.motion.isReduced
        ? const Duration(milliseconds: 300)
        : LoginScreen.doneHold;
    await Future<void>.delayed(hold);
    if (mounted) widget.onSignedIn?.call();
  }

  void _toEmail() => unawaited(
    _nav.currentState!.push(
      _route(
        _EmailStep(
          onBack: () => _nav.currentState!.pop(),
          onSignedIn: _signedIn,
          onForgot: (email) => unawaited(
            _nav.currentState!.push(
              _route(
                _ResetStep(
                  email: email,
                  onBack: () => _nav.currentState!.pop(),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return PopScope(
      // 안쪽 단계에서 뒤로 가면 화면을 닫지 말고 한 단계 돌아간다. 첫 단계면
      // 그대로 나간다 — 그래야 iOS 가장자리 밀기로도 뒤로 간다.
      canPop: _depth.value <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final inner = _nav.currentState;
        if (inner != null && inner.canPop()) {
          inner.pop();
        } else {
          widget.onClose?.call();
        }
      },
      child: ColoredBox(
        color: sys.background,
        child: Stack(
          children: <Widget>[
            // 체크가 덮은 뒤로는 알약 스피너가 돌 까닭이 없다.
            TickerMode(
              enabled: !_done,
              child: Navigator(
                key: _nav,
                observers: <NavigatorObserver>[_depth],
                onGenerateInitialRoutes: (_, _) => <Route<void>>[
                  _route(
                    _OptionsStep(
                      onClose: widget.onClose,
                      onEmail: _toEmail,
                      onSignedIn: _signedIn,
                    ),
                  ),
                ],
              ),
            ),
            if (_done) const Positioned.fill(child: _Done()),
          ],
        ),
      ),
    );
  }
}

/// 로그인 방법 고르기.
class _OptionsStep extends ConsumerStatefulWidget {
  const _OptionsStep({
    required this.onEmail,
    required this.onSignedIn,
    this.onClose,
  });

  final VoidCallback onEmail;
  final VoidCallback onSignedIn;
  final VoidCallback? onClose;

  @override
  ConsumerState<_OptionsStep> createState() => _OptionsStepState();
}

class _OptionsStepState extends ConsumerState<_OptionsStep> {
  AuthMethod? _busy;
  String? _error;

  Future<void> _tap(AuthMethod method) async {
    if (_busy != null) return;
    setState(() {
      _busy = method;
      _error = null;
    });
    final result = await ref.read(currentUserProvider.notifier).signIn(method);
    if (!mounted) return;
    setState(() => _busy = null);
    if (result.ok) {
      widget.onSignedIn();
      return;
    }
    final message = authMessage(result.failure!);
    if (message == null) return;
    TpHaptics.error();
    setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final google = glass || FirebaseAuthService.googleConfiguredForAndroid;

    final buttons = <Widget>[
      if (glass)
        _AppleButton(
          dark: dark,
          busy: _busy == AuthMethod.apple,
          onTap: _busy == null ? () => unawaited(_tap(AuthMethod.apple)) : null,
        ),
      if (google)
        _GoogleButton(
          busy: _busy == AuthMethod.google,
          onTap: _busy == null
              ? () => unawaited(_tap(AuthMethod.google))
              : null,
        ),
      TpPill(
        label: K.continueEmail.tr(),
        kind: TpPillKind.tinted,
        height: glass ? 50 : 48,
        onTap: _busy == null ? widget.onEmail : null,
      ),
    ];

    return Material(
      color: sys.background,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            TpTopBar(
              safeTop: false,
              // Android 는 M3 앱 바 여백(앞 4 · 뒤 16)에 IconButton.
              padding: glass
                  ? null
                  : const EdgeInsetsDirectional.only(start: 4, end: 16),
              leading: widget.onClose == null
                  ? null
                  : glass
                  ? TpBarButton(
                      action: TpBarAction(
                        label: K.back.tr(),
                        icon: CupertinoIcons.chevron_back,
                        symbol: 'chevron.backward',
                        onTap: widget.onClose,
                      ),
                    )
                  : IconButton(
                      onPressed: widget.onClose,
                      tooltip: K.back.tr(),
                      icon: const Icon(Icons.arrow_back),
                    ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: box.maxHeight),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const Spacer(),
                            _Stagger(
                              index: 0,
                              child: _SyncCard(
                                height: (box.maxHeight * .3).clamp(
                                  130.0,
                                  230.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            _Stagger(
                              index: 1,
                              child: Text(
                                K.loginTitle.tr(),
                                textAlign: TextAlign.center,
                                // Android 는 M3 headlineMedium 28/36.
                                style: glass
                                    ? TextStyle(
                                        fontSize: 30,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                        color: sys.label,
                                      )
                                    : Theme.of(
                                        context,
                                      ).textTheme.headlineMedium!.copyWith(
                                        height: 36 / 28,
                                        color: sys.label,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _Stagger(
                              index: 2,
                              child: Text(
                                K.loginWhy.tr(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                  color: sys.label2,
                                ),
                              ),
                            ),
                            const Spacer(flex: 2),
                            for (
                              var i = 0;
                              i < buttons.length;
                              i++
                            ) ...<Widget>[
                              if (i > 0) const SizedBox(height: 12),
                              _Stagger(index: 3 + i, child: buttons[i]),
                            ],
                            if (_error != null) ...<Widget>[
                              const SizedBox(height: 14),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: sys.destructive,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            Text(
                              K.legalLine.tr(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: sys.label2,
                              ),
                            ),
                            _LegalLinks(
                              open: (url) => unawaited(
                                ref
                                    .read(linkOpenerProvider)
                                    .open(url)
                                    .catchError((Object e, StackTrace s) {
                                      TpErrors.record(
                                        e,
                                        s,
                                        reason: 'link.open',
                                      );
                                      return false;
                                    }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 기기 사이 동기화 그림. 관심 목록이 어느 기기에서든 이어진다는 뜻.
class _SyncCard extends StatelessWidget {
  const _SyncCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(24, 26, 24, 26),
    decoration: BoxDecoration(
      color: context.sys.cell,
      borderRadius: BorderRadius.circular(32),
    ),
    child: TpFigure(
      paint: TpFigures.sync,
      height: height - 52,
      delay: const Duration(milliseconds: 200),
      duration: const Duration(milliseconds: 2200),
    ),
  );
}

/// 차례로 조금 올라오며 나타난다. 동작 줄이기면 바로.
class _Stagger extends StatefulWidget {
  const _Stagger({required this.index, required this.child});

  final int index;
  final Widget child;

  static const Duration step = Duration(milliseconds: 60);

  @override
  State<_Stagger> createState() => _StaggerState();
}

class _StaggerState extends State<_Stagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.duration != null) return;
    final move = context.motion.listItem;
    _c.duration = move.duration;
    if (context.motion.isReduced) {
      _c.value = 1;
      return;
    }
    _wait = Timer(_Stagger.step * widget.index, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .25),
          end: Offset.zero,
        ).animate(t),
        child: widget.child,
      ),
    );
  }
}

/// Google 브랜드 규칙대로: 흰 바탕, 1pt 테두리, 공식 G 로고.
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onTap, this.busy = false});

  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final glass = context.tp.isGlass;
    final height = glass ? 50.0 : 48.0;
    final face = Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: const Color(0xFF747775)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (busy)
            SizedBox.square(
              dimension: 18,
              child: glass
                  ? const CupertinoActivityIndicator(color: Color(0xFF1F1F1F))
                  : const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1F1F1F),
                    ),
            )
          else
            Image.asset('assets/logo/google_logo.png', width: 18, height: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              K.continueGoogle.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F1F1F),
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: K.continueGoogle.tr(),
      excludeSemantics: true,
      onTap: onTap,
      child: TpTappable(onTap: onTap, press: true, child: face),
    );
  }
}

/// 약관 두 개. 한 줄 문구 안의 글자보다 누르기 쉽게 따로 둔다.
class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.open});

  final ValueChanged<Uri> open;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 12,
      height: 1.4,
      fontWeight: FontWeight.w600,
      color: context.sys.label2,
    );
    Widget link(String label, Uri url) => Semantics(
      link: true,
      child: TpTappable(
        onTap: () => open(url),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          child: Text(label, style: style),
        ),
      ),
    );
    // 글자를 키우면 두 줄로 내려간다.
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        link(K.terms.tr(), TpUrls.terms),
        Text('·', style: style),
        link(K.privacy.tr(), TpUrls.privacy),
      ],
    );
  }
}

/// Apple 버튼. 공식 위젯은 로고와 글자가 높이에 비례해 Google 버튼보다
/// 커 보인다. 같은 색·모양으로 직접 그리고, 로고와 글자를 Google 과 맞춘다.
/// 기다리는 동안은 로고 자리에 돌림 표시를 띄우고 흐려진다.
class _AppleButton extends StatelessWidget {
  const _AppleButton({
    required this.dark,
    required this.onTap,
    this.busy = false,
  });

  final bool dark;
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? Colors.white : Colors.black;
    final fg = dark ? Colors.black : Colors.white;
    final face = Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Google G 와 같은 18 자리. 사과는 폭이 좁아서 높이를 맞춘다.
          SizedBox.square(
            dimension: 18,
            child: busy
                ? CupertinoActivityIndicator(color: fg)
                : Transform.translate(
                    // 공식 버튼처럼 글자 줄에 맞춰 살짝 위로.
                    offset: const Offset(0, -1),
                    child: Center(
                      child: SizedBox(
                        width: 18 * 25 / 31,
                        height: 18,
                        child: CustomPaint(
                          painter: AppleLogoPainter(color: fg),
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              K.continueApple.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
    // 다른 방법을 기다리는 동안은 눌리지 않는다.
    return SizedBox(
      height: 50,
      child: AnimatedOpacity(
        opacity: busy ? .6 : 1,
        duration: context.motion.selection.duration,
        child: Semantics(
          button: true,
          enabled: onTap != null && !busy,
          label: K.continueApple.tr(),
          excludeSemantics: true,
          onTap: busy ? null : onTap,
          child: IgnorePointer(
            ignoring: onTap == null || busy,
            child: TpTappable(onTap: onTap, press: true, child: face),
          ),
        ),
      ),
    );
  }
}

/// 이메일 로그인·가입. 맨 아래 한 줄로 오간다.
class _EmailStep extends ConsumerStatefulWidget {
  const _EmailStep({
    required this.onBack,
    required this.onSignedIn,
    required this.onForgot,
  });

  final VoidCallback onBack;
  final VoidCallback onSignedIn;
  final ValueChanged<String> onForgot;

  @override
  ConsumerState<_EmailStep> createState() => _EmailStepState();
}

class _EmailStepState extends ConsumerState<_EmailStep> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _signingUp = false;
  bool _busy = false;
  String? _error;

  /// 오류가 가리키는 칸. 고치기 시작하면 그 칸부터 풀린다.
  Set<_Field> _bad = const <_Field>{};

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fail(String message, Set<_Field> bad) {
    TpHaptics.error();
    setState(() {
      _busy = false;
      _error = message;
      _bad = bad;
    });
  }

  void _edited(_Field field) {
    if (!_bad.contains(field)) return;
    setState(() {
      _bad = <_Field>{..._bad}..remove(field);
      if (_bad.isEmpty) _error = null;
    });
  }

  /// 서버 오류가 어느 칸 탓인지. 네트워크처럼 칸과 상관없으면 빈 집합.
  static Set<_Field> _blame(AuthFailure failure) => switch (failure) {
    AuthFailure.badCredentials => const <_Field>{_Field.email, _Field.password},
    AuthFailure.invalidEmail ||
    AuthFailure.emailInUse ||
    AuthFailure.otherProvider ||
    AuthFailure.disabled => const <_Field>{_Field.email},
    AuthFailure.weakPassword => const <_Field>{_Field.password},
    _ => const <_Field>{},
  };

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    // 빈 칸에 "형식이 아닙니다"는 고장 난 것처럼 읽힌다.
    if (email.isEmpty || password.isEmpty) {
      return _fail(K.emailNeeded.tr(), <_Field>{
        if (email.isEmpty) _Field.email,
        if (password.isEmpty) _Field.password,
      });
    }
    if (!LoginScreen.looksLikeEmail(email)) {
      return _fail(K.emailInvalid.tr(), const <_Field>{_Field.email});
    }
    if (password.length < LoginScreen.minPasswordLength) {
      return _fail(K.passwordShort.tr(), const <_Field>{_Field.password});
    }
    setState(() {
      _busy = true;
      _error = null;
      _bad = const <_Field>{};
    });
    final notifier = ref.read(currentUserProvider.notifier);
    final result = _signingUp
        ? await notifier.signUp(email, password)
        : await notifier.signIn(
            AuthMethod.email,
            email: email,
            password: password,
          );
    if (!mounted) return;
    if (result.ok) {
      // 키체인이 방금 쓴 아이디·암호를 저장하겠냐고 묻게 한다.
      TextInput.finishAutofillContext();
      widget.onSignedIn();
      return;
    }
    final failure = result.failure!;
    _fail(authMessage(failure) ?? K.authFailed.tr(), _blame(failure));
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    void toggle() => setState(() {
      _signingUp = !_signingUp;
      _error = null;
      _bad = const <_Field>{};
    });
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    // Android 는 칸의 errorText 로 말한다. 두 칸 다 틀렸으면 문장은 아래 칸에.
    final inField = !context.tp.isGlass && _bad.isNotEmpty;
    final says = _bad.contains(_Field.password)
        ? _Field.password
        : _Field.email;
    String? fieldError(_Field f) => inField && says == f ? _error : null;

    // `iOS-EmailLogin` · `iOS-SignUp` · `iOS-EmailLogin-Error`.
    // 큰 제목, 칸 둘, 그 아래 한 줄(오류는 빨강, 가입은 비밀번호 규칙), 채운
    // 알약, 로그인이면 "비밀번호를 잊으셨나요?". 모드는 맨 아래 한 줄로 바꾼다.
    return Material(
      color: sys.background,
      child: Column(
        children: <Widget>[
          Expanded(
            child: TpPage(
              title: (_signingUp ? K.signupTitle : K.emailTitle).tr(),
              onBack: widget.onBack,
              slivers: <Widget>[
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                SliverToBoxAdapter(
                  // 한 묶음이어야 iCloud 키체인이 아이디와 암호를 같이 채운다.
                  child: AutofillGroup(
                    child: TpGroup(
                      children: <Widget>[
                        LoginField(
                          controller: _email,
                          label: K.emailLabel.tr(),
                          placeholder: K.emailPlaceholder.tr(),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
                          action: TextInputAction.next,
                          invalid: _bad.contains(_Field.email),
                          errorText: fieldError(_Field.email),
                          onChanged: (_) => _edited(_Field.email),
                        ),
                        LoginField(
                          controller: _password,
                          label: K.passwordLabel.tr(),
                          placeholder: (_signingUp ? K.pwHint : K.pwRequired)
                              .tr(),
                          obscure: true,
                          autofillHints: <String>[
                            _signingUp
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          action: TextInputAction.done,
                          onSubmitted: (_) => unawaited(_submit()),
                          invalid: _bad.contains(_Field.password),
                          errorText: fieldError(_Field.password),
                          onChanged: (_) => _edited(_Field.password),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: AnimatedSize(
                    duration: context.motion.reveal.duration,
                    curve: context.motion.reveal.curve,
                    alignment: Alignment.topCenter,
                    child: _error != null && !inField
                        ? _ErrorLine(_error!)
                        : _signingUp
                        ? _Footnote(K.pwRule.tr())
                        : const SizedBox(width: double.infinity),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TpPill(
                          label: (_signingUp ? K.signup : K.signIn).tr(),
                          busy: _busy,
                          onTap: () => unawaited(_submit()),
                        ),
                        if (!_signingUp) ...<Widget>[
                          const SizedBox(height: 8),
                          TpPill(
                            label: K.forgotPw.tr(),
                            kind: TpPillKind.plain,
                            height: 44,
                            onTap: () => widget.onForgot(_email.text.trim()),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, math.max(safe, 16) + 10),
            child: Semantics(
              button: true,
              onTap: toggle,
              child: TpTappable(
                onTap: toggle,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Center(
                    child: Text.rich(
                      TextSpan(
                        text:
                            '${(_signingUp ? K.haveAccount : K.noAccount).tr()} ',
                        style: TextStyle(fontSize: 15, color: sys.label2),
                        children: <InlineSpan>[
                          TextSpan(
                            text: (_signingUp ? K.signIn : K.signup).tr(),
                            style: TextStyle(color: sys.accentText),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 칸 아래 회색 한 줄(가입의 비밀번호 규칙).
class _Footnote extends StatelessWidget {
  const _Footnote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 7, 32, 0),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        height: 18 / 13,
        color: context.sys.label2,
      ),
    ),
  );
}

/// 비밀번호 재설정 메일.
class _ResetStep extends ConsumerStatefulWidget {
  const _ResetStep({required this.email, required this.onBack});

  final String email;
  final VoidCallback onBack;

  @override
  ConsumerState<_ResetStep> createState() => _ResetStepState();
}

class _ResetStepState extends ConsumerState<_ResetStep> {
  late final TextEditingController _email = TextEditingController(
    text: widget.email,
  );
  bool _busy = false;
  bool _sent = false;
  String? _error;

  /// 이메일 칸 탓인 오류인지.
  bool _bad = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!LoginScreen.looksLikeEmail(email)) {
      TpHaptics.error();
      setState(() {
        _error = K.emailInvalid.tr();
        _bad = true;
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _bad = false;
    });
    final failure = await ref
        .read(currentUserProvider.notifier)
        .sendPasswordReset(email);
    if (!mounted) return;
    if (failure == null) {
      TpHaptics.commit();
      setState(() {
        _busy = false;
        _sent = true;
      });
      return;
    }
    TpHaptics.error();
    setState(() {
      _busy = false;
      _error = authMessage(failure) ?? K.authFailed.tr();
      _bad = _EmailStepState._blame(failure).contains(_Field.email);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final inField = !context.tp.isGlass && _bad;
    return TpPage(
      title: K.resetTitle.tr(),
      largeTitle: false,
      onBack: widget.onBack,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: TpGroup(
            header: K.resetBody.tr(),
            children: <Widget>[
              LoginField(
                controller: _email,
                label: K.emailLabel.tr(),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const <String>[AutofillHints.email],
                action: TextInputAction.send,
                onSubmitted: (_) => unawaited(_send()),
                invalid: _bad,
                errorText: inField ? _error : null,
                onChanged: (_) {
                  if (_bad) {
                    setState(() {
                      _bad = false;
                      _error = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        if (_error != null && !inField)
          SliverToBoxAdapter(child: _ErrorLine(_error!)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: _sent
                ? Semantics(
                    liveRegion: true,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        TpPulse(
                          trigger: _sent,
                          child: Icon(
                            context.tp.isGlass
                                ? CupertinoIcons.checkmark_circle_fill
                                : Icons.check_circle,
                            color: TpSys.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            K.resetSent.tr(),
                            style: TextStyle(fontSize: 15, color: sys.label),
                          ),
                        ),
                      ],
                    ),
                  )
                : TpPill(
                    label: K.resetSend.tr(),
                    busy: _busy,
                    onTap: () => unawaited(_send()),
                  ),
          ),
        ),
        // 보낸 뒤엔 할 일이 로그인뿐이다. 뒤로만 두면 찾아야 한다.
        if (_sent)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: TpPill(
                label: K.resetBackToSignIn.tr(),
                kind: TpPillKind.tinted,
                height: context.tp.isGlass ? 50 : 48,
                onTap: widget.onBack,
              ),
            ),
          ),
      ],
    );
  }
}

/// 칸 아래 빨간 오류 한 줄. 스크린 리더가 바로 읽는다.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 7, 32, 0),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          height: 18 / 13,
          color: context.sys.destructive,
        ),
      ),
    ),
  );
}

/// 성공 장면. 액센트 원이 튀어 오르며 체크가 그려지고, 고리 두 겹이 퍼지고,
/// 색 조각이 사방으로 터졌다 떨어진다. 그 아래 "로그인했습니다"와 계정 이름.
///
/// 동작 줄이기면 끝 장면만 보인다.
class _Done extends ConsumerStatefulWidget {
  const _Done();

  @override
  ConsumerState<_Done> createState() => _DoneState();
}

class _DoneState extends ConsumerState<_Done>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.value > 0) return;
    if (context.motion.isReduced) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _span(
    double t,
    double a,
    double b, [
    Curve c = Curves.easeOutCubic,
  ]) {
    if (t <= a) return 0;
    if (t >= b) return 1;
    return c.transform((t - a) / (b - a));
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final user = ref.watch(currentUserProvider);
    final who = user?.name ?? user?.email;
    return ColoredBox(
      color: sys.background,
      child: Semantics(
        liveRegion: true,
        label: <String>[K.signedIn.tr(), ?who].join(', '),
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              final pop = _span(t, 0, .35, Curves.easeOutBack);
              final text = _span(t, .35, .6);
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox.square(
                      dimension: 260,
                      child: CustomPaint(
                        painter: _Burst(t: t, accent: TpSys.accent),
                        child: Center(
                          child: Transform.scale(
                            scale: pop,
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                color: TpSys.accent,
                                shape: BoxShape.circle,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: TpSys.accent.withValues(alpha: .35),
                                    blurRadius: 30 * pop,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CustomPaint(
                                painter: _Check(_span(t, .18, .5)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: text,
                      child: Transform.translate(
                        offset: Offset(0, (1 - text) * 12),
                        child: Column(
                          children: <Widget>[
                            Text(
                              K.signedIn.tr(),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: sys.label,
                              ),
                            ),
                            if (who != null) ...<Widget>[
                              const SizedBox(height: 6),
                              Text(
                                who,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: sys.label2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 원 안의 흰 체크. [k] 만큼 그어진다.
class _Check extends CustomPainter {
  const _Check(this.k);

  final double k;

  @override
  void paint(Canvas canvas, Size size) {
    if (k <= 0) return;
    final w = size.width;
    final path = Path()
      ..moveTo(w * .29, w * .52)
      ..lineTo(w * .44, w * .66)
      ..lineTo(w * .72, w * .37);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * k),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .085
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_Check old) => old.k != k;
}

/// 퍼지는 고리 두 겹 + 사방으로 터졌다 떨어지는 색 조각.
class _Burst extends CustomPainter {
  const _Burst({required this.t, required this.accent});

  final double t;
  final Color accent;

  static const List<Color> _colors = <Color>[
    Color(0xFF0C78D8),
    Color(0xFF34C759),
    Color(0xFFFF9500),
    Color(0xFFFF2D55),
    Color(0xFFAF52DE),
    Color(0xFF5AC8FA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    // 고리: 원이 튀는 순간부터 바깥으로 퍼지며 옅어진다.
    for (var i = 0; i < 2; i++) {
      final k = ((t - .12 - .12 * i) / .55).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final r = 52 + 78 * Curves.easeOutCubic.transform(k);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * (1 - k) + .5
          ..color = accent.withValues(alpha: .45 * (1 - k)),
      );
    }
    // 조각: 정해진 각도로 튀어 나가고 중력으로 조금 떨어진다.
    final k = ((t - .15) / .85).clamp(0.0, 1.0);
    if (k <= 0) return;
    const n = 28;
    for (var i = 0; i < n; i++) {
      final angle = i / n * 2 * math.pi + (i.isEven ? .12 : -.08);
      final speed = 90 + (i * 37 % 50);
      final out = Curves.easeOutCubic.transform(k) * speed;
      final drop = 60 * k * k;
      final p =
          c +
          Offset(
            math.cos(angle) * (58 + out),
            math.sin(angle) * (58 + out) + drop,
          );
      final fade = (1 - ((k - .55) / .45).clamp(0.0, 1.0));
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(angle + k * 6);
      if (i % 3 == 0) {
        canvas.drawCircle(Offset.zero, 3.2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 9, height: 4.5),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_Burst old) => old.t != t;
}

/// 한 줄 입력. iOS 는 inset grouped 칸 안에 왼쪽 레이블 + 테두리 없는 필드,
/// Android 는 채운 필드.
class LoginField extends StatelessWidget {
  const LoginField({
    super.key,
    required this.controller,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.autofillHints,
    this.action,
    this.onSubmitted,
    this.placeholder,
    this.onChanged,
    this.invalid = false,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;

  /// 빈 칸 안의 흐린 안내("name@example.com", "필수").
  final String? placeholder;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  /// 오류가 이 칸을 가리킨다. iOS 는 이름이 빨개진다.
  final bool invalid;

  /// Android 칸 아래 오류 문장. [invalid] 인데 null 이면 빨간 밑줄만.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    if (context.tp.isGlass) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 112,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      color: invalid ? sys.destructive : sys.label,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: MergeSemantics(
                child: Semantics(
                  label: label,
                  child: CupertinoTextField(
                    controller: controller,
                    obscureText: obscure,
                    keyboardType: keyboardType,
                    autofillHints: autofillHints,
                    textInputAction: action,
                    autocorrect: false,
                    enableSuggestions: !obscure && keyboardType == null,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    onSubmitted: onSubmitted,
                    onChanged: onChanged,
                    placeholder: placeholder,
                    placeholderStyle: TextStyle(
                      fontSize: 17,
                      color: sys.label3,
                    ),
                    decoration: null,
                    padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
                    style: TextStyle(fontSize: 17, color: sys.label),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // Android 묶음이 이미 좌우 16을 준다. 알약과 한 선에 선다.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: action,
        autocorrect: false,
        enableSuggestions: !obscure && keyboardType == null,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          filled: true,
          errorText: invalid ? (errorText ?? '') : null,
        ),
      ),
    );
  }
}

/// 이메일 단계의 칸.
enum _Field { email, password }

/// 안쪽 Navigator 의 깊이.
class _Depth extends NavigatorObserver {
  _Depth(this.onChange);

  final VoidCallback onChange;
  int value = 0;

  void _changed() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => onChange());

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    value++;
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    value--;
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    value--;
    _changed();
  }
}
