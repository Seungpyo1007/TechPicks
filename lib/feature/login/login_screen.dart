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
    this.onBrowse,
  });

  final VoidCallback? onSignedIn;

  /// 푸터의 `Sign up` 링크. 이메일 가입 화면을 연다.
  final VoidCallback? onSignUp;

  /// 이메일 버튼. 입력 화면이 따로 필요해 바깥에서 띄운다.
  final VoidCallback? onEmail;

  /// `Browse without an account`. 계정 없이 그냥 들어간다.
  final VoidCallback? onBrowse;

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
    final outcome = await ref.read(currentUserProvider.notifier).signIn(method);
    if (!mounted) return;
    if (outcome == SignInOutcome.ok) {
      widget.onSignedIn?.call();
      return;
    }
    // 스스로 닫은 사람에게 실패를 보여주지 않는다.
    if (outcome == SignInOutcome.canceled) {
      setState(() => _error = null);
      return;
    }
    // 계정 없이 둘러보기는 익명 로그인이 실패해도 들어가야 한다. 명세가
    // "계정 없이도 비교가 된다"는 쪽이고, Firebase 가 없는 빌드에서 이게
    // 막히면 앱에 들어갈 방법이 하나도 없다.
    if (method == AuthMethod.anonymous && widget.onBrowse != null) {
      widget.onBrowse!();
      return;
    }
    setState(() => _error = _messageFor(method));
  }

  static String _messageFor(AuthMethod method) => switch (method) {
    AuthMethod.google => K.notConnected.tr(args: const <String>['Google']),
    AuthMethod.apple => K.notConnected.tr(args: const <String>['Apple']),
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
          Text(K.welcomeSub.tr(), style: type.body.copyWith(height: 1.5)),
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
          // 글자 크기를 키우면 한 줄에 안 들어간다. Row 면 넘치고, Wrap 이면
          // 링크가 아래로 내려간다.
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 4,
            children: <Widget>[
              Text(K.noAccount.tr(), style: type.secondary),
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
  static const double _markWidth = 20;
  static const double _markGap = 14;

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
    final radius = BorderRadius.circular(
      t.isGlass ? TpTokens.rControl : t.rCard,
    );

    return Semantics(
      button: true,
      // decoration: 으로 칠한 상자는 히트 테스트에 안 잡힌다. 이게 없으면
      // 버튼이 글자 글리프 위에서만 눌린다.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
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
            mainAxisAlignment: plain
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: <Widget>[
              if (asset != null) ...<Widget>[
                Image.asset(asset!, width: 20, height: 20),
                const SizedBox(width: 14),
              ]
              // 마크가 없는 버튼도 라벨은 같은 선에서 시작한다. 이메일 줄만
              // 왼쪽으로 튀어나와 넉 장의 왼쪽 끝이 들쭉날쭉했다.
              else if (!plain)
                const SizedBox(width: _markWidth + _markGap),
              // 라벨이 남은 폭을 넘으면 Row 가 넘친다. 명세가 버튼 높이를 52 로
              // 고정해서 두 줄로 늘릴 수 없다.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: plain ? TextAlign.center : TextAlign.start,
                  style: type.body.copyWith(
                    fontWeight: t.boldWeight,
                    color: filled
                        ? Colors.white
                        : (plain ? TpTokens.blueText : TpTokens.ink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
