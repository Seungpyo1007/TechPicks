import 'package:flutter/material.dart';
import 'package:rive/rive.dart'; // Rive 패키지 임포트
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences 임포트
import '../Loading.dart'; // LoadingScreen 클래스 임포트
import 'SecondTutorial.dart'; // SecondTutorial 파일 임포트
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
      home: WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Rive Controller
  late RiveAnimationController _controller;
  bool _isPlayingSuccess = false;
  String _loadingText = '시작'; // 초기 텍스트 설정
  bool _tutorialEnded = false; // 튜토리얼이 끝났는지 여부
  late BuildContext dialogContext; // 안전한 BuildContext 저장

  @override
  void initState() {
    super.initState();
    // 초기 애니메이션 설정 (idle 애니메이션)
    _controller = OneShotAnimation(
      'idle',
      autoplay: true,
    );
  }

  // 애니메이션 전환 함수 및 로딩 시작 함수
  void _toggleAnimation() {
    setState(() {
      // 현재 애니메이션 상태에 따라 애니메이션 변경
      if (_isPlayingSuccess) {
        _controller = OneShotAnimation('Idle', autoplay: true);
      } else {
        _controller = OneShotAnimation('Turn-copy', autoplay: true);
      }
      _isPlayingSuccess = !_isPlayingSuccess;
      _loadingText = '첫 시작을 위해 로딩중...'; // 버튼 클릭 시 텍스트 변경
    });

    // 5초 후 SecondTutorial 화면으로 이동
    Future.delayed(Duration(seconds: 5), () {
      if (mounted) { // BuildContext가 유효한지 확인
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SecondTutorial()),
        );
      }
    });
  }

  // "괜찮아요"를 클릭하면 경고창을 표시
  void _showConfirmationDialog() {
    // 다크 모드 여부에 따라 색상 설정
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0);
    final borderColor = isDarkMode ? Colors.white : Colors.black;

    // 안전한 BuildContext 저장
    dialogContext = context;
    showDialog(
      context: dialogContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor, // 다크 모드에 따라 배경색 설정
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
            side: BorderSide(color: borderColor, width: 2.0), // 다크 모드에 따라 테두리 색상 설정
          ),
          title: Text(
            "정말 괜찮겠습니까?",
            style: TextStyle(color: borderColor), // 다크 모드에 따라 텍스트 색상 설정
          ),
          content: Text(
            "튜토리얼을 건너뛰면 다시 볼 수 없습니다. 괜찮으신가요?",
            style: TextStyle(color: borderColor), // 다크 모드에 따라 텍스트 색상 설정
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (mounted) { // BuildContext가 유효한지 확인 후 Navigator 호출
                  Navigator.of(dialogContext).pop(); // 경고창 닫기
                }
              },
              child: Text("아니요", style: TextStyle(color: borderColor)), // 다크 모드에 따라 텍스트 색상 설정
            ),
            TextButton(
              onPressed: () async {
                // 튜토리얼 종료 설정 및 SharedPreferences에 저장
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_tutorial_completed', true);

                setState(() {
                  _tutorialEnded = true;
                  _loadingText = '튜토리얼이 종료되었습니다.'; // 튜토리얼 종료 텍스트 설정
                });
                if (mounted) { // BuildContext가 유효한지 확인 후 Navigator 호출
                  Navigator.of(dialogContext).pop(); // 경고창 닫기
                }

                // 3초 후 LoadingScreen으로 이동
                Future.delayed(Duration(seconds: 3), () {
                  if (!mounted) return; // BuildContext가 유효하지 않으면 리턴
                  Navigator.push(
                    dialogContext,
                    MaterialPageRoute(builder: (context) => const LoadingScreen()),
                  );

                  // LoadingScreen에서 3초 대기 후 LoginPage로 이동
                  Future.delayed(Duration(seconds: 3), () {
                    if (!mounted) return; // BuildContext가 유효하지 않으면 리턴
                    Navigator.pushReplacement(
                      dialogContext,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  });
                });
              },
              child: Text("예", style: TextStyle(color: borderColor)), // 다크 모드에 따라 텍스트 색상 설정
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 여부에 따라 배경 및 텍스트 색상 설정
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0);
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor, // 설정한 배경색 사용
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Column(
              children: [
                Text(
                  '환영합니다!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor, // 텍스트 색상 설정
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'TECHPICKS에 오신것을 환영해요!\n사용하시기전에 앱 이용에 도움이 될\n튜토리얼을 시작하겠습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor, // 텍스트 색상 설정
                  ),
                ),
              ],
            ),
          ),
          Spacer(), // 애니메이션을 화면 중앙 근처로 밀어내기 위한 Spacer
          Center(
            child: Container(
              height: 300, // Rive 애니메이션의 높이 설정
              child: RiveAnimation.asset(
                'assets/Rive/laptop_turns.riv', // Rive 파일 경로
                fit: BoxFit.contain,
                alignment: Alignment.center, // 애니메이션을 화면 가운데 정렬
                controllers: [_controller],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              _tutorialEnded ? _loadingText : _loadingText, // 상태에 따라 텍스트 변경
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          SizedBox(height: 20), // 애니메이션과 버튼 사이의 간격을 조정
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: ElevatedButton(
              onPressed: _toggleAnimation, // 버튼 클릭 시 애니메이션 변경 및 로딩 시작
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
                shape: CircleBorder(),
                padding: EdgeInsets.all(20), // 버튼 패딩 설정
              ),
              child: Icon(Icons.arrow_forward, color: Colors.black),
            ),
          ),
          Spacer(), // 버튼을 아래로 밀어내기 위한 Spacer
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 30.0), // 왼쪽에 "괜찮아요" 텍스트 위치를 고정
            child: Align(
              alignment: Alignment.bottomLeft, // "괜찮아요" 텍스트를 화면 하단 왼쪽에 정렬
              child: GestureDetector(
                onTap: _showConfirmationDialog, // "괜찮아요" 텍스트를 클릭 시 경고창 표시
                child: Text(
                  '< 괜찮아요',
                  style: TextStyle(
                    fontSize: 18,
                    color: textColor, // 텍스트 색상 설정
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
