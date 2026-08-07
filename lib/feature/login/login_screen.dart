import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../data/service/auth_service.dart';

/// 로그인.
///
/// v1 은 Rive 로봇 배경에 검정-파랑 그라디언트를 깔았다. 확정 디자인은
/// 다른 화면과 같은 바탕에 버튼 다섯 개만 세로로 쌓는다.
///
/// 카피는 아직 하드코딩이다.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.onSignedIn, this.onSignUp});

  final VoidCallback? onSignedIn;
  final VoidCallback? onSignUp;

  /// 명세의 버튼 순서와 라벨.
  static const List<({AuthMethod method, String label, String? asset})> buttons =
      [
    (
      method: AuthMethod.google,
      label: 'Continue with Google',
      asset: 'assets/logo/google_logo.png',
    ),
    (
      method: AuthMethod.apple,
      label: 'Continue with Apple',
      asset: 'assets/logo/apple_logo.png',
    ),
    (
      method: AuthMethod.facebook,
      label: 'Continue with Facebook',
      asset: 'assets/logo/facebook_logo.png',
    ),
    (method: AuthMethod.email, label: 'Continue with email', asset: null),
    (method: AuthMethod.anonymous, label: 'Browse without an account', asset: null),
  ];

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _error;

  Future<void> _tap(AuthMethod method) async {
    // 이메일은 별도 입력 화면이 필요하다. 지금은 익명과 같은 자리에서
    // 처리하지 않고 안내만 띄운다.
    final ok = await ref.read(currentUserProvider.notifier).signIn(method);
    if (!mounted) return;
    if (ok) {
      widget.onSignedIn?.call();
      return;
    }
    setState(() => _error = _messageFor(method));
  }

  static String _messageFor(AuthMethod method) => switch (method) {
        AuthMethod.google => 'Google sign-in is not connected yet.',
        AuthMethod.apple => 'Apple sign-in is not connected yet.',
        AuthMethod.facebook => 'Facebook sign-in is not connected yet.',
        AuthMethod.email => 'Enter an email and password to continue.',
        AuthMethod.anonymous => 'Could not start a session. Try again.',
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
          Text('Welcome to\nTechPicks', style: type.largeTitle),
          const SizedBox(height: 10),
          Text(
            'Score every device the way you weigh it.',
            style: type.body.copyWith(height: 1.5),
          ),
          const SizedBox(height: 28),

          for (final b in LoginScreen.buttons) ...<Widget>[
            _AuthButton(
              label: b.label,
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
              Text('No account yet?', style: type.secondary),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onSignUp,
                child: Text(
                  'Sign up',
                  style: type.body.copyWith(color: TpTokens.blue),
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
                    : (plain ? TpTokens.blue : TpTokens.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
