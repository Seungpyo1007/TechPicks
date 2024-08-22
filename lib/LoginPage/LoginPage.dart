import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/Video/backgroundVideo.mp4")
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _controller.setLooping(true); // 비디오 반복 재생 설정
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(_controller),
          Container(
            color: Colors.black.withOpacity(0.5), // 영상 위에 반투명 블랙 오버레이
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: 100), // 여기를 조정해서 버튼들을 더 위로 올립니다.
                _emailSignInButton(), // 이메일 버튼을 첫 번째로 배치
                SizedBox(height: 16),
                _signInButton(
                  'Sign in with Google',
                  'assets/logo/google_logo.png', // Add your Google logo asset here
                      () {
                    // Handle Google sign-in
                  },
                ),
                SizedBox(height: 16),
                _signInButton(
                  'Sign in with Facebook',
                  'assets/logo/facebook_logo.png', // Add your Facebook logo asset here
                      () {
                    // Handle Facebook sign-in
                  },
                ),
                SizedBox(height: 16),
                _signInButton(
                  'Sign in with Apple',
                  'assets/logo/`    apple_logo.png', // Add your Apple logo asset here
                      () {
                    // Handle Apple sign-in
                  },
                ),
                SizedBox(height: 50), // 하단에도 약간의 여백 추가 (원하는 대로 조정 가능)
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _signInButton(String text, String asset, Function() onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        backgroundColor: Colors.grey[200], // Update here
        foregroundColor: Colors.black, // Update here
      ),
      onPressed: onPressed,
      icon: Image.asset(asset, height: 24), // Add your logo asset here
      label: Text(text),
    );
  }

  Widget _emailSignInButton() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
      ),
      onPressed: () {
        // Handle email sign-in
      },
      icon: Icon(Icons.email),
      label: Text('Sign in with email'),
    );
  }
}
