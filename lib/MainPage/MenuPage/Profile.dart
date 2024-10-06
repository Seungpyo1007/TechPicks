import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:restart_app/restart_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'EditProfileScreen.dart';
import 'PhoneSetting.dart';
import '../../LoginPage/LoginPage.dart';
import '../../LoginPage/ChangePassword.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  String _username = 'Unknown User'; // Firestore에서 불러온 사용자 이름
  User? _currentUser;
  String? _profileImageUrl; // Firebase Storage에 저장된 프로필 이미지 URL
  File? _imageFile; // 선택된 이미지 파일

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // 현재 로그인된 사용자 가져오기
    _loadDarkModeSetting(); // 다크 모드 설정 불러오기
    _fetchUserProfile(); // Firestore에서 사용자 프로필 정보 불러오기
    _loadProfileImage(); // Firebase Storage에서 프로필 이미지 불러오기
  }

  // 다크 모드 설정 불러오기
  Future<void> _loadDarkModeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    });
  }

  // Firestore에서 사용자 프로필 정보 가져오기
  Future<void> _fetchUserProfile() async {
    if (_currentUser != null) {
      final userDocument = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (userDocument.exists) {
        setState(() {
          _username = userDocument.data()?['username'] ?? 'Unknown User'; // Firestore에서 username 가져오기
        });
      }
    }
  }

  // Firebase Storage에서 프로필 이미지 불러오기
  Future<void> _loadProfileImage() async {
    if (_currentUser != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${_currentUser!.uid}');
      try {
        final url = await storageRef.getDownloadURL();
        setState(() {
          _profileImageUrl = url; // 불러온 이미지 URL을 상태로 설정
        });
      } catch (e) {
        print("Failed to load profile image: $e");
      }
    }
  }

  // 이미지 선택 후 Firebase Storage에 업로드
  Future<void> _pickAndUploadImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path); // 선택한 이미지 파일을 상태로 설정
        });
        await _uploadImageToFirebase(); // 이미지 업로드
      }
    } catch (e) {
      print("Failed to pick and upload image: $e");
    }
  }

  // Firebase Storage에 이미지 업로드
  Future<void> _uploadImageToFirebase() async {
    if (_imageFile == null || _currentUser == null) return;
    final storageRef = FirebaseStorage.instance.ref().child('profile_images/${_currentUser!.uid}');
    try {
      await storageRef.putFile(_imageFile!);
      final url = await storageRef.getDownloadURL();
      setState(() {
        _profileImageUrl = url; // 업로드한 이미지의 URL을 상태로 설정
      });
      await _saveProfileImageUrl(url); // Firestore에 URL 저장
    } catch (e) {
      print("Failed to upload image: $e");
    }
  }

  // Firestore에 프로필 이미지 URL 저장
  Future<void> _saveProfileImageUrl(String url) async {
    if (_currentUser != null) {
      final firestoreRef = FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);
      await firestoreRef.update({'profileImageUrl': url});
    }
  }

  // 다크 모드 토글
  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = value;
    });
    await prefs.setBool('is_dark_mode', value);
    _showRestartForThemeChangeDialog(context); // 테마 변경 시 재시작 다이얼로그 호출
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = _isDarkMode;
    final backgroundColor = isDarkMode ? const Color(0xFF222222) : const Color(0xFFE0E0E0);
    final textColor = isDarkMode ? Colors.white : Colors.black;

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
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!) // Firebase Storage에서 불러온 이미지
                            : const AssetImage('assets/logo/logo.png') as ImageProvider, // 기본 이미지
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _username, // Firestore에서 불러온 사용자 이름 표시
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: _currentUser?.isAnonymous ?? false ? null : _pickAndUploadImage, // 익명 사용자는 비활성화
                        child: Text('Change Profile Image'.tr()),
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
                  activeColor: textColor, // 스위치 활성화 시 텍스트 색상과 동일하게
                  onChanged: (bool value) {
                    _toggleDarkMode(value);
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('profile'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ),
                ListTile(
                  leading: Icon(Icons.person, color: textColor),
                  title: Text('edit_profile'.tr(), style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, color: textColor),
                  onTap: () {
                    if (_currentUser?.isAnonymous ?? false) {
                      _showAnonymousUserAlert(); // 익명 사용자는 경고창 표시
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EditProfileScreen()),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.lock, color: textColor),
                  title: Text('change_password'.tr(), style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, color: textColor),
                  onTap: () {
                    if (_currentUser?.isAnonymous ?? false) {
                      _showAnonymousUserAlert(); // 익명 사용자는 경고창 표시
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChangePassword()),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('notifications'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ),
                SwitchListTile(
                  title: Text('notifications'.tr(), style: TextStyle(color: textColor)),
                  secondary: Icon(Icons.notifications, color: textColor),
                  value: true,
                  activeColor: textColor, // 스위치 활성화 시 텍스트 색상과 동일하게
                  onChanged: (bool value) {
                    // 알림 설정 토글 시의 동작 추가
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('choose_language'.tr(), style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ),
                ListTile(
                  leading: Icon(Icons.language, color: textColor),
                  title: Text('choose_language'.tr(), style: TextStyle(color: textColor)),
                  trailing: Icon(Icons.arrow_forward_ios, color: textColor),
                  onTap: () {
                    _showLanguageDialog(context); // 언어 선택 다이얼로그 호출
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: textColor),
                  title: Text('logout'.tr(), style: TextStyle(color: textColor)),
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

  // 언어 변경 다이얼로그 표시 메서드
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text('Choose Language'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
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

  // 언어 변경 처리 메서드
  Future<void> _changeLanguage(BuildContext context, String languageCode, String countryCode) async {
    final locale = Locale(languageCode, countryCode);
    context.setLocale(locale);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_locale', '${locale.languageCode}_${locale.countryCode}');

    Navigator.of(context).pop();
    _showRestartConfirmationDialog(context);
  }

  // 테마 변경 시 재시작 다이얼로그 표시
  void _showRestartForThemeChangeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text('Restart Required'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Text('The app needs to restart for theme changes to take effect.'.tr(),
              style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Restart.restartApp(); // 앱 재시작
              },
              child: Text('Yes'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            ),
          ],
        );
      },
    );
  }

  // 앱 재시작 확인 다이얼로그 표시
  void _showRestartConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text('Restart Required'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Text('The app needs to restart to apply changes.'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            ),
            TextButton(
              onPressed: () {
                Restart.restartApp(); // 앱 재시작
              },
              child: Text('Yes'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            ),
          ],
        );
      },
    );
  }

  // 익명 사용자 경고 메시지 표시
  void _showAnonymousUserAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _isDarkMode ? Colors.grey[850] : Colors.white,
          title: Text('Access Denied'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: Text(
            'Anonymous users cannot edit profiles or change passwords.'.tr(),
            style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'.tr(), style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
            ),
          ],
        );
      },
    );
  }

  // 로그아웃 처리 메서드
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false); // SharedPreferences 초기화
    await FirebaseAuth.instance.signOut(); // Firebase 로그아웃
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LoginPage()),
    ); // 로그인 페이지로 이동
  }
}
