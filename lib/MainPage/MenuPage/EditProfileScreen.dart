import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop(); // 뒤로 가기 기능
          },
        ),
        title: Text('profile'.tr(), style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 그라데이션 배경
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 프로필 이미지 및 편집 아이콘
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('assets/images/profile_picture.png'), // 프로필 이미지 경로
                      ),
                      CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.edit, color: Colors.black, size: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Asini Sanja', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Designer', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 20),

                  // 사용자 이름 입력 필드
                  _buildTextField(labelText: 'username'.tr(), initialValue: 'asini.sanja'),

                  // 대명사 입력 필드
                  _buildTextField(labelText: 'pronouns'.tr(), initialValue: 'she/her'),

                  // 비밀번호 입력 필드
                  _buildTextField(
                    labelText: 'password'.tr(),
                    initialValue: '********************',
                    isPassword: true,
                  ),

                  // 전화번호 입력 필드
                  _buildTextField(labelText: 'phone_number'.tr(), initialValue: '+94 77 745 0101'),

                  // 성별 입력 필드
                  _buildTextField(labelText: 'gender'.tr(), initialValue: 'Female'),

                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // 프로필 저장 기능 추가
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    ),
                    child: Text('save'.tr(), style: TextStyle(color: Colors.white)), // 'Save' 번역 추가
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
  Widget _buildTextField({required String labelText, String? initialValue, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: initialValue,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(Icons.visibility, color: Colors.black),
            onPressed: () {
              // 비밀번호 보이기/숨기기 기능 추가
            },
          )
              : null,
        ),
      ),
    );
  }
}
