import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'EditProfileScreen.dart';
import 'PhoneSetting.dart'; // 새로 만든 파일을 import
import '../../LoginPage/LoginPage.dart';
import '../../LoginPage/ChangePassword.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  String _phoneNickname = 'Unknown Device'; // 초기 별명 값 설정

  @override
  void initState() {
    super.initState();
    _loadDarkModeSetting();
    _loadPhoneNickname();
  }

  Future<void> _loadDarkModeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }

  Future<void> _loadPhoneNickname() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phoneNickname = prefs.getString('phone_nickname') ?? 'Galaxy S23 Ultra'; // 기본 모델명 사용
    });
  }

  Future<void> _navigateToPhoneSetting() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PhoneSetting()),
    );
    if (result != null) {
      setState(() {
        _phoneNickname = result; // 반환된 별명으로 업데이트
      });
    }
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('is_dark_mode', value);
    _showRestartForThemeChangeDialog(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF222222) : const Color(0xFFE0E0E0);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final switchColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false, // 뒤로 가기 버튼 비활성화
        backgroundColor: backgroundColor,
        elevation: 0, // 그림자 제거
        toolbarHeight: 0, // AppBar의 높이를 0으로 설정하여 빈 공간 없애기
      ),
      body: SafeArea(
        child: Container(
          // 라이트 모드일 때 배경을 단색으로 설정
          decoration: !isDarkMode
              ? const BoxDecoration(
            color: Color(0xFFE0E0E0), // 배경색을 E0E0E0로 설정
          )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        radius: 40,
                        backgroundImage: const NetworkImage(
                          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRan1_0IEDJRBm1YkvqKvTalg83rNIEafe3LA&s',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _phoneNickname,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: _navigateToPhoneSetting,
                        child: Text('edit'.tr()),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Divider(color: textColor),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: Text('dark_mode'.tr(), style: TextStyle(color: textColor)),
                  secondary: Icon(Icons.dark_mode, color: textColor),
                  value: _isDarkMode,
                  activeColor: switchColor, // 스위치 활성화 시 다크모드 여부에 따라 검정 또는 흰색
                  onChanged: (bool value) {
                    _toggleDarkMode(value);
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('profile'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: textColor)),
                ),
                ListTile(
                  leading: Icon(Icons.person, color: textColor),
                  title: Text('edit_profile'.tr(),
                      style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, color: textColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock, color: textColor),
                  title: Text('change_password'.tr(),
                      style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, color: textColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChangePassword()),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('notifications'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: textColor)),
                ),
                SwitchListTile(
                  title: Text('notifications'.tr(),
                      style: TextStyle(color: textColor)),
                  secondary: Icon(Icons.notifications, color: textColor),
                  value: true,
                  activeColor: switchColor, // 스위치 활성화 시 다크모드 여부에 따라 검정 또는 흰색
                  onChanged: (bool value) {
                    // 알림 설정 토글 시의 동작 추가
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('choose_language'.tr(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: textColor)),
                ),
                ListTile(
                  leading: Icon(Icons.language, color: textColor),
                  title: Text('choose_language'.tr(),
                      style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, color: textColor),
                  onTap: () {
                    _showLanguageDialog(context);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: textColor),
                  title: Text('logout'.tr(),
                      style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, color: textColor),
                  onTap: () async {
                    await _logout(); // 로그아웃 시 SharedPreferences 초기화 및 Firebase 로그아웃
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('app_version'.tr(), style: TextStyle(color: textColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // SharedPreferences 초기화
    await FirebaseAuth.instance.signOut(); // Firebase 로그아웃
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    ); // 로그인 페이지로 이동
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text('choose_language'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.language, color: Colors.blue),
                title: Text('English', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
                onTap: () async {
                  await _changeLanguage(context, 'en', 'US');
                },
              ),
              ListTile(
                leading: Icon(Icons.language, color: Colors.red),
                title: Text('한국어', style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
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
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text('restart_required'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Text('theme_change_confirm_message'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('no'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Restart.restartApp();
              },
              child: Text('yes'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
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
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text('restart_required'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Text('restart_confirm_message'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('no'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Restart.restartApp();
              },
              child: Text('yes'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            ),
          ],
        );
      },
    );
  }
}
