import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rive/rive.dart' hide Image; // Rive 관련 패키지
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 추가
import '../MainPage/MainPage.dart';
import 'EmailLogin.dart';
import 'DeveloperLogin.dart'; // DeveloperLogin 페이지 추가

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<String> developerEmails = ['admin@gmail.com', 'rush94434@gmail.com']; // 개발자 계정 리스트

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLoginStatus(); // 앱 시작 시 로그인 상태 확인
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 로그인 상태 확인 및 자동 로그인
  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (isLoggedIn) {
      User? user = _auth.currentUser;
      if (user != null && !user.isAnonymous) {
        if (developerEmails.contains(user.email)) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DeveloperLogin()),
          );
        } else {
          // MainLoginPage로 이동
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainLoginPage()), // MainLoginPage로 변경된 페이지로 이동
          );
        }
      }
    }
  }

  // 로그인 상태 저장 메서드 추가
  Future<void> _saveLoginStatus(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async => false, // 뒤로 가기 버튼 방지
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 1.5,
                height: MediaQuery.of(context).size.height * 1.5,
                child: RiveAnimation.asset(
                  'assets/Rive/Robot.riv', // Rive 파일 경로
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  animations: ['Timeline 1'],
                ),
              ),
            ),
            Container(
              color: Colors.black.withOpacity(0.5),
            ),
            Positioned(
              left: MediaQuery.of(context).size.width * 0.1,
              top: MediaQuery.of(context).size.height * 0.15,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        'welcome_message'.tr(),
                        textStyle: TextStyle(
                          fontSize: 40.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        speed: Duration(milliseconds: 200),
                      ),
                    ],
                    repeatForever: true,
                    pause: Duration(milliseconds: 1000),
                    displayFullTextOnTap: true,
                    stopPauseOnTap: true,
                  ),
                ],
              ),
            ),
            Positioned(
              right: MediaQuery.of(context).size.width * 0.10,
              top: MediaQuery.of(context).size.height * 0.10,
              child: Image.asset(
                isDarkMode ? 'assets/logo/NBlogo.png' : 'assets/logo/NBlogo_black.png', // 다크 모드 여부에 따라 로고 변경
                height: 100,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _emailSignInButton(),
                  SizedBox(height: 16),
                  _signInButton(
                    'sign_in_with_google'.tr(),
                    'assets/logo/google_logo.png',
                    _signInWithGoogle,
                  ),
                  SizedBox(height: 16),
                  _signInButton(
                    'sign_in_with_facebook'.tr(),
                    'assets/logo/facebook_logo.png',
                    _showIncompleteFeatureDialog, // 페이스북 로그인 미완성 다이얼로그 호출
                  ),
                  SizedBox(height: 16),
                  _anonymousSignInButton(),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 이메일 로그인 버튼 클릭 시 MainLoginPage로 이동 처리
  void _signInWithEmail() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainLoginPage()), // MainLoginPage로 이동
    );
  }

  // 로딩 애니메이션 다이얼로그
  Future<void> _showLoadingAnimation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0);
        final borderColor = isDarkMode ? Colors.white : Colors.black;

        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: borderColor, width: 2),
          ),
          content: Container(
            width: 200,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150, // 애니메이션 너비 조정
                  height: 150, // 애니메이션 높이 조정
                  child: RiveAnimation.asset(
                    'assets/Rive/animgears.riv', // 로딩 애니메이션 파일 경로
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "logging_in".tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 성공 애니메이션
  Future<void> _showSuccessAnimation() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0);
        final borderColor = isDarkMode ? Colors.white : Colors.black;

        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: borderColor, width: 2),
          ),
          content: Container(
            width: 200,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150, // 애니메이션 너비 조정
                  height: 150, // 애니메이션 높이 조정
                  child: RiveAnimation.asset(
                    'assets/Rive/LoginSuccess.riv', // 성공 애니메이션 파일 경로
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "login_success".tr(),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
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

  // 로그인 실패 애니메이션
  Future<void> _showLoginFailedAnimation(String errorMessage) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0);
        final borderColor = isDarkMode ? Colors.white : Colors.black;

        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: borderColor, width: 2),
          ),
          content: Container(
            width: 200,
            height: 200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 150, // 애니메이션 너비 조정
                  height: 150, // 애니메이션 높이 조정
                  child: RiveAnimation.asset(
                    'assets/Rive/error_icon.riv', // 실패 애니메이션 파일 경로
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  errorMessage,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black),
                  textAlign: TextAlign.center,
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

  // 로그인 후 개발자 페이지 또는 메인 페이지로 이동
  void _navigateToAppropriatePage(User? user) {
    if (user != null && developerEmails.contains(user.email)) {
      _stopAnimationAndNavigate(DeveloperLogin());
    } else {
      // MainLoginPage로 이동 처리
      _stopAnimationAndNavigate(MainLoginPage());
    }
  }

  // 애니메이션 중단 및 페이지 이동
  void _stopAnimationAndNavigate(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        fullscreenDialog: true,
      ),
    ).then((_) {
      setState(() {});
    });
  }

  // 로그인 버튼 생성
  Widget _signInButton(String text, String asset, Function() onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
      ),
      onPressed: onPressed,
      icon: Image.asset(asset, height: 24),
      label: Text(text),
    );
  }

  // 익명 로그인 버튼
  Widget _anonymousSignInButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
      ),
      onPressed: _signInAnonymously,
      icon: Icon(Icons.person, color: Colors.black, size: 24), // 익명 로그인 아이콘
      label: Text('sign_in_anonymously'.tr()), // 번역된 텍스트로 변경
    );
  }

  // 이메일 로그인 버튼
  Widget _emailSignInButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: _signInWithEmail, // 버튼 클릭 시 MainLoginPage로 이동
      icon: Icon(Icons.email, color: Colors.black, size: 24),
      label: Text('sign_in_with_email'.tr()), // 번역된 텍스트로 변경
    );
  }

  // 구글 로그인
  Future<void> _signInWithGoogle() async {
    await _showLoadingAnimation();
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveLoginStatus(true);
        await _showSuccessAnimation();
        _navigateToAppropriatePage(userCredential.user);
      }
    } catch (e) {
      Navigator.of(context).pop();
      print(e);
      await _showLoginFailedAnimation("Google 로그인에 실패했습니다."); // 실패 애니메이션 호출
    }
  }

  // 익명 로그인 처리
  Future<void> _signInAnonymously() async {
    await _showLoadingAnimation();
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      if (userCredential.user != null) {
        await _showSuccessAnimation(); // 성공 애니메이션
        _stopAnimationAndNavigate(MainLoginPage()); // 익명 로그인 시 MainLoginPage로 이동
      }
    } catch (e) {
      Navigator.of(context).pop();
      print(e);
      await _showLoginFailedAnimation("익명 로그인에 실패했습니다. 다시 시도해 주세요."); // 실패 애니메이션 호출
    }
  }

  // 페이스북 로그인 미완성 다이얼로그 표시
  void _showIncompleteFeatureDialog() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0);
    final borderColor = isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: borderColor, width: 2),
          ),
          title: Text(
            "미완성 기능",
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          content: Text(
            "페이스북 로그인 기능이 아직 구현되지 않았습니다.",
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                "확인",
                style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}
