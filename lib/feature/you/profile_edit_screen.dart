import 'dart:async' show Timer, unawaited;
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../core/error_reporter.dart';
import '../../domain/model/tp_profile.dart';
import '../../shared/copy_keys.dart';
import '../../shared/tp_haptics.dart';
import '../../shared/widgets/tp_alert.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_menu.dart';
import '../../shared/widgets/tp_pop_in.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../shared/widgets/tp_page.dart';
import 'photo_crop_screen.dart';
import 'you_screen.dart' show YouScreen;

/// 자르기 화면을 띄우는 것. 테스트가 갈아끼운다.
typedef PhotoCropper =
    Future<Uint8List?> Function(BuildContext context, Uint8List bytes);

/// 프로필 편집.
///
/// v1 에 있던 화면이다 — 사진, 사용자 이름, 대명사, 전화번호, 성별. 리메이크
/// 뒤에는 표시 이름 하나짜리 알림창이 그 자리에 있었다.
///
/// **대명사는 고르는 게 아니라 받아 적는다.** 목록으로 두면 거기 없는 사람이
/// 생긴다.
///
/// 사진은 고르는 순간 바로 저장한다. 위의 저장은 이름과 칸만이다 — 취소해도
/// 사진은 그대로다.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, this.onBack, this.picker, this.crop});

  final VoidCallback? onBack;

  /// 카메라·갤러리를 여는 것. 테스트가 갈아끼운다.
  final ImagePicker? picker;

  /// null 이면 [PhotoCropScreen] 을 띄운다.
  final PhotoCropper? crop;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

/// 사진 한 장의 진행.
enum _Photo { idle, uploading, failed }

