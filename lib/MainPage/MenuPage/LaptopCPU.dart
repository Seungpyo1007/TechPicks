import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LaptopCPUScreen extends StatefulWidget {
  const LaptopCPUScreen({Key? key}) : super(key: key);

  @override
  _LaptopCPUScreenState createState() => _LaptopCPUScreenState();
}

class _LaptopCPUScreenState extends State<LaptopCPUScreen> {
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
              // nav-container 요소 제거
              var navbar = document.querySelector('.nav-container'); 
              if (navbar) { 
                navbar.remove(); 
              }

              // premain-container 요소 제거
              var premain = document.querySelector('.premain-container');
              if (premain) { 
                premain.remove(); 
              }

              // 페이지의 여백을 제거하여 빈 공간을 채움
              document.body.style.marginTop = '0px';
              document.body.style.paddingTop = '0px';

              // 특정 요소의 여백을 제거하여 상단 공간을 줄임
              var mainContent = document.querySelector('.main-content'); // 이 부분은 주요 컨텐츠의 클래스명으로 변경
              if (mainContent) {
                mainContent.style.marginTop = '0px';
                mainContent.style.paddingTop = '0px';
              }
              """,
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('https://nanoreview.net/en/cpu-list/laptop-chips-rating'));
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
