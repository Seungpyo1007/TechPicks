import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../data/service/auth_service.dart';

/// 로그인.
///
/// v1 은 Rive 로봇 배경에 검정-파랑 그라디언트를 깔았다. 확정 디자인은
/// 다른 화면과 같은 바탕에 버튼 다섯 개만 세로로 쌓는다.
///
/// 카피는 아직 하드코딩이다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({
    super.key,
    this.onSignedIn,
    this.onSignUp,
    this.onEmail,
  });

  final VoidCallback? onSignedIn;
  final VoidCallback? onSignUp;

  /// 이메일 버튼. 입력 화면이 따로 필요해 바깥에서 띄운다.
  final VoidCallback? onEmail;

  /// 명세의 버튼 순서와 라벨.
  static const List<({AuthMethod method, String key, String? asset})> buttons =
      [
    (
      method: AuthMethod.google,
      key: K.loginGoogle,
      asset: 'assets/logo/google_logo.png',
    ),
    (
      method: AuthMethod.apple,
      key: K.loginApple,
      asset: 'assets/logo/apple_logo.png',
    ),
    (
      method: AuthMethod.facebook,
      key: K.loginFacebook,
      asset: 'assets/logo/facebook_logo.png',
    ),
    (method: AuthMethod.email, key: K.loginEmail, asset: null),
    (method: AuthMethod.anonymous, key: K.loginAnon, asset: null),
  ];

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _error;

  Future<void> _tap(AuthMethod method) async {
    if (method == AuthMethod.email && widget.onEmail != null) {
      widget.onEmail!();
      return;
    }
    final ok = await ref.read(currentUserProvider.notifier).signIn(method);
    if (!mounted) return;
    if (ok) {
      widget.onSignedIn?.call();
      return;
    }
    setState(() => _error = _messageFor(method));
  }

  static String _messageFor(AuthMethod method) => switch (method) {
        AuthMethod.google =>
          K.notConnected.tr(args: const <String>['Google']),
        AuthMethod.apple => K.notConnected.tr(args: const <String>['Apple']),
        AuthMethod.facebook =>
          K.notConnected.tr(args: const <String>['Facebook']),
        AuthMethod.email => K.emailNeeded.tr(),
        AuthMethod.anonymous => K.anonFailed.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return TpShell(
      mode: TpChromeMode.plain,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: <Widget>[
          Text(K.welcome.tr(), style: type.largeTitle),
          const SizedBox(height: 10),
          Text(
            K.welcomeSub.tr(),
            style: type.body.copyWith(height: 1.5),
          ),
          const SizedBox(height: 28),

          for (final b in LoginScreen.buttons) ...<Widget>[
            _AuthButton(
              label: b.key.tr(),
              asset: b.asset,
              // 이메일만 파란 채움. 익명은 텍스트 버튼.
              filled: b.method == AuthMethod.email,
              plain: b.method == AuthMethod.anonymous,
              onTap: () => _tap(b.method),
            ),
            const SizedBox(height: 12),
          ],

          if (_error != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(_error!, style: type.caption.copyWith(color: t.dim)),
          ],

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(K.noAccount.tr(), style: type.secondary),
              const SizedBox(width: 6),
              TpTapTarget(
                onTap: widget.onSignUp,
                child: Text(
                  K.signup.tr(),
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

/// 52px 높이, 라벨 왼쪽 정렬, 제공자 마크가 왼쪽에.
class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.label,
    required this.filled,
    required this.plain,
    this.asset,
    this.onTap,
  });

  final String label;
  final String? asset;
  final bool filled;
  final bool plain;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final radius =
        BorderRadius.circular(t.isGlass ? TpTokens.rControl : t.rCard);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: plain
              ? Colors.transparent
              : (filled ? TpTokens.blue : t.chipBg),
          borderRadius: radius,
          boxShadow: filled ? t.buttonShadow : null,
        ),
        child: Row(
          mainAxisAlignment:
              plain ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: <Widget>[
            if (asset != null) ...<Widget>[
              Image.asset(asset!, width: 20, height: 20),
              const SizedBox(width: 14),
            ],
            Text(
              label,
              style: type.body.copyWith(
                fontWeight: t.boldWeight,
                color: filled
                    ? Colors.white
                    : (plain ? TpTokens.blueText : TpTokens.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