/// 메뉴·시트에서 고른 것.
enum _PhotoAction { take, choose, remove }

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _pronouns = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _gender = TextEditingController();

  /// 저장 결과 한 줄. null 이면 안 그린다.
  String? _notice;
  bool _busy = false;
  bool _filled = false;

  _Photo _photo = _Photo.idle;

  /// 0–1. 모르면 null 이고 원이 돈다.
  double? _progress;

  /// 올리는 중인 사진. 실패하면 다시 시도가 이걸 올린다.
  Uint8List? _pending;

  /// 끝날 때마다 올라간다. 아바타가 새 키로 다시 튄다.
  int _pops = 0;

  /// 실패할 때마다 올라간다. 아바타가 새 키로 다시 흔들린다.
  int _shakes = 0;

  /// iOS 완료 체크 배지.
  bool _check = false;

  /// 아래 알림 한 줄(iOS 유리 알약 / Android 스낵바).
  String? _toast;
  bool _toastOk = true;
  VoidCallback? _toastAction;
  Timer? _toastTimer;
  Timer? _checkTimer;

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _pronouns.dispose();
    _phone.dispose();
    _gender.dispose();
    _toastTimer?.cancel();
    _checkTimer?.cancel();
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

  /// 메뉴·시트에서 고른 것을 한다.
  Future<void> _act(_PhotoAction action) async {
    switch (action) {
      case _PhotoAction.take:
        await _pick(ImageSource.camera);
      case _PhotoAction.choose:
        await _pick(ImageSource.gallery);
      case _PhotoAction.remove:
        await _remove();
    }
  }

  /// 카메라(앞 렌즈)나 갤러리 → 자르기 → 올리기.
  Future<void> _pick(ImageSource source) async {
    XFile? picked;
    try {
      picked = await (widget.picker ?? ImagePicker()).pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        // 자르기가 512 로 줄인다. 원본 그대로면 몇 MB 를 풀고 버린다.
        maxWidth: 2048,
        maxHeight: 2048,
      );
    } on PlatformException catch (e, s) {
      // 권한을 거절했으면 메뉴만 닫고 조용히 끝난다.
      if (!e.code.endsWith('_access_denied')) {
        TpErrors.record(e, s, reason: 'profile.pick');
      }
      return;
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'profile.pick');
      return;
    }
    if (picked == null || !mounted) return;

    final raw = await picked.readAsBytes();
    if (!mounted) return;
    final cropped = await (widget.crop ?? _openCrop)(context, raw);
    if (cropped == null || !mounted) return;
    await _upload(cropped);
  }

  Future<Uint8List?> _openCrop(BuildContext context, Uint8List bytes) =>
      Navigator.of(context).push<Uint8List>(
        context.tp.isGlass
            ? MaterialPageRoute<Uint8List>(
                fullscreenDialog: true,
                builder: (_) => PhotoCropScreen(bytes: bytes),
              )
            : MaterialPageRoute<Uint8List>(
                fullscreenDialog: true,
                builder: (_) => PhotoCropScreen(bytes: bytes),
              ),
      );

  Future<void> _upload(Uint8List bytes) async {
    _hideToast();
    setState(() {
      _photo = _Photo.uploading;
      _progress = null;
      _pending = bytes;
      _check = false;
    });
    final url = await ref
        .read(profileProvider.notifier)
        .uploadPhoto(
          bytes,
          onProgress: (v) {
            if (mounted) setState(() => _progress = v.clamp(0.0, 1.0));
          },
        );
    if (!mounted) return;
    if (url == null) {
      // 이전 사진은 그대로 남는다.
      TpHaptics.error();
      setState(() {
        _photo = _Photo.failed;
        _shakes++;
      });
      // Android 는 빨간 줄에 더해 스낵바 "다시 시도".
      if (!context.tp.isGlass) {
        _showToast(K.photoFailed.tr(), ok: false, action: _retry);
      }
      return;
    }
    TpHaptics.commit();
    setState(() {
      _photo = _Photo.idle;
      _pending = null;
      _pops++;
    });
    _showCheck();
    _showToast(K.photoUpdated.tr());
  }

  void _retry() {
    final bytes = _pending;
    if (bytes != null) unawaited(_upload(bytes));
  }

  /// 확인 → 문서에서 떼고 파일을 지운다.
  Future<void> _remove() async {
    final glass = context.tp.isGlass;
    final bool? sure = glass
        ? await showTpAlert<bool>(
            context: context,
            title: K.removePhoto.tr(),
            message: K.removePhotoAsk.tr(),
            actions: <TpAlertAction<bool>>[
              TpAlertAction<bool>(label: K.cancel.tr(), cancel: true),
              TpAlertAction<bool>(
                label: K.removePhoto.tr(),
                value: true,
                destructive: true,
              ),
            ],
          )
        : await showDialog<bool>(
            context: context,
            builder: (dialog) => AlertDialog(
              content: Text(K.removePhotoAsk.tr()),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialog).pop(false),
                  child: Text(K.cancel.tr()),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialog).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(dialog).colorScheme.error,
                  ),
                  child: Text(K.remove.tr()),
                ),
              ],
            ),
          );
    if (sure != true || !mounted) return;
    final removed = await ref.read(profileProvider.notifier).removePhoto();
    if (!mounted) return;
    setState(() {
      _photo = _Photo.idle;
      _pending = null;
      _check = false;
    });
    if (removed) {
      TpHaptics.commit();
      _showToast(K.photoRemoved.tr());
    } else {
      setState(() => _notice = K.profileFailed.tr());
    }
  }

  /// 체크 배지는 아바타가 튀고 250ms 뒤에.
  void _showCheck() {
    if (!context.tp.isGlass) return;
    _checkTimer?.cancel();
    final delay = context.motion.isReduced
        ? Duration.zero
        : const Duration(milliseconds: 250);
    _checkTimer = Timer(delay, () {
      if (mounted) setState(() => _check = true);
    });
  }

  /// iOS 는 2초, Android 스낵바는 4초.
  void _showToast(String text, {bool ok = true, VoidCallback? action}) {
    _toastTimer?.cancel();
    setState(() {
      _toast = text;
      _toastOk = ok;
      _toastAction = action;
    });
    _toastTimer = Timer(
      context.tp.isGlass
          ? const Duration(seconds: 2)
          : const Duration(seconds: 4),
      _hideToast,
    );
  }

  void _hideToast() {
    _toastTimer?.cancel();
    if (!mounted || _toast == null) return;
    setState(() {
      _toast = null;
      _toastAction = null;
      _check = false;
    });
  }

  /// Android: 아바타를 누르면 바텀 시트.
  Future<void> _openSheet(bool hasPhoto) async {
    final picked = await showModalBottomSheet<_PhotoAction>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => _PhotoSheet(hasPhoto: hasPhoto),
    );
    if (picked != null && mounted) await _act(picked);
  }

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final glass = context.tp.isGlass;
    final profile = ref.watch(profileProvider).value ?? const TpProfile();
    final user = ref.watch(currentUserProvider);
    _fill(profile);

    final hasPhoto = profile.photoUrl != null;
    final uploading = _photo == _Photo.uploading;

    final avatar = _Avatar(
      url: profile.photoUrl,
      local: uploading ? _pending : null,
      initials: YouScreen.initials(user?.name, user?.email),
      progress: _progress,
      uploading: uploading,
      pops: _pops,
      shakes: _shakes,
      check: _check,
      badge: !glass,
    );

    // 스크린 리더: 아바타 버튼 이름은 "사진 바꾸기", 올리는 중엔 비율까지.
    final avatarLabel = !uploading
        ? K.changePhoto.tr()
        : _progress == null
        ? K.photoUploading.tr()
        : K.a11yPhotoUploading.tr(
            args: <String>['${(_progress! * 100).round()}'],
          );

    final items = <TpMenuItem>[
      TpMenuItem(
        label: K.takePhoto.tr(),
        icon: CupertinoIcons.camera,
        onTap: () => unawaited(_act(_PhotoAction.take)),
      ),
      TpMenuItem(
        label: K.choosePhoto.tr(),
        icon: CupertinoIcons.photo,
        onTap: () => unawaited(_act(_PhotoAction.choose)),
      ),
      if (hasPhoto)
        TpMenuItem(
          label: K.removePhoto.tr(),
          icon: CupertinoIcons.trash,
          destructive: true,
          onTap: () => unawaited(_act(_PhotoAction.remove)),
        ),
    ];

    final Widget photo;
    if (!glass) {
      // Android: 아바타 전체 + 카메라 배지. 누르면 바텀 시트.
      photo = Semantics(
        button: true,
        label: avatarLabel,
        excludeSemantics: true,
        onTap: uploading ? null : () => unawaited(_openSheet(hasPhoto)),
        child: TpTappable(
          onTap: uploading ? null : () => unawaited(_openSheet(hasPhoto)),
          press: true,
          child: avatar,
        ),
      );
    } else if (TpNativeGlass.enabled) {
      // iOS 26: 아바타 아래 "사진 바꾸기"에서 시스템 유리 메뉴가 펼쳐진다.
      photo = Column(
        children: <Widget>[
          Semantics(label: avatarLabel, image: true, child: avatar),
          const SizedBox(height: 4),
          IgnorePointer(
            ignoring: uploading,
            child: TpNativeMenuLink(
              label: K.changePhoto.tr(),
              color: context.tp.link,
              entries: <TpNativeMenuEntry>[
                for (var i = 0; i < items.length; i++)
                  TpNativeMenuEntry(
                    label: items[i].label,
                    destructive: items[i].destructive,
                    symbol: switch (i) {
                      0 => 'camera',
                      1 => 'photo.on.rectangle',
                      _ => 'trash',
                    },
                  ),
              ],
              onSelected: (i) => items[i].onTap(),
            ),
          ),
        ],
      );
    } else {
      // 유리 메뉴가 없는 iOS·테스트: 같은 자리에서 Flutter 풀다운.
      photo = TpMenu(
        items: items,
        builder: (context, open) => Column(
          children: <Widget>[
            Semantics(
              button: true,
              label: avatarLabel,
              excludeSemantics: true,
              onTap: uploading ? null : open,
              child: TpTappable(
                onTap: uploading ? null : open,
                press: true,
                child: avatar,
              ),
            ),
            const SizedBox(height: 4),
            TpTapTarget(
              onTap: uploading ? null : open,
              minSize: 44,
              child: Text(
                K.changePhoto.tr(),
                style: type.body.copyWith(color: context.tp.link),
              ),
            ),
          ],
        ),
      );
    }

    // `iOS-ProfileEdit`: X / 프로필 수정 / 체크(Android 는 "취소"·"저장"). 버튼 자리는
    // 다른 화면과 같다([TpTopBar]).
    final page = TpPage(
      title: K.editProfile.tr(),
      largeTitle: false,
      leading: TpBarAction(
        label: K.cancel.tr(),
        role: TpBarRole.close,
        text: true,
        onTap: widget.onBack,
      ),
      actions: <TpBarAction>[
        TpBarAction(
          label: K.save.tr(),
          role: TpBarRole.confirm,
          text: true,
          filled: true,
          onTap: _busy ? null : () => _save(profile),
        ),
      ],
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, glass ? 16 : 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(child: photo),
                _PhotoStatus(
                  photo: _photo,
                  progress: _progress,
                  onRetry: glass ? _retry : null,
                ),
                const SizedBox(height: 16),
                TpSurface(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: <Widget>[
                      _Field(label: K.nameLabel.tr(), controller: _name),
                      _Field(
                        label: K.usernameLabel.tr(),
                        controller: _username,
                      ),
                      _Field(
                        label: K.pronounsLabel.tr(),
                        controller: _pronouns,
                      ),
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
              ],
            ),
          ),
        ),
      ],
    );

    return Stack(
      children: <Widget>[
        Positioned.fill(child: page),
        Positioned(
          left: 16,
          right: 16,
          bottom: MediaQuery.paddingOf(context).bottom + (glass ? 48 : 16),
          child: _Toast(
            text: _toast,
            ok: _toastOk,
            action: _toastAction,
            onAction: () {
              final action = _toastAction;
              _hideToast();
              action?.call();
            },
          ),
        ),
      ],
    );
  }
}

