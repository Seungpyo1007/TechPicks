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
      ..loadRequest(Uri.parse('https://nanoreview.net/en/cpu-list/laptop-chips-rating'));
  }

  Future<void> _requestPermission() async {
    // 위치 권한 요청
    var status = await Permission.location.request();
    if (status.isGranted) {
      print("위치 권한이 허용되었습니다.");
    } else if (status.isDenied) {
      print("위치 권한이 거부되었습니다.");
    } else if (status.isPermanentlyDenied) {
      print("위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.");
      openAppSettings(); // 사용자가 설정에서 권한을 변경하도록 앱 설정 페이지를 엽니다.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Laptop Screen'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
