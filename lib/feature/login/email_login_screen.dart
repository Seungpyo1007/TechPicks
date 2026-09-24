import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_group.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../data/service/auth_service.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../app/theme/tp_icons.dart';

/// 이메일 로그인·가입.
///
/// 명세에 이 화면은 없다. 로그인 화면의 "Continue with email" 이 갈 곳이
/// 필요해서 만들었고, 다른 화면과 같은 토큰·간격을 쓴다. v1 의
/// EmailLogin/RegisterPage 두 화면을 하나로 합친 셈이다.
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({
    super.key,
    this.onBack,
    this.onSignedIn,
    this.startInSignUp = false,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSignedIn;

  /// 로그인의 `Sign up` 링크로 들어온 경우 가입 쪽부터 보여준다.
  final bool startInSignUp;

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

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();

  late bool _signingUp = widget.startInSignUp;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;

    final email = _email.text.trim();
    final password = _password.text;

    // 빈 칸에 "형식이 아닙니다"는 고장 난 것처럼 읽힌다. 안 채운 것과
    // 잘못 채운 것을 나눠 말한다.
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = K.emailNeeded.tr());
      return;
    }
    if (!EmailLoginScreen.looksLikeEmail(email)) {
      setState(() => _error = K.emailInvalid.tr());
      return;
    }
    if (password.length < EmailLoginScreen.minPasswordLength) {
      setState(() => _error = K.passwordShort.tr());
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final notifier = ref.read(currentUserProvider.notifier);
    // 이메일은 우리 화면에서 받으므로 취소가 없다. 성공 여부만 본다.
    final ok = _signingUp
        ? await notifier.signUp(email, password)
        : await notifier.signIn(
                AuthMethod.email,
                email: email,
                password: password,
              ) ==
              SignInOutcome.ok;

    if (!mounted) return;
    if (ok) {
      widget.onSignedIn?.call();
      return;
    }
    setState(() {
      _busy = false;
      _error = (_signingUp ? K.signupFailed : K.authFailed).tr();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return TpShell(
      mode: TpChromeMode.plain,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: <Widget>[
          if (widget.onBack != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TpTapTarget(
                onTap: widget.onBack,
                label: K.back.tr(),
                child: Icon(context.icons.back, size: 26),
              ),
            ),
          Text(
            (_signingUp ? K.signupTitle : K.emailTitle).tr(),
            style: type.largeTitle,
          ),
          const SizedBox(height: 24),

          // 한 묶음이어야 iCloud 키체인이 아이디와 암호를 같이 채워 준다.
          AutofillGroup(
            child: _Fields(
              children: <Widget>[
                _Field(
                  controller: _email,
                  label: K.emailLabel.tr(),
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const <String>[
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  action: TextInputAction.next,
                ),
                _Field(
                  controller: _password,
                  label: K.passwordLabel.tr(),
                  obscure: true,
                  // 가입이면 강력한 암호를 제안하고, 로그인이면 저장된 걸 채운다.
                  autofillHints: <String>[
                    _signingUp
                        ? AutofillHints.newPassword
                        : AutofillHints.password,
                  ],
                  action: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),

          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: type.caption.copyWith(color: context.sys.destructive),
              ),
            ),
          ],

          const SizedBox(height: 20),
          TpPill(
            label: (_signingUp ? K.signup : K.signIn).tr(),
            onTap: _submit,
          ),
          const SizedBox(height: 16),
          // 로그인 화면과 같은 이유로 Wrap.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: <Widget>[
              Text(
                (_signingUp ? K.haveAccount : K.noAccount).tr(),
                style: type.secondary,
              ),
              TpTapTarget(
                onTap: () => setState(() {
                  _signingUp = !_signingUp;
                  _error = null;
                }),
                child: Text(
                  (_signingUp ? K.signIn : K.signup).tr(),
                  style: type.body.copyWith(color: t.link),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
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
    final t = context.tp;
    final type = context.tpText;

    if (t.isGlass) {
      // iOS: inset grouped 칸 안에 왼쪽 레이블 + 테두리 없는 필드.
      final sys = context.sys;
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 50),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 96,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ExcludeSemantics(
                  child: Text(
                    label,
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.inputBg,
          borderRadius: BorderRadius.circular(t.rCard),
        ),
        child: Semantics(
          label: label,
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
            style: type.body,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: InputBorder.none,
              hint: ExcludeSemantics(
                child: Text(label, style: type.body.copyWith(color: t.dim)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// iOS 는 한 묶음(inset grouped), Android 는 그냥 세로로.
class _Fields extends StatelessWidget {
  const _Fields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (!context.tp.isGlass) return Column(children: children);
    final sys = context.sys;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: sys.cell,
        borderRadius: BorderRadius.circular(TpGroup.radius),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Container(height: 0.5, color: sys.separator),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}