/// 96 원. 사진·이니셜, 올리는 중엔 진행 원, 끝나면 튀고, 실패하면 흔들린다.
class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.url,
    required this.local,
    required this.initials,
    required this.progress,
    required this.uploading,
    required this.pops,
    required this.shakes,
    required this.check,
    required this.badge,
  });

  static const double size = 96;

  final String? url;

  /// 올리는 중인 사진. 55% 로 보인다.
  final Uint8List? local;
  final String initials;
  final double? progress;
  final bool uploading;
  final int pops;
  final int shakes;

  /// iOS 완료 체크.
  final bool check;

  /// Android 카메라 배지.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final letters = Text(
      initials,
      maxLines: 1,
      softWrap: false,
      style: const TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
    Widget face = Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: TpTokens.blue,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: local != null
          ? Opacity(
              opacity: .55,
              child: Image.memory(
                local!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            )
          : url == null
          ? letters
          // 사진을 못 읽어도 화면은 남아야 한다.
          : Image.network(
              url!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => letters,
            ),
    );
    if (pops > 0) face = TpPopIn(key: ValueKey<int>(pops), child: face);

    final stack = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          face,
          if (uploading)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 4,
                color: TpSys.accent,
                backgroundColor: TpSys.accent.withValues(alpha: .2),
              ),
            ),
          if (badge)
            Positioned(
              right: -4,
              bottom: -2,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.sys.background, width: 2),
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          if (check)
            const Positioned(
              right: -2,
              bottom: -2,
              child: TpPopIn(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFF34C759),
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  child: SizedBox.square(
                    dimension: 28,
                    child: Icon(
                      CupertinoIcons.checkmark_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // 실패하면 좌우 6pt 로 흔들린다. 동작 줄이기면 흔들지 않는다.
    if (shakes == 0 || motion.isReduced) return stack;
    return TweenAnimationBuilder<double>(
      key: ValueKey<int>(shakes),
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) => Transform.translate(
        offset: Offset(6 * math.sin(t * 4 * math.pi) * (1 - t), 0),
        child: child,
      ),
      child: stack,
    );
  }
}

