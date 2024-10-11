import 'package:flutter/material.dart';
import 'package:rive/rive.dart'; // Rive 패키지 임포트
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

// SecondTutorial 클래스 정의
class SecondTutorial extends StatefulWidget {
  @override
  _SecondTutorialState createState() => _SecondTutorialState();
}

class _SecondTutorialState extends State<SecondTutorial> {
  late RiveAnimationController _controller;
  int _currentStep = 0; // 현재 설명 단계

  // 튜토리얼 제목과 설명 리스트
  List<String> _tutorialTitles = ['CPU', 'PHONE', 'LAPTOP', 'PROFILE', '튜토리얼 완료'];
  List<String> _tutorialDescriptions = [
    'CPU는 컴퓨터에서 연산이 가능한 부품입니다. 컴퓨터의 두뇌 역할을 하며, 성능이 좋을수록 빠른 속도로 작업을 처리할 수 있습니다.',
    '현재 전세계 스마트폰의 랭킹 TOP 10을 알 수 있습니다.\n이를 통해 성능이 좋은 폰을 원하시는 분들께 도움이 될 수 있습니다.',
    '현재 전세계 노트북의 랭킹 TOP 10을 알 수 있습니다.\n2024 노트북의 세계 랭킹을 통해 최신 노트북 성능을 확인하세요.',
    '당신의 스마트폰의 기종과 계정 정보, 언어, 화면 모드 등 각종 정보를 확인할 수 있습니다.',
    '튜토리얼이 끝났습니다, 로그인 페이지로 넘어가는 중...'
  ];

  @override
  void initState() {
    super.initState();
    _controller = OneShotAnimation(
      'idle',
      autoplay: true,
    );
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
      if (_currentStep == _tutorialTitles.length - 1) {
        _controller.isActive = true; // 애니메이션 실행
        // 2초 후 LoginPage로 이동
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                // 현재 단계에 맞는 제목 표시
                Text(
                  _tutorialTitles[_currentStep],
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 20),
                // 현재 단계에 맞는 설명 표시
                Text(
                  _tutorialDescriptions[_currentStep],
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
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: ElevatedButton(
              onPressed: _currentStep < _tutorialTitles.length - 1 ? _nextStep : null, // 마지막 단계에서는 비활성화
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
