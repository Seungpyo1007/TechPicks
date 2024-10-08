import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({Key? key}) : super(key: key);

  @override
  _PhoneScreenState createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _requestPermission(); // 권한 요청
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // 웹 페이지 로드가 완료된 후 JavaScript 실행
            _controller.runJavaScript(
                """
              // nav-container 및 premain-container 요소 삭제
              var navContainer = document.querySelector('.nav-container'); 
              if (navContainer) { 
                navContainer.remove(); 
              }

              var premainContainer = document.querySelector('.premain-container'); 
              if (premainContainer) { 
                premainContainer.remove(); 
              }

              // mt 클래스 요소 삭제
              var mtElements = document.querySelectorAll('.mt'); 
              mtElements.forEach(function(element) {
                element.remove();
              });

              // margin-top: 42px 제거
              document.body.style.marginTop = '0px';
              """
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('https://nanoreview.net/en/phone-list/antutu-rating'));
  }

  Future<void> _requestPermission() async {
    var status = await Permission.location.status;

    if (status.isGranted) {
      print("위치 권한이 허용되었습니다.");
    } else if (status.isDenied) {
      if (await Permission.location.request().isGranted) {
        print("위치 권한이 허용되었습니다.");
      } else {
        print("위치 권한이 거부되었습니다.");
        _showPermissionDialog();
      }
    } else if (status.isPermanentlyDenied) {
      print("위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.");
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('권한 요청'),
          content: Text('이 앱은 위치 접근 권한이 필요합니다. 설정으로 이동하여 권한을 허용해주세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings(); // 앱 설정 열기
              },
              child: Text('설정으로 이동'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 배경색을 검정색으로 설정
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
