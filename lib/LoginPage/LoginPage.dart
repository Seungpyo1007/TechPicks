import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:video_player/video_player.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
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
    _initializeVideo(); // Initialize and play video on page load
  }

  void _initializeVideo() {
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
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose(); // Dispose video when leaving the page
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!_controller.value.isPlaying) {
        _controller.play(); // Play video when app is resumed
      }
    } else if (state == AppLifecycleState.paused) {
      if (_controller.value.isPlaying) {
        _controller.pause(); // Pause video when app is in background
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
            top: MediaQuery.of(context).size.height * 0.15, // 글자 올리고 싶으면 이거 ㄱㄱㄱ
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      'TechPicks\nWelcome',
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
          // Positioned logo in the top right corner
          Positioned(
            right: MediaQuery.of(context).size.width * 0.10,
            top: MediaQuery.of(context).size.height * 0.10,
            child: Image.asset(
              'assets/logo/NBlogo.png', // Adjust the path to your logo
              height: 100, // Adjust the size as needed
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _emailSignInButton(), // Updated email sign-in button
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
                    // Placeholder for Facebook login action
                  },
                ),
                SizedBox(height: 16),
                _signInButton(
                  'Sign in with Apple',
                  'assets/logo/apple_logo.png',
                      () {
                    // Placeholder for Apple login action
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
    _controller.pause(); // Pause video before navigating
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => page,
        fullscreenDialog: true,
      ),
    ).then((_) {
      if (!_controller.value.isPlaying) {
        _controller.play(); // Resume video when returning to the page
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
      print(e); // Error handling
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
        backgroundColor: Colors.white, // White background color for email button
        foregroundColor: Colors.black,
      ),
      onPressed: _signInWithEmail,
      icon: Icon(Icons.email, color: Colors.black, size: 24), // Icon with black color
      label: Text('Sign in with email'),
    );
  }
}
