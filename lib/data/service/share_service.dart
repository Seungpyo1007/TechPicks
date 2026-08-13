import 'package:share_plus/share_plus.dart';

/// 시스템 공유 시트.
///
/// 화면은 이 인터페이스만 본다. 테스트가 시트를 띄우지 않아도 되게 하려는
/// 것이고, [AskService] · [AuthService] 와 같은 이유다.
abstract class ShareService {
  /// [text] 를 공유한다. [subject] 는 메일처럼 제목이 있는 앱만 쓴다.
  Future<void> shareText(String text, {String? subject});
}

/// `share_plus` 구현.
class SharePlusService implements ShareService {
  const SharePlusService();

  @override
  Future<void> shareText(String text, {String? subject}) =>
      SharePlus.instance.share(ShareParams(text: text, subject: subject));
}
