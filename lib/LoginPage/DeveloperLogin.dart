import 'package:flutter/material.dart';
import '../MainPage/MainPage.dart';

class DeveloperLogin extends StatefulWidget {
  @override
  _DeveloperLoginState createState() => _DeveloperLoginState();
}

class _DeveloperLoginState extends State<DeveloperLogin> {
  final TextEditingController _passwordController = TextEditingController();

  void _checkPassword() {
    if (_passwordController.text == '1007') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SimpleBottomNavigation()), // Navigate to MainPage
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect password')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Developer Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Enter Developer Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkPassword,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
