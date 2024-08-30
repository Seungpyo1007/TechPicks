import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino package
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth import
import '../MainPage/MainPage.dart';
import '../components/EmailLoginPageBackground.dart';
import 'RegisterPage.dart';
import 'DeveloperLogin.dart'; // Import DeveloperLogin page
import 'ChangePassword.dart'; // Import ChangePassword page

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
            _buildSegmentedControl(), // Fixed position for toggle control
            SizedBox(height: size.height * 0.03),
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300), // Duration for the animation
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: _buildContent(size, context), // Animated transition for content
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40.0), // Fix the toggle button position
      child: CupertinoSegmentedControl<int>(
        borderColor: Color(0xFF2661FA),
        selectedColor: Color(0xFF2661FA),
        unselectedColor: Colors.white,
        children: {
          0: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Login', style: TextStyle(fontSize: 14)), // Reduced font size
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Developer Login', style: TextStyle(fontSize: 14)), // Reduced font size
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
    // Decides which view to show based on the selected index
    if (_selectedIndex == 0) {
      return _buildLoginView(size, context);
    } else {
      return _buildDeveloperLoginView(context);
    }
  }

  Widget _buildLoginView(Size size, BuildContext context) {
    return Column(
      key: ValueKey(0), // Unique key for the AnimatedSwitcher
      children: [
        _buildHeaderText("LOGIN"),
        SizedBox(height: size.height * 0.03),
        _buildTextField("Email", controller: _emailController),
        SizedBox(height: size.height * 0.03),
        _buildTextField("Password", controller: _passwordController, obscureText: true),
        _buildForgotPasswordText(context), // Updated to include context for navigation
        SizedBox(height: size.height * 0.05),
        _buildLoginButton(size, context, "LOGIN"),
        _buildSignUpText(context),
      ],
    );
  }

  Widget _buildDeveloperLoginView(BuildContext context) {
    return Column(
      key: ValueKey(1), // Unique key for the AnimatedSwitcher
      children: [
        _buildHeaderText("DEVELOPER LOGIN"),
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
            MaterialPageRoute(builder: (context) => DeveloperLogin()), // Navigate to Developer Login page
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
            "DEVELOPER LOGIN",
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
            MaterialPageRoute(builder: (context) => ChangePassword()), // Navigate to ChangePassword page
          );
        },
        child: Text(
          "Forgot your password?",
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
          // Firebase Authentication login logic
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
            // Handle login failure
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$buttonText failed. Please try again.")),
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
          "Don't Have an Account? Sign up",
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
