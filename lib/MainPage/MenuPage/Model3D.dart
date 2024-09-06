import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class Model3DScreen extends StatefulWidget {
  const Model3DScreen({Key? key}) : super(key: key);

  @override
  _Model3DScreenState createState() => _Model3DScreenState();
}

class _Model3DScreenState extends State<Model3DScreen> {
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
            // 웹 페이지 로드가 완료된 후 JavaScript 실행
            _controller.runJavaScript(
                """
                // 3D 모델 전체 화면 버튼 클릭 시뮬레이션
                var fullScreenButton = document.querySelector("button[title='Full screen']");
                if (fullScreenButton) {
                  fullScreenButton.click();
                }
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
      ..loadRequest(Uri.parse('https://www.gsmarena.com/samsung_galaxy_z_fold6-pictures-13147.php'));
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
      backgroundColor: Colors.white, // 배경색을 설정
      appBar: AppBar(
        title: const Text('Model 3D'),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          // 웹뷰 로딩 중에는 로딩 인디케이터 표시
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Colors.black,
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
