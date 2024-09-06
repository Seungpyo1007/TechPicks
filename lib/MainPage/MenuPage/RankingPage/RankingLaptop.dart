import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class RankingLaptopScreen extends StatefulWidget {
  const RankingLaptopScreen({Key? key}) : super(key: key);

  @override
  _LaptopScreenState createState() => _LaptopScreenState();
}

class _LaptopScreenState extends State<RankingLaptopScreen> {
  late final WebViewController _controller;
  bool _isLoading = true; // 로딩 상태 변수 추가

  @override
  void initState() {
    super.initState();
    _requestPermission(); // 권한 요청
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // 페이지 로드가 완료된 후에도 검은 화면을 일정 시간 유지
            Future.delayed(const Duration(seconds: 5), () { // 검은 화면을 유지할 시간 설정
              setState(() {
                _isLoading = false; // 추가 지연 시간 후 로딩 상태를 false로 변경
              });
            });

            // 웹 페이지 로드가 완료된 후 JavaScript 실행
            _controller.runJavaScript(
                """
              // header 요소 삭제
              var header = document.querySelector('header'); 
              if (header) { 
                header.remove(); 
              }

              // 지정된 ID 요소 삭제
              var idsToRemove = ['c11844565', 'c11844564', 'c11844563', 'c11844562', 'c11844561', 'c11844560', 'c11844559', 'c11844558', 'c11844557', 'c11844556', 'c11844555', 'c11844554', 'c11844553', 'c11844552', 'c11844549'];
              idsToRemove.forEach(function(id) {
                var element = document.getElementById(id);
                if (element) {
                  element.remove();
                }
              });

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
      body: Stack(
        children: [
          if (!_isLoading) WebViewWidget(controller: _controller), // 로딩이 끝난 후 WebView 표시
          if (_isLoading)
            Container(
              color: Colors.black, // 검은 화면 유지
              child: Center(
                child: CircularProgressIndicator(), // 로딩 인디케이터 추가
              ),
            ),
        ],
      ),
    );
  }
}
