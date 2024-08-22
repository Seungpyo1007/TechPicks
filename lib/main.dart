import 'package:flutter/material.dart';
import 'LoginPage/LoginPage.dart';  // LoginPage 폴더 안의 LoginPage.dart를 임포트

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginPage(),  // 앱 시작 시 LoginPage로 이동
    );
  }
}
