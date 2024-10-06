import 'package:flutter/material.dart';
import 'package:rive/rive.dart'; // Rive 패키지 임포트
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 임포트
import '../Loading.dart'; // LoadingScreen 클래스 임포트
import '../LoginPage/LoginPage.dart'; // LoginPage 파일 임포트

void main() {
  runApp(TechPicksApp());
}

class TechPicksApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(), // 라이트 모드 테마
      darkTheme: ThemeData.dark(), // 다크 모드 테마
      themeMode: ThemeMode.system, // 시스템 테마 모드에 따라 변경
      home: SecondTutorial(), // 기본 화면을 SecondTutorial로 설정
    );
  }
}

// SecondTutorial 클래스 정의 - WelcomeScreen의 디자인을 복사하여 사용
class SecondTutorial extends StatefulWidget {
  @override
  _SecondTutorialState createState() => _SecondTutorialState();
}

class _SecondTutorialState extends State<SecondTutorial> {
  // Rive Controller
  late RiveAnimationController _controller;
  String _secondTutorialText = '두 번째 튜토리얼을 시작합니다.';
  bool _isPlayingSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = OneShotAnimation(
      'idle',
      autoplay: true,
    );
  }

  void _startSecondTutorial() {
    setState(() {
      _secondTutorialText = '튜토리얼 진행 중...'; // 버튼 클릭 시 텍스트 변경
      _controller.isActive = true;
    });

    // 5초 후 LoginPage로 이동
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 여부에 따라 배경 및 텍스트 색상 설정
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Column(
              children: [
                Text(
                  '두 번째 튜토리얼',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  _secondTutorialText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          Spacer(),
          Center(
            child: Container(
              height: 300,
              child: RiveAnimation.asset(
                'assets/Rive/laptop_turns.riv',
                fit: BoxFit.contain,
                alignment: Alignment.center,
                controllers: [_controller],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              _secondTutorialText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: ElevatedButton(
              onPressed: _startSecondTutorial,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: CircleBorder(),
                padding: EdgeInsets.all(20),
              ),
              child: Icon(Icons.arrow_forward, color: Colors.black),
            ),
          ),
          Spacer(),
        ],
      ),
    );
  }
}
