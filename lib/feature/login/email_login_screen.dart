import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../data/service/auth_service.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_tap_target.dart';

/// 이메일 로그인·가입.
///
/// 명세에 이 화면은 없다. 로그인 화면의 "Continue with email" 이 갈 곳이
/// 필요해서 만들었고, 다른 화면과 같은 토큰·간격을 쓴다. v1 의
/// EmailLogin/RegisterPage 두 화면을 하나로 합친 셈이다.
class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key, this.onBack, this.onSignedIn});

  final VoidCallback? onBack;
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

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
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

  Future<void> _submit() async {
    if (_busy) return;

    final email = _email.text.trim();
    final password = _password.text;

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
    final ok = _signingUp
        ? await notifier.signUp(email, password)
        : await notifier.signIn(
            AuthMethod.email,
            email: email,
            password: password,
          );

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
                child: const Icon(Icons.chevron_left, size: 26),
              ),
            ),
          Text(
            (_signingUp ? K.signupTitle : K.emailTitle).tr(),
            style: type.largeTitle,
          ),
          const SizedBox(height: 24),

          _Field(
            controller: _email,
            label: K.emailLabel.tr(),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _password,
            label: K.passwordLabel.tr(),
            obscure: true,
            onSubmitted: (_) => _submit(),
          ),

          if (_error != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(_error!, style: type.caption.copyWith(color: t.dim)),
          ],

          const SizedBox(height: 20),
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: _submit,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TpTokens.blue,
                  borderRadius: BorderRadius.circular(
                    t.isGlass ? TpTokens.rControl : t.rCard,
                  ),
                  boxShadow: t.buttonShadow,
                ),
                child: Text(
                  (_signingUp ? K.signup : K.signIn).tr(),
                  style: type.body.copyWith(
                    color: Colors.white,
                    fontWeight: t.boldWeight,
                  ),
                ),
              ),
            ),
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
                  style: type.body.copyWith(color: TpTokens.blueText),
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
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(
          t.isGlass ? TpTokens.rControl : t.rCard,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: type.body,
        decoration: InputDecoration(
          // isDense 를 켜면 필드의 히트 영역이 글자 높이로 줄어 접근성
          // 기준(48)에 못 미친다. 세로 여백으로 채운다.
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          border: InputBorder.none,
          hintText: label,
          hintStyle: type.body.copyWith(color: t.dim),
        ),
      ),
    );
  }
}
