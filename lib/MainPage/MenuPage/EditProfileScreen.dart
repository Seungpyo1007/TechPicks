import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User? user;
  String username = '';
  String pronouns = '';
  String phoneNumber = '';
  String gender = '';
  String userId = ''; // 사용자 ID
  String newEmail = ''; // 새로운 이메일
  String password = '************'; // 비밀번호 기본 값
  bool isPasswordVisible = false; // 비밀번호 가시성 여부
  String userEmail = ''; // 로그인된 사용자 이메일
  bool isLoading = true; // 데이터 로딩 상태 확인용

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    _fetchUserData();
  }

  // Firestore에서 사용자 데이터를 가져오기
  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        // Firestore에서 사용자 문서 가져오기
        final userDocument = await _firestore.collection('users').doc(user!.uid).get();

        // 문서가 존재하는지 확인
        if (userDocument.exists) {
          setState(() {
            // 데이터가 존재할 때만 필드에 접근
            final data = userDocument.data() ?? {};
            username = data['username'] ?? ''; // Firestore 필드: username
            pronouns = data['pronouns'] ?? ''; // Firestore 필드: pronouns
            phoneNumber = data['phone_number'] ?? ''; // Firestore 필드: phone_number
            gender = data['gender'] ?? ''; // Firestore 필드: gender
            userId = data['user_id'] ?? user!.uid; // Firestore 필드: user_id 또는 기본 UID 사용
            userEmail = user?.email ?? ''; // Firebase 인증 사용자 이메일
            newEmail = userEmail; // 새로운 이메일 필드 초기화
            isLoading = false; // 데이터 로딩 완료
          });
        } else {
          setState(() {
            isLoading = false; // 데이터 로딩 완료
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User profile does not exist. Creating default profile...')),
          );

          // Firestore에 기본 사용자 문서 생성
          await _firestore.collection('users').doc(user!.uid).set({
            'username': 'New User',
            'pronouns': '',
            'phone_number': '',
            'gender': '',
            'user_id': user!.uid, // 기본 사용자 ID 설정
            'email': user!.email ?? '', // 이메일 필드 추가
          });
        }
      } catch (e) {
        setState(() {
          isLoading = false; // 데이터 로딩 완료
        });

        print("Error fetching user data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch user data. Please check your permissions or network connection.')),
        );
      }
    }
  }

  // 사용자 데이터 Firestore에 저장 및 이메일 업데이트하기
  Future<void> _saveUserData() async {
    if (user != null) {
      try {
        // Firebase Authentication의 이메일 업데이트
        if (newEmail.isNotEmpty && newEmail != userEmail) {
          await user!.updateEmail(newEmail);
          userEmail = newEmail; // 사용자 이메일 필드 업데이트
        }

        // Firestore에 사용자 데이터 업데이트
        await _firestore.collection('users').doc(user!.uid).set({
          'username': username,
          'pronouns': pronouns,
          'phone_number': phoneNumber,
          'gender': gender,
          'user_id': userId,
          'email': newEmail, // 변경된 이메일 Firestore에 업데이트
        }, SetOptions(merge: true));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!'.tr())),
        );
      } catch (e) {
        print("Error saving user data: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save user data. Please check your permissions or network connection.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 여부를 확인하여 배경 및 텍스트 색상 설정
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 표준 배경 및 텍스트 색상 설정
    final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0); // 다크 모드: 어두운 색, 라이트 모드: 밝은 색
    final textColor = isDarkMode ? Colors.white : Colors.black; // 다크 모드: 흰색 텍스트, 라이트 모드: 검정색 텍스트

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), // 올바른 텍스트 색상 적용
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('profile'.tr(), style: TextStyle(color: textColor)), // 올바른 텍스트 색상 적용
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // 데이터 로딩 중일 때 로딩 스피너 표시
          : Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 로그인된 사용자 이메일 표시
                  Text(
                    'Logged in as:',
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userEmail,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // 사용자 ID 표시 필드
                  _buildTextField(labelText: 'User ID'.tr(), initialValue: userId, onChanged: (value) => userId = value, textColor: textColor),

                  // 새로운 이메일 입력 필드
                  _buildTextField(labelText: 'New Email'.tr(), initialValue: newEmail, onChanged: (value) => newEmail = value, textColor: textColor),

                  // 사용자 이름 입력 필드
                  _buildTextField(labelText: 'username'.tr(), initialValue: username, onChanged: (value) => username = value, textColor: textColor),

                  // 대명사 입력 필드
                  _buildTextField(labelText: 'pronouns'.tr(), initialValue: pronouns, onChanged: (value) => pronouns = value, textColor: textColor),

                  // 전화번호 입력 필드
                  _buildTextField(labelText: 'phone_number'.tr(), initialValue: phoneNumber, onChanged: (value) => phoneNumber = value, textColor: textColor),

                  // 성별 입력 필드
                  _buildTextField(labelText: 'gender'.tr(), initialValue: gender, onChanged: (value) => gender = value, textColor: textColor),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveUserData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textColor, // 올바른 텍스트 색상 적용
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: Text('save'.tr(), style: TextStyle(color: backgroundColor)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 텍스트 필드 생성 함수
  Widget _buildTextField({
    required String labelText,
    String? initialValue,
    bool isPassword = false,
    bool isPasswordVisible = false,
    required ValueChanged<String> onChanged,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        obscureText: isPassword && !isPasswordVisible, // 비밀번호 가시성 여부에 따른 텍스트 가리기
        onChanged: onChanged,
        style: TextStyle(color: textColor), // 텍스트 색상 적용
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: textColor), // 라벨 색상 적용
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
