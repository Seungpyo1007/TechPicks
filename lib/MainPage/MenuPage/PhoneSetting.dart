import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneSetting extends StatefulWidget {
  const PhoneSetting({Key? key}) : super(key: key);

  @override
  _PhoneSettingState createState() => _PhoneSettingState();
}

class _PhoneSettingState extends State<PhoneSetting> {
  late Future<String> deviceModelFuture;
  TextEditingController _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    deviceModelFuture = Future.value(''); // 초기에는 빈 Future로 설정
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    deviceModelFuture = _loadDeviceInfo(); // context가 초기화된 후 안전하게 Future를 설정
  }

  Future<String> _loadDeviceInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String deviceModel = 'Unknown Device'; // 초기값 설정

    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        // Android 기기 정보 가져오기
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        String brand = androidInfo.brand ?? '';
        String model = androidInfo.model ?? '';
        deviceModel = '$brand $model'.trim(); // 기종명: 브랜드와 모델명 조합
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        // iOS 기기 정보 가져오기
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.name ?? 'Unknown iPhone'; // iOS 기기 이름 사용
      }
    } catch (e) {
      // 오류 처리
      print('Failed to get device info: $e');
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedNickname = prefs.getString('phone_nickname');
    _nicknameController.text = savedNickname ?? deviceModel; // 저장된 별명 또는 기본 기종명을 사용

    return deviceModel;
  }

  Future<void> _saveNickname() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone_nickname', _nicknameController.text);
    Navigator.pop(context, _nicknameController.text); // 이전 화면으로 별명 데이터 전달
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('핸드폰 설정'),
      ),
      body: FutureBuilder<String>(
        future: deviceModelFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No device information available.'));
          }

          final deviceModel = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('당신의 핸드폰 기종은 $deviceModel 입니다.'),
                const SizedBox(height: 20),
                TextField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: '핸드폰 별명을 설정하시오',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveNickname,
                  child: Text('저장'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
