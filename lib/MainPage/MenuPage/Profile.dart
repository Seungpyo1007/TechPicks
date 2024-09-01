import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../LoginPage/LoginPage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () async => false, // 뒤로 가기 버튼의 기본 동작을 막음
      child: Scaffold(
        appBar: AppBar(
          leading: Container(), // 뒤로 가기 버튼(화살표)을 제거
          backgroundColor: Colors.transparent, // 앱바 배경색 투명
          elevation: 0, // 앱바 그림자 제거
        ),
        extendBodyBehindAppBar: true, // 앱바를 몸체 뒤에 연장
        body: Stack(
          children: [
            // 그라데이션 배경
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Colors.blue], // 검정색에서 파란색으로 그라데이션
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
                    // User Information
                    ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(user?.photoURL ?? ''),
                        radius: 30,
                      ),
                      title: Text(
                        user?.displayName ?? 'No Name',
                        style: const TextStyle(color: Colors.white), // 텍스트 색상 변경
                      ),
                      subtitle: Text(
                        'edit_details'.tr(),
                        style: TextStyle(color: Colors.white70), // 텍스트 색상 변경
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        // 프로필 편집 페이지로 이동하는 코드 추가
                      },
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white),

                    // Dark Mode Setting
                    SwitchListTile(
                      title: Text('dark_mode'.tr(), style: TextStyle(color: Colors.white)),
                      secondary: const Icon(Icons.dark_mode, color: Colors.white),
                      value: true,
                      onChanged: (bool value) {
                        // 다크 모드 토글 시의 동작 추가
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
                        // 프로필 편집 페이지로 이동하는 코드 추가
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock, color: Colors.white),
                      title: Text('change_password'.tr(),
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        // 비밀번호 변경 페이지로 이동하는 코드 추가
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
                        _showLanguageDialog(context); // 언어 선택 팝업 창을 표시
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.white),
                      title: Text('logout'.tr(),
                          style: TextStyle(color: Colors.white)),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () async {
                        await FirebaseAuth.instance.signOut(); // 로그아웃 수행
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) => LoginPage()),
                        ); // LoginPage로 이동
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
          title: Text('choose_language'.tr()), // 팝업창 제목
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.language, color: Colors.blue),
                title: Text('English'),
                onTap: () {
                  context.setLocale(Locale('en', 'US')); // 영어로 변경
                  Navigator.of(context).pop(); // 팝업 닫기
                },
              ),
              ListTile(
                leading: Icon(Icons.language, color: Colors.red),
                title: Text('한국어'),
                onTap: () {
                  context.setLocale(Locale('ko', 'KR')); // 한국어로 변경
                  Navigator.of(context).pop(); // 팝업 닫기
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
