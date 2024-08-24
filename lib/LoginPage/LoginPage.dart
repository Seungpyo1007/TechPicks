import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_player/video_player.dart';
import 'MainLoginPage.dart'; // MainLoginPage import 추가

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late VideoPlayerController _controller;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset("assets/Video/backgroundVideo.mp4")
      ..initialize().then((_) {
        setState(() {
          _controller.play();
          _controller.setLooping(true);
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
            color: Colors.black.withOpacity(0.5),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(height: 100),
                _emailSignInButton(),
                SizedBox(height: 16),
                _signInButton(
                  'Sign in with Google',
                  'assets/logo/google_logo.png',
                  _signInWithGoogle,
                ),
                SizedBox(height: 16),
                _signInButton(
                  'Sign in with Facebook',
                  'assets/logo/facebook_logo.png',
                      () {
                    // 페이스북 로그인 버튼 클릭 시 동작을 여기에 추가하거나 비워둡니다.
                  },
                ),
                SizedBox(height: 16),
                _signInButton(
                  'Sign in with Apple',
                  'assets/logo/apple_logo.png',
                      () {
                    // 애플 로그인 버튼 클릭 시 동작을 여기에 추가하거나 비워둡니다.
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

  void _signInWithEmail() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MainLoginPage()),
    );
  }

  // Google 로그인
  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      // 로그인 성공 처리
    } catch (e) {
      // 오류 처리
      print(e);
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
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
      ),
      onPressed: _signInWithEmail,
      icon: Icon(Icons.email),
      label: Text('Sign in with email'),
    );
  }
}
