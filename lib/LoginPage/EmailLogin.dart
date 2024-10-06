import 'package:flutter/material.dart' as flutter;
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:shared_preferences/shared_preferences.dart';
import '../MainPage/MainPage.dart';
import '../components/EmailLoginPageBackground.dart';
import 'RegisterPage.dart';
import 'DeveloperLogin.dart';
import 'ChangePassword.dart';

class MainLoginPage extends StatefulWidget {
  @override
  _MainLoginPageState createState() => _MainLoginPageState();
}

class _MainLoginPageState extends State<MainLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isRememberMe = false;

  final List<String> developerEmails = ['admin@gmail.com', 'rush94434@gmail.com'];

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // 앱 시작 시 로그인 상태 확인
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SimpleBottomNavigation()),
      );
    }
  }

  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', isLoggedIn);
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', false); // 로그인 상태 초기화
    await _auth.signOut(); // Firebase 로그아웃 처리
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Background(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: size.height * 0.03),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildLoginView(size, context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginView(Size size, BuildContext context) {
    return Column(
      key: ValueKey(0),
      children: [
        _buildHeaderText("login".tr()),
        SizedBox(height: size.height * 0.03),
        _buildTextField("email".tr(), controller: _emailController),
        SizedBox(height: size.height * 0.03),
        _buildTextField("password".tr(), controller: _passwordController, obscureText: true),
        _buildRememberMeSwitch(), // Remember me 스위치 추가
        _buildForgotPasswordText(context),
        SizedBox(height: size.height * 0.05),
        _buildLoginButton(size, context, "login".tr()),
        _buildSignUpText(context),
      ],
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
            MaterialPageRoute(builder: (context) => ChangePassword()),
          );
        },
        child: Text(
          "forgot_password".tr(),
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

  Widget _buildRememberMeSwitch() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            "remember_me".tr(),
            style: TextStyle(fontSize: 14),
          ),
          Switch(
            value: _isRememberMe,
            onChanged: (value) {
              setState(() {
                _isRememberMe = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(Size size, BuildContext context, String buttonText) {
    return Container(
      alignment: Alignment.centerRight,
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: ElevatedButton(
        onPressed: () async {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
                content: Container(
                  width: 200,
                  height: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 150, // 애니메이션 너비
                        height: 150, // 애니메이션 높이
                        child: RiveAnimation.asset(
                          'assets/Rive/animgears.riv',
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "logging_in".tr(),
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

          try {
            UserCredential userCredential = await _auth.signInWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

            Navigator.of(context).pop();

            if (userCredential.user != null) {
              if (_isRememberMe) {
                _saveLoginStatus(true);
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => _buildSuccessDialog(context),
              );

              Future.delayed(Duration(seconds: 2), () {
                Navigator.of(context).pop();
                if (developerEmails.contains(userCredential.user!.email)) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => DeveloperLogin()),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SimpleBottomNavigation()),
                  );
                }
              });
            }
          } catch (e) {
            Navigator.of(context).pop();
            _showFailureAnimation(); // 로그인 실패 시 애니메이션 표시
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
            gradient: flutter.LinearGradient( // flutter 패키지의 LinearGradient 사용
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

  Widget _buildSuccessDialog(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      content: Container(
        width: 200,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 150, // 애니메이션 너비
              height: 150, // 애니메이션 높이
              child: RiveAnimation.asset(
                'assets/Rive/LoginSuccess.riv',
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "login_success".tr(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 로그인 실패 시 애니메이션 다이얼로그 표시
  Future<void> _showFailureAnimation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          content: Container(
            width: 200,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: RiveAnimation.asset(
                    'assets/Rive/error_icon.riv', // 실패 애니메이션 파일 경로
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "login_failed".tr(), // "로그인 실패" 메시지 표시
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );

    // 2초 후 다이얼로그 닫기
    await Future.delayed(Duration(seconds: 2));
    Navigator.of(context).pop();
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
          "no_account_sign_up".tr(),
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