/// 아바타 아래 한 줄. 올리는 중, 또는 실패와 다시 시도.
class _PhotoStatus extends StatelessWidget {
  const _PhotoStatus({
    required this.photo,
    required this.progress,
    required this.onRetry,
  });

  final _Photo photo;
  final double? progress;

  /// iOS 만. Android 는 스낵바가 다시 시도를 든다.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    final Widget child = switch (photo) {
      _Photo.idle => const SizedBox(key: ValueKey<String>('idle')),
      _Photo.uploading => Padding(
        key: const ValueKey<String>('up'),
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          progress == null || glass
              ? K.photoUploading.tr()
              : '${K.photoUploading.tr()} ${(progress! * 100).round()}%',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: sys.label2),
        ),
      ),
      _Photo.failed => Padding(
        key: const ValueKey<String>('failed'),
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  glass
                      ? CupertinoIcons.exclamationmark_circle
                      : Icons.error_outline,
                  size: 14,
                  color: sys.destructive,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    K.photoFailed.tr(),
                    style: TextStyle(fontSize: 13, color: sys.destructive),
                  ),
                ),
              ],
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 6),
              Semantics(
                button: true,
                label: K.retry.tr(),
                excludeSemantics: true,
                onTap: onRetry,
                child: TpTappable(
                  onTap: onRetry,
                  press: true,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: sys.cell,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      K.retry.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.tp.link,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    };
    return AnimatedSwitcher(
      duration: context.motion.contentSwap.duration,
      child: child,
    );
  }
}

