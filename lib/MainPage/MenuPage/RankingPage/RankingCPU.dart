import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class RankingCPUScreen extends StatefulWidget {
  const RankingCPUScreen({Key? key}) : super(key: key);

  @override
  _RankingCPUScreenState createState() => _RankingCPUScreenState();
}

class _RankingCPUScreenState extends State<RankingCPUScreen> {
  late final WebViewController _controller;
  bool _isLoading = true; // 로딩 상태 변수

  @override
  void initState() {
    super.initState();
    _requestPermission(); // 권한 요청

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // 페이지 로드가 시작되면 로딩 상태 활성화
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            // 웹 페이지 로드가 완료된 후 로딩 상태 비활성화
            _controller.runJavaScript(
                """
              // 불필요한 요소 삭제
              var navContainer = document.querySelector('.nav-container'); 
              if (navContainer) { 
                navContainer.remove(); 
              }

              var premainContainer = document.querySelector('.premain-container'); 
              if (premainContainer) { 
                premainContainer.remove(); 
              }

              var mtElements = document.querySelectorAll('.mt'); 
              mtElements.forEach(function(element) {
                element.remove();
              });

              // margin-top: 42px 제거
              document.body.style.marginTop = '0px';
              """
            ).then((_) {
              // JavaScript 실행이 완료되면 로딩 상태 비활성화
              setState(() {
                _isLoading = false;
              });
            });
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
      appBar: AppBar(
        title: const Text('Ranking CPU'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // 웹뷰 로딩 중에는 로딩 인디케이터 표시
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          // 로딩이 끝나면 웹뷰를 표시
          if (!_isLoading)
            SafeArea(
              child: WebViewWidget(controller: _controller),
            ),
        ],
      ),
    );
  }
}
