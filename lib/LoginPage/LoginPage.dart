import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_player/video_player.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:easy_localization/easy_localization.dart'; // 번역 패키지 추가
import 'EmailLogin.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  late VideoPlayerController _controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo(); // 페이지 로드 시 비디오 초기화 및 재생
  }

  void _initializeVideo() {
    _controller = VideoPlayerController.asset("assets/Video/TechPicks.mp4")
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _controller.setLooping(true);
        });
      });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose(); // 페이지 나갈 때 비디오 해제
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.value.isPlaying) {
        _controller.play(); // 앱이 다시 활성화될 때 비디오 재생
      }
    } else if (state == AppLifecycleState.paused) {
      if (_controller.value.isPlaying) {
        _controller.pause(); // 앱이 백그라운드로 전환될 때 비디오 일시정지
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller),
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
                      'welcome_message'.tr(), // 번역된 텍스트로 변경
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
          // 오른쪽 상단에 로고
          Positioned(
            right: MediaQuery.of(context).size.width * 0.10,
            top: MediaQuery.of(context).size.height * 0.10,
            child: Image.asset(
              'assets/logo/NBlogo.png', // 로고 경로 수정
              height: 100, // 크기 조정
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
                  'sign_in_with_google'.tr(), // 번역된 텍스트로 변경
                  'assets/logo/google_logo.png',
                  _signInWithGoogle,
                ),
                SizedBox(height: 16),
                _signInButton(
                  'sign_in_with_facebook'.tr(), // 번역된 텍스트로 변경
                  'assets/logo/facebook_logo.png',
                      () {
                    // 페이스북 로그인 작업
                  },
                ),
                SizedBox(height: 16),
                _signInButton(
                  'sign_in_with_apple'.tr(), // 번역된 텍스트로 변경
                  'assets/logo/apple_logo.png',
                      () {
                    // 애플 로그인 작업
                  },
                ),
                SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _stopVideoAndNavigate(Widget page) {
    _controller.pause(); // 탐색하기 전 비디오 일시 정지
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        fullscreenDialog: true,
      ),
    ).then((_) {
      if (!_controller.value.isPlaying) {
        _controller.play(); // 페이지로 돌아올 때 비디오 재생
      }
    });
  }

  void _signInWithEmail() {
    _stopVideoAndNavigate(MainLoginPage());
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth =
      await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _stopVideoAndNavigate(MainLoginPage());
      }
    } catch (e) {
      print(e); // 에러 처리
    }
  }

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

  Widget _emailSignInButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      onPressed: _signInWithEmail,
      icon: Icon(Icons.email, color: Colors.black, size: 24),
      label: Text('sign_in_with_email'.tr()), // 번역된 텍스트로 변경
    );
  }
}
