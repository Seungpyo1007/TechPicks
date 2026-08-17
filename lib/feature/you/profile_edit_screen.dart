import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../core/error_reporter.dart';
import '../../domain/model/tp_profile.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_button.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';

/// 프로필 편집.
///
/// v1 에 있던 화면이다 — 사진, 사용자 이름, 대명사, 전화번호, 성별. 리메이크
/// 뒤에는 표시 이름 하나짜리 알림창이 그 자리에 있었다.
///
/// **대명사는 고르는 게 아니라 받아 적는다.** 목록으로 두면 거기 없는 사람이
/// 생긴다.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, this.onBack, this.picker});

  final VoidCallback? onBack;

  /// 갤러리를 여는 것. 테스트가 갈아끼운다.
  final ImagePicker? picker;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _pronouns = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _gender = TextEditingController();

  /// 저장·업로드 결과 한 줄. null 이면 안 그린다.
  String? _notice;
  bool _busy = false;
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _pronouns.dispose();
    _phone.dispose();
    _gender.dispose();
    super.dispose();
  }

  /// 읽어온 값을 칸에 한 번만 넣는다. 매번 넣으면 타이핑이 덮인다.
  void _fill(TpProfile profile) {
    if (_filled) return;
    _filled = true;
    _name.text = ref.read(currentUserProvider)?.name ?? '';
    _username.text = profile.username ?? '';
    _pronouns.text = profile.pronouns ?? '';
    _phone.text = profile.phone ?? '';
    _gender.text = profile.gender ?? '';
  }

  String? _trimmed(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _save(TpProfile current) async {
    setState(() {
      _busy = true;
      _notice = null;
    });

    // 표시 이름은 계정 쪽에 있고 나머지는 프로필 문서에 있다. 한 번에 누르면
    // 둘 다 간다.
    final name = _trimmed(_name);
    var renamed = true;
    if (name != null && name != ref.read(currentUserProvider)?.name) {
      renamed = await ref.read(currentUserProvider.notifier).updateName(name);
    }

    final saved = await ref
        .read(profileProvider.notifier)
        .save(
          current.copyWith(
            username: _trimmed(_username),
            pronouns: _trimmed(_pronouns),
            phone: _trimmed(_phone),
            gender: _trimmed(_gender),
          ),
        );

    if (!mounted) return;
    setState(() {
      _busy = false;
      // 이름은 계정에, 나머지는 프로필 문서에 간다. 한쪽만 실패해도 저장
      // 됐다고 말하면 안 된다.
      _notice = (renamed && saved ? K.profileSaved : K.profileFailed).tr();
    });
  }

  Future<void> _pickPhoto() async {
    setState(() => _notice = null);
    try {
      final picked = await (widget.picker ?? ImagePicker()).pickImage(
        source: ImageSource.gallery,
        // 아바타는 64pt 원이다. 원본 그대로 올리면 몇 MB 를 쓰고 버린다.
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _busy = true);
      final url = await ref
          .read(profileProvider.notifier)
          .uploadPhoto(picked.path);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _notice = url == null ? K.photoFailed.tr() : null;
      });
    } catch (e, s) {
      // 권한을 거절했거나 갤러리를 못 열었다.
      TpErrors.record(e, s, reason: 'profile.pick');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final profile = ref.watch(profileProvider).value ?? const TpProfile();
    _fill(profile);

    return TpShell(
      mode: TpChromeMode.plain,
      child: Builder(
        builder: (context) => ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 24) +
              tpContentInset(context),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(K.editProfile.tr(), style: type.largeTitle),
                ),
                TpTapTarget(
                  onTap: widget.onBack,
                  label: K.back.tr(),
                  child: Text(
                    K.cancel.tr(),
                    style: type.body.copyWith(color: context.tp.link),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _PhotoRow(url: profile.photoUrl, onTap: _busy ? null : _pickPhoto),
            const SizedBox(height: 18),

            TpSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: <Widget>[
                  _Field(label: K.nameLabel.tr(), controller: _name),
                  _Field(label: K.usernameLabel.tr(), controller: _username),
                  _Field(label: K.pronounsLabel.tr(), controller: _pronouns),
                  _Field(
                    label: K.phoneLabel.tr(),
                    controller: _phone,
                    keyboard: TextInputType.phone,
                  ),
                  _Field(
                    label: K.genderLabel.tr(),
                    controller: _gender,
                    last: true,
                  ),
                ],
              ),
            ),

            if (_notice != null) ...<Widget>[
              const SizedBox(height: 10),
              Text(_notice!, style: type.caption),
            ],
            const SizedBox(height: 18),

            TpButton(
              label: K.save.tr(),
              onTap: _busy ? null : () => _save(profile),
            ),
          ],
        ),
      ),
    );
  }
}

/// 아바타와 "사진 바꾸기".
class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.url, required this.onTap});

  final String? url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;

    return Row(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: TpTokens.blue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: url == null
              ? const Icon(Icons.person, size: 34, color: Colors.white)
              // 사진을 못 읽어도 화면은 남아야 한다.
              : Image.network(
                  url!,
                  fit: BoxFit.cover,
                  width: 72,
                  height: 72,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.person, size: 34, color: Colors.white),
                ),
        ),
        const SizedBox(width: 14),
        TpTapTarget(
          onTap: onTap,
          child: Text(
            K.changePhoto.tr(),
            style: type.body.copyWith(color: context.tp.link),
          ),
        ),
      ],
    );
  }
}

/// 라벨 한 줄 + 입력 한 줄.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    this.keyboard,
    this.last = false,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboard;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Container(
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: t.hairline, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 108,
            child: Text(label, style: type.secondary),
          ),
          Expanded(
            child: Semantics(
              label: label,
              child: TextField(
                controller: controller,
                keyboardType: keyboard,
                textAlign: TextAlign.end,
                style: type.body,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  // isDense 를 켜면 히트 영역이 접근성 기준에 못 미친다.
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
