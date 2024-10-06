import 'package:flutter/material.dart';
import '../MainPage/MainPage.dart';
import '../LoginPage/ChangePassword.dart';
import '../LoginPage/LoginPage.dart';
import '../LoginPage/RegisterPage.dart';
import '../MainPage/MenuPage/ChatAI.dart';
import '../NewPage/FirstTutorial.dart';
import 'EmailLogin.dart';

void main() {
  runApp(MaterialApp(
    navigatorObservers: [DeveloperObserver()],
    home: DeveloperLogin(),
  ));
}

// 개발자 모드 플로팅 버튼 및 메뉴를 관리하는 Observer
class DeveloperObserver extends NavigatorObserver {
  static final DeveloperObserver _singleton = DeveloperObserver._internal();

  OverlayEntry? _overlayEntry;

  factory DeveloperObserver() {
    return _singleton;
  }

  DeveloperObserver._internal();

  void _addFloatingButton(BuildContext context) {
    if (_overlayEntry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _overlayEntry = _createOverlayEntry(context);
        Overlay.of(context)?.insert(_overlayEntry!);
      });
    }
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        right: 20, // 오른쪽 여백
        top: MediaQuery.of(context).size.height / 4, // 화면 높이의 1/4 위치에 배치
        child: FloatingActionButton(
          child: Icon(Icons.developer_mode),
          onPressed: () {
            _showDeveloperMenu(context);
          },
        ),
      ),
    );
  }

  void _showDeveloperMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView(
          children: [
            ListTile(
              leading: Icon(Icons.home),
              title: Text('HomeScreen'),
              onTap: () => _navigateToPage(context, SimpleBottomNavigation()),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('MainLoginPage'),
              onTap: () => _navigateToPage(context, MainLoginPage()),
            ),
            ListTile(
              leading: Icon(Icons.vpn_key),
              title: Text('ChangePassword'),
              onTap: () => _navigateToPage(context, ChangePassword()),
            ),
            ListTile(
              leading: Icon(Icons.login),
              title: Text('LoginPage'),
              onTap: () => _navigateToPage(context, LoginPage()),
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('RegisterScreen'),
              onTap: () => _navigateToPage(context, RegisterScreen()),
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('WelcomeScreen'),
              onTap: () => _navigateToPage(context, WelcomeScreen()),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    // Close the menu first
    Navigator.of(context).pop();
    // Push the new page
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is MaterialPageRoute) {
      _addFloatingButton(route.navigator!.context);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is MaterialPageRoute) {
      _removeFloatingButton();
      _addFloatingButton(route.navigator!.context);
    }
  }

  void _removeFloatingButton() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// 개발자 로그인 페이지 통합
class DeveloperLogin extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DeveloperObserver()._addFloatingButton(context); // 플로팅 버튼 추가
    return Scaffold(
      appBar: AppBar(
        title: Text('Developer Mode'),
      ),
      body: Center(
        child: Text(
          '개발자 모드에 오신 것을 환영합니다!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
