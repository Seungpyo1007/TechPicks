import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class CPUScreen extends StatefulWidget {
  const CPUScreen({Key? key}) : super(key: key);

  @override
  _CPUScreenState createState() => _CPUScreenState();
}

class _CPUScreenState extends State<CPUScreen> {
  late Future<Map<String, dynamic>> cpuInfoFuture;

  @override
  void initState() {
    super.initState();
    // CPU 정보를 가져오는 Future 초기화
    cpuInfoFuture = Future.value({}); // 초기에는 빈 Future로 설정
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // context가 안전하게 초기화된 이후에 CPU 정보를 가져옴
    cpuInfoFuture = _getCpuInfo();
  }

  Future<Map<String, dynamic>> _getCpuInfo() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> cpuInfo = {};

    try {
      // 플랫폼에 따라 다른 정보를 가져옴
      if (Theme.of(context).platform == TargetPlatform.android) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        cpuInfo = {
          'Brand': androidInfo.brand,
          'Device': androidInfo.device,
          'Hardware': androidInfo.hardware,
          'Model': androidInfo.model,
          'Product': androidInfo.product,
          'Supported ABIs': androidInfo.supportedAbis.join(', '),
        };
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        cpuInfo = {
          'Model': iosInfo.model,
          'System Name': iosInfo.systemName,
          'System Version': iosInfo.systemVersion,
          'Name': iosInfo.name,
          'Is Physical Device': iosInfo.isPhysicalDevice.toString(),
        };
      }
    } catch (e) {
      cpuInfo = {'Error': 'Failed to get CPU information: $e'};
    }

    return cpuInfo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CPU Information'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: cpuInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No CPU information available.'));
          }

          final cpuInfo = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: cpuInfo.entries.map((entry) {
              return ListTile(
                title: Text(entry.key),
                subtitle: Text(entry.value.toString()),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
