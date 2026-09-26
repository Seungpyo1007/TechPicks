import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../data/service/auth_service.dart';
import '../../shared/copy_keys.dart';
import '../../shared/tp_haptics.dart';
import '../../shared/figures/tp_figure.dart';
import '../../shared/figures/tp_figures.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_pop_in.dart';
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

/// 로그인 화면(전체 화면 모달). 방법 고르기 → 이메일 → 비밀번호 재설정이 화면
/// 안에서 옆으로 밀린다. 로그인은 선택이라 언제든 X 로 닫는다.
///
/// 성공하면 체크가 한 번 튀고 시트가 닫힌다.
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
  static const Duration doneHold = Duration(milliseconds: 700);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<NavigatorState> _nav = GlobalKey<NavigatorState>();
  bool _done = false;

  Route<void> _route(Widget child) => context.tp.isGlass
      ? CupertinoPageRoute<void>(builder: (_) => child)
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
      // 안쪽 단계에서 뒤로 가면 시트를 닫지 말고 한 단계 돌아간다.
      canPop: false,
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
        SizedBox(
          height: 50,
          child: SignInWithAppleButton(
            text: K.continueApple.tr(),
            height: 50,
            style: dark
                ? SignInWithAppleButtonStyle.white
                : SignInWithAppleButtonStyle.black,
            borderRadius: const BorderRadius.all(Radius.circular(25)),
            onPressed: () => unawaited(_tap(AuthMethod.apple)),
          ),
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
            SizedBox(
              height: 52,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 16),
                  if (widget.onClose != null)
                    TpBarButton(
                      action: TpBarAction(
                        label: K.close.tr(),
                        icon: glass ? CupertinoIcons.xmark : Icons.close,
                        symbol: 'xmark',
                        onTap: widget.onClose,
                      ),
                    ),
                ],
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
                                style: TextStyle(
                                  fontSize: 30,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
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

/// 온보딩 마지막 장과 같은 그림. 거기서 넘어오면 이어져 보인다.
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
            const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
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

/// 이메일 로그인·가입. 위의 세그먼트로 오간다.
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

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _fail(String message) {
    TpHaptics.error();
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final password = _password.text;
    // 빈 칸에 "형식이 아닙니다"는 고장 난 것처럼 읽힌다.
    if (email.isEmpty || password.isEmpty) return _fail(K.emailNeeded.tr());
    if (!LoginScreen.looksLikeEmail(email)) return _fail(K.emailInvalid.tr());
    if (password.length < LoginScreen.minPasswordLength) {
      return _fail(K.passwordShort.tr());
    }
    setState(() {
      _busy = true;
      _error = null;
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
    _fail(authMessage(result.failure!) ?? K.authFailed.tr());
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final labels = <String>[K.signIn.tr(), K.signup.tr()];
    void pick(int i) => setState(() {
      _signingUp = i == 1;
      _error = null;
    });

    return TpPage(
      title: (_signingUp ? K.signupTitle : K.emailTitle).tr(),
      largeTitle: false,
      onBack: widget.onBack,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TpNativeGlass.enabled
                ? SizedBox(
                    width: double.infinity,
                    child: TpNativeSegmented(
                      labels: labels,
                      index: _signingUp ? 1 : 0,
                      onChanged: pick,
                    ),
                  )
                : context.tp.isGlass
                ? SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _signingUp ? 1 : 0,
                      onValueChanged: (i) => pick(i ?? 0),
                      children: <int, Widget>{
                        for (var i = 0; i < labels.length; i++)
                          i: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(labels[i]),
                          ),
                      },
                    ),
                  )
                : SegmentedButton<int>(
                    segments: <ButtonSegment<int>>[
                      for (var i = 0; i < labels.length; i++)
                        ButtonSegment<int>(value: i, label: Text(labels[i])),
                    ],
                    selected: <int>{_signingUp ? 1 : 0},
                    onSelectionChanged: (s) => pick(s.first),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          // 한 묶음이어야 iCloud 키체인이 아이디와 암호를 같이 채워 준다.
          child: AutofillGroup(
            child: TpGroup(
              footer: _signingUp ? K.pwHint.tr() : null,
              children: <Widget>[
                LoginField(
                  controller: _email,
                  label: K.emailLabel.tr(),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  action: TextInputAction.next,
                ),
                LoginField(
                  controller: _password,
                  label: K.passwordLabel.tr(),
                  obscure: true,
                  autofillHints: <String>[
                    _signingUp
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  action: TextInputAction.done,
                  onSubmitted: (_) => unawaited(_submit()),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) SliverToBoxAdapter(child: _ErrorLine(_error!)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TpPill(
              label: (_signingUp ? K.signup : K.signIn).tr(),
              busy: _busy,
              onTap: () => unawaited(_submit()),
            ),
          ),
        ),
        if (!_signingUp)
          SliverToBoxAdapter(
            child: Center(
              child: TextButton(
                onPressed: () => widget.onForgot(_email.text.trim()),
                child: Text(
                  K.forgotPw.tr(),
                  style: TextStyle(fontSize: 15, color: sys.accentText),
                ),
              ),
            ),
          ),
      ],
    );
  }
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

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _email.text.trim();
    if (!LoginScreen.looksLikeEmail(email)) {
      TpHaptics.error();
      setState(() => _error = K.emailInvalid.tr());
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
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
              ),
            ],
          ),
        ),
        if (_error != null) SliverToBoxAdapter(child: _ErrorLine(_error!)),
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
    padding: const EdgeInsets.fromLTRB(32, 0, 32, 12),
    child: Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: TextStyle(fontSize: 13, color: context.sys.destructive),
      ),
    ),
  );
}

/// 성공: 체크 원이 튀고 "로그인했습니다".
class _Done extends StatelessWidget {
  const _Done();

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return ColoredBox(
      color: sys.background,
      child: Semantics(
        liveRegion: true,
        label: K.signedIn.tr(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TpPopIn(
              from: 0.4,
              child: Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: TpSys.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 54),
              ),
            ),
            const SizedBox(height: 16),
            ExcludeSemantics(
              child: Text(
                K.signedIn.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: sys.label,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;

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
                    style: TextStyle(fontSize: 17, color: sys.label),
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
                    decoration: null,
                    padding: const EdgeInsets.fromLTRB(4, 14, 16, 14),
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
        decoration: InputDecoration(labelText: label, filled: true),
      ),
    );
  }
}
