import 'package:flutter/material.dart';

class SecondTutorial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Tutorial'),
      ),
      body: Center(
        child: Text(
          '이곳은 두 번째 튜토리얼 화면입니다.',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
