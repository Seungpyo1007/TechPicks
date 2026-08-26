import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_typography.dart';
import '../copy_keys.dart';
import 'tp_button.dart';

/// 못 읽었다고 말하고, 다시 시도할 자리를 준다.
///
/// 실패를 빈 상태로 그리면 "아직 기기가 없습니다"가 뜬다. 데이터가 없는 것과
/// 못 읽은 것은 다른 일이고, 사용자가 할 수 있는 것도 다르다.
class TpErrorState extends StatelessWidget {
  const TpErrorState({
    required this.title,
    required this.body,
    this.onRetry,
    super.key,
  });

  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: type.cardTitle, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(body, style: type.caption, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              TpButton(
                label: K.retry.tr(),
                height: 46,
                expand: false,
                onTap: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 카탈로그를 못 읽었을 때. 다섯 화면이 같은 걸 쓴다.
///
/// 다시 시도는 카탈로그 프로바이더를 버린다 — 애셋을 다시 읽고, 받아둔 파일과
/// 원격 버전도 다시 본다.
class TpCatalogError extends ConsumerWidget {
  const TpCatalogError({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => TpErrorState(
    title: K.catalogFailedTitle.tr(),
    body: K.catalogFailedBody.tr(),
    onRetry: () => ref.invalidate(catalogProvider),
  );
}
