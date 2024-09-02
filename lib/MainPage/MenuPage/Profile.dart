import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:restart_app/restart_app.dart'; // 앱 재시작 패키지 임포트
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 패키지 추가
import 'EditProfileScreen.dart';
import '../../LoginPage/LoginPage.dart';
import '../../LoginPage/ChangePassword.dart'; // 비밀번호 변경 페이지 임포트

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadDarkModeSetting();
  }

  Future<void> _loadDarkModeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('is_dark_mode', value);

    // 재부팅 확인 메시지 표시
    _showRestartForThemeChangeDialog(context);
  }

  void _applyTheme() {
    Restart.restartApp();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          leading: Container(),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.blue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user?.photoURL ?? ''),
                        radius: 30,
                      ),
                      title: Text(
                        user?.displayName ?? 'No Name',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'edit_details'.tr(),
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfileScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white),

                    // 다크 모드 설정
                    SwitchListTile(
                      title: Text('dark_mode'.tr(), style: TextStyle(color: Colors.white)),
                      secondary: const Icon(Icons.dark_mode, color: Colors.white),
                      value: _isDarkMode,
                      onChanged: (bool value) {
                        _toggleDarkMode(value); // 다크 모드 토글 시 재부팅 확인 메시지 표시
                      },
                    ),

                    // Profile Settings
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Text('profile'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person, color: Colors.white),
                      title: Text('edit_profile'.tr(),
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EditProfileScreen()),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock, color: Colors.white),
                      title: Text('change_password'.tr(),
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChangePassword()),
                        );
                      },
                    ),

                    // Notification Settings
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Text('notifications'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    SwitchListTile(
                      title: Text('notifications'.tr(),
                          style: TextStyle(color: Colors.white)),
                      secondary: const Icon(Icons.notifications, color: Colors.white),
                      value: true,
                      onChanged: (bool value) {
                        // 알림 설정 토글 시의 동작 추가
                      },
                    ),

                    // Regional Settings
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.0),
                      child: Text('choose_language'.tr(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    ListTile(
                      leading: const Icon(Icons.language, color: Colors.white),
                      title: Text('choose_language'.tr(),
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        _showLanguageDialog(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: Text('logout'.tr(),
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        );
                      },
                    ),

                    const Spacer(),
                    Center(
                      child: Text('app_version'.tr(), style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 언어 선택 팝업 창을 표시하는 함수
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('choose_language'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.language, color: Colors.blue),
                title: Text('English'),
                onTap: () async {
                  await _changeLanguage(context, 'en', 'US');
                },
              ),
              ListTile(
                leading: Icon(Icons.language, color: Colors.red),
                title: Text('한국어'),
                onTap: () async {
                  await _changeLanguage(context, 'ko', 'KR');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 언어 변경 및 저장 함수
  Future<void> _changeLanguage(BuildContext context, String languageCode, String countryCode) async {
    final locale = Locale(languageCode, countryCode);
    context.setLocale(locale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', '${locale.languageCode}_${locale.countryCode}');

    Navigator.of(context).pop();
    _showRestartConfirmationDialog(context);
  }

  // 테마 변경 시 재부팅 확인 메시지 표시 함수
  void _showRestartForThemeChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('restart_required'.tr()), // 재부팅이 필요하다는 메시지
          content: Text('theme_change_confirm_message'.tr()), // 배경색 변경 재부팅 메시지
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('no'.tr()), // '아니요' 버튼
            ),
            TextButton(
              onPressed: () {
                Restart.restartApp();
              },
              child: Text('yes'.tr()), // '예' 버튼
            ),
          ],
        );
      },
    );
  }

  // 앱 재부팅 확인 메시지 표시 함수 (언어 변경)
  void _showRestartConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('restart_required'.tr()),
          content: Text('restart_confirm_message'.tr()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('no'.tr()),
            ),
            TextButton(
              onPressed: () {
                Restart.restartApp();
              },
              child: Text('yes'.tr()),
            ),
          ],
        );
      },
    );
  }
}