/// Android 바텀 시트. 찍기, 고르기, (있으면) 지우기.
class _PhotoSheet extends StatelessWidget {
  const _PhotoSheet({required this.hasPhoto});

  final bool hasPhoto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget row(_PhotoAction action, IconData icon, String label, {Color? c}) =>
        ListTile(
          minTileHeight: 56,
          leading: Icon(icon, color: c),
          title: Text(label, style: TextStyle(color: c)),
          onTap: () => Navigator.of(context).pop(action),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            K.changePhoto.tr(),
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
        ),
        row(_PhotoAction.take, Icons.photo_camera_outlined, K.takePhoto.tr()),
        row(
          _PhotoAction.choose,
          Icons.photo_library_outlined,
          K.choosePhotoGallery.tr(),
        ),
        if (hasPhoto) ...<Widget>[
          const Divider(indent: 24, endIndent: 24),
          row(
            _PhotoAction.remove,
            Icons.delete_outline,
            K.removePhoto.tr(),
            c: scheme.error,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

/// 아래 알림. iOS 는 유리 알약 44, Android 는 스낵바.
class _Toast extends StatelessWidget {
  const _Toast({
    required this.text,
    required this.ok,
    required this.action,
    required this.onAction,
  });

  final String? text;
  final bool ok;
  final VoidCallback? action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    final shown = text;
    final Widget body;
    if (shown == null) {
      body = const SizedBox.shrink(key: ValueKey<String>('none'));
    } else if (glass) {
      body = Center(
        key: ValueKey<String>(shown),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sys.cell,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 20,
                color: ok ? const Color(0xFF34C759) : sys.label3,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  shown,
                  style: TextStyle(fontSize: 15, color: sys.label),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final scheme = Theme.of(context).colorScheme;
      body = Material(
        key: ValueKey<String>(shown),
        color: scheme.inverseSurface,
        elevation: 6,
        borderRadius: BorderRadius.circular(4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: <Widget>[
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    shown,
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onInverseSurface,
                    ),
                  ),
                ),
              ),
              if (action != null)
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: scheme.inversePrimary,
                  ),
                  child: Text(K.retry.tr()),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      );
    }
    return Semantics(
      liveRegion: shown != null,
      child: AnimatedSwitcher(
        duration: context.motion.contentSwap.duration,
        child: body,
      ),
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
          SizedBox(width: 108, child: Text(label, style: type.secondary)),
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
