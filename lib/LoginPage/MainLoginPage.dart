import 'package:flutter/material.dart';
import 'RegisterPage.dart';
import '../components/MainLoginPageBackground.dart';

class MainLoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Background(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _buildHeaderText(),
            SizedBox(height: size.height * 0.03),
            _buildTextField("Username"),
            SizedBox(height: size.height * 0.03),
            _buildTextField("Password", obscureText: true),
            _buildForgotPasswordText(),
            SizedBox(height: size.height * 0.05),
            _buildLoginButton(size),
            _buildSignUpText(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderText() {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        "LOGIN",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF2661FA),
          fontSize: 36,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

  Widget _buildTextField(String labelText, {bool obscureText = false}) {
    return Container(
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: 40),
      child: TextField(
        decoration: InputDecoration(labelText: labelText),
        obscureText: obscureText,
      ),
    );
  }

  Widget _buildForgotPasswordText() {
    return Container(
      alignment: Alignment.centerRight,
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Text(
        "Forgot your password?",
        style: TextStyle(fontSize: 12, color: Color(0XFF2661FA)),
      ),
    );
  }

  Widget _buildLoginButton(Size size) {
    return Container(
      alignment: Alignment.centerRight,
      margin: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: ElevatedButton(
        onPressed: () {
          // Handle login button press
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
            "LOGIN",
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
