import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../LoginPage/LoginPage.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return WillPopScope(
      onWillPop: () async => false, // 뒤로 가기 버튼의 기본 동작을 막음
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          leading: Container(), // 뒤로 가기 버튼(화살표)을 제거
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (user != null) ...[
                Text(
                  'Email: ${user.email}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut(); // 로그아웃 수행
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    ); // LoginPage로 이동
                  },
                  child: const Text('Logout'),
                ),
              ] else
                const Text('No user is currently signed in.'),
            ],
          ),
        ),
      ),
    );
  }
}
