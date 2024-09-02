import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'EditProfileScreen.dart';
import '../../LoginPage/LoginPage.dart';
import '../../LoginPage/ChangePassword.dart';

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

    _showRestartForThemeChangeDialog(context);
  }

  void _applyTheme() {
    Restart.restartApp();
  }

  @override
  Widget build(BuildContext context) {
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
                    // 상단 핸드폰 이미지와 모델명, 편집 버튼 추가
                    Center(
                      child: Column(
                        children: [
                          // 핸드폰 이미지
                          Image.network(
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRan1_0IEDJRBm1YkvqKvTalg83rNIEafe3LA&s', // 여기에 실제 이미지 URL을 넣으세요.
                            height: 0,
                          ),
                          const SizedBox(height: 8),
                          // 핸드폰 모델명
                          Text(
                            'G의 S23 Ultra',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // 편집 버튼
                          ElevatedButton(
                            onPressed: () {
                              // 편집 버튼의 동작 추가
                            },
                            child: Text('편집'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black, backgroundColor: Colors.white, // 버튼 텍스트 색상
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20), // 요소 간 간격
                    const Divider(color: Colors.white),
                    const SizedBox(height: 8),

                    SwitchListTile(
                      title: Text('dark_mode'.tr(), style: TextStyle(color: Colors.white)),
                      secondary: const Icon(Icons.dark_mode, color: Colors.white),
                      value: _isDarkMode,
                      onChanged: (bool value) {
                        _toggleDarkMode(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
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
                    const SizedBox(height: 8),

                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
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
                    const SizedBox(height: 8),

                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
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

  Future<void> _changeLanguage(BuildContext context, String languageCode, String countryCode) async {
    final locale = Locale(languageCode, countryCode);
    context.setLocale(locale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', '${locale.languageCode}_${locale.countryCode}');

    Navigator.of(context).pop();
    _showRestartConfirmationDialog(context);
  }

  void _showRestartForThemeChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('restart_required'.tr()),
          content: Text('theme_change_confirm_message'.tr()),
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
