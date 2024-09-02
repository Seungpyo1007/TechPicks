import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Cupertino 패키지 추가
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth 패키지 추가
import 'package:easy_localization/easy_localization.dart'; // 번역 패키지 추가
import '../MainPage/MainPage.dart';
import '../components/EmailLoginPageBackground.dart';
import 'RegisterPage.dart';
import 'DeveloperLogin.dart'; // DeveloperLogin 페이지 임포트
import 'ChangePassword.dart'; // ChangePassword 페이지 임포트

class MainLoginPage extends StatefulWidget {
  @override
  _MainLoginPageState createState() => _MainLoginPageState();
}

class _MainLoginPageState extends State<MainLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  int _selectedIndex = 0; // 0 for Login, 1 for Developer Login

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Background(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildSegmentedControl(), // 고정된 위치에 토글 컨트롤 추가
            SizedBox(height: size.height * 0.03),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300), // 애니메이션 지속 시간
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildContent(size, context), // 애니메이션이 적용된 콘텐츠
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.0), // 토글 버튼 위치 고정
      child: CupertinoSegmentedControl<int>(
        borderColor: Color(0xFF2661FA),
        selectedColor: Color(0xFF2661FA),
        unselectedColor: Colors.white,
        children: {
          0: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('login'.tr(), style: TextStyle(fontSize: 14)), // 텍스트 번역 추가
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('developer_login'.tr(), style: TextStyle(fontSize: 14)), // 텍스트 번역 추가
          ),
        },
        groupValue: _selectedIndex,
        onValueChanged: (int value) {
          setState(() {
            _selectedIndex = value;
          });
        },
      ),
    );
  }

  Widget _buildContent(Size size, BuildContext context) {
    // 선택된 인덱스에 따라 보여줄 뷰를 결정
    if (_selectedIndex == 0) {
      return _buildLoginView(size, context);
    } else {
      return _buildDeveloperLoginView(context);
    }
  }

  Widget _buildLoginView(Size size, BuildContext context) {
    return Column(
      key: ValueKey(0), // AnimatedSwitcher를 위한 고유 키
      children: [
        _buildHeaderText("login".tr()), // 텍스트 번역 추가
        SizedBox(height: size.height * 0.03),
        _buildTextField("email".tr(), controller: _emailController), // 텍스트 번역 추가
        SizedBox(height: size.height * 0.03),
        _buildTextField("password".tr(), controller: _passwordController, obscureText: true), // 텍스트 번역 추가
        _buildForgotPasswordText(context), // 네비게이션을 위한 컨텍스트 추가
        SizedBox(height: size.height * 0.05),
        _buildLoginButton(size, context, "login".tr()), // 텍스트 번역 추가
        _buildSignUpText(context),
      ],
    );
  }

  Widget _buildDeveloperLoginView(BuildContext context) {
    return Column(
      key: ValueKey(1), // AnimatedSwitcher를 위한 고유 키
      children: [
        _buildHeaderText("developer_login".tr()), // 텍스트 번역 추가
        SizedBox(height: 20),
        _buildDeveloperLoginButton(context),
      ],
    );
  }

  Widget _buildDeveloperLoginButton(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DeveloperLogin()), // DeveloperLogin 페이지로 이동
          );
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(80.0),
          ),
          padding: const EdgeInsets.all(0),
          backgroundColor: Colors.transparent,
        ),
        child: Container(
          alignment: Alignment.center,
          height: 50.0,
          width: MediaQuery.of(context).size.width * 0.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(80.0),
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 136, 34),
                Color.fromARGB(255, 255, 177, 41),
              ],
            ),
          ),
          padding: const EdgeInsets.all(0),
          child: Text(
            "developer_login".tr(), // 텍스트 번역 추가
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordText(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChangePassword()), // ChangePassword 페이지로 이동
          );
        },
        child: Text(
          "forgot_password".tr(), // 텍스트 번역 추가
          style: TextStyle(fontSize: 12, color: Color(0XFF2661FA)),
        ),
      ),
    );
  }

  Widget _buildHeaderText(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2661FA),
          fontSize: 36,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildTextField(String labelText, {bool obscureText = false, required TextEditingController controller}) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: 40),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: labelText),
        obscureText: obscureText,
      ),
    );
  }

  Widget _buildLoginButton(Size size, BuildContext context, String buttonText) {
    return Container(
      alignment: Alignment.centerRight,
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: ElevatedButton(
        onPressed: () async {
          // Firebase 인증 로그인 로직
          try {
            UserCredential userCredential = await _auth.signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );
            if (userCredential.user != null) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SimpleBottomNavigation()),
              );
            }
          } catch (e) {
            // 로그인 실패 시 처리
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$buttonText".tr() + " " + "failed".tr())), // 텍스트 번역 추가
            );
          }
        },
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(80.0),
          ),
          padding: const EdgeInsets.all(0),
          backgroundColor: Colors.transparent,
        ),
        child: Container(
          alignment: Alignment.center,
          height: 50.0,
          width: size.width * 0.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(80.0),
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 136, 34),
                Color.fromARGB(255, 255, 177, 41),
              ],
            ),
          ),
          padding: const EdgeInsets.all(0),
          child: Text(
            buttonText,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpText(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: GestureDetector(
        onTap: () {
          _navigateToRegisterScreen(context);
        },
        child: Text(
          "no_account_sign_up".tr(), // 텍스트 번역 추가
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2661FA),
          ),
        ),
      ),
    );
  }

  void _navigateToRegisterScreen(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var begin = 0.0;
          var end = 1.0;
          var tween = Tween(begin: begin, end: end);
          var fadeAnimation = animation.drive(tween);

          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },
      ),
    );
  }
}
