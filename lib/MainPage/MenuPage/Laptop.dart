import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LaptopScreen extends StatefulWidget {
  const LaptopScreen({Key? key}) : super(key: key);

  @override
  _LaptopScreenState createState() => _LaptopScreenState();
}

class _LaptopScreenState extends State<LaptopScreen> {
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
              // header 요소 삭제
              var header = document.querySelector('header'); 
              if (header) { 
                header.remove(); 
              }

              // 'The best laptops reviewed, summer 2024' 요소까지 이전의 모든 요소 삭제
              var targetElement = document.evaluate("//h2[contains(text(),'The best laptops reviewed, summer 2024')]", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
              if (targetElement) {
                var parent = targetElement.parentNode; // 부모 요소 가져오기
                var siblings = Array.from(parent.children); // 부모 요소의 자식들을 배열로 변환

                for (var i = 0; i < siblings.length; i++) {
                  if (siblings[i] === targetElement) break; // 대상 요소에 도달하면 중지
                  siblings[i].remove(); // 대상 요소 이전의 모든 형제 요소 삭제
                }
              }

              // 페이지의 여백을 제거하여 빈 공간을 채움
              document.body.style.marginTop = '0px';
              document.body.style.paddingTop = '0px';
              """
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('https://www.notebookcheck.net/The-best-laptops-of-summer-2024-61-reviewed-laptops-compared.882186.0.html'));
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
