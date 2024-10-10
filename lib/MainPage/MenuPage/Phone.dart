import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as flutter_image; // flutter Image에 대한 별칭
import 'package:easy_localization/easy_localization.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:rive/rive.dart' as rive_image; // rive Image에 대한 별칭
import 'scan.dart'; // Scan.dart 파일을 불러옵니다.

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({Key? key}) : super(key: key);

  @override
  _PhoneScreenState createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  int selectedIndex = 0;

  final List<Map<String, dynamic>> phoneDetails = [
    {
      'title': 'phone_details.samsung_galaxy_s24_ultra',
      'image': 'https://fdn2.gsmarena.com/vv/pics/samsung/samsung-galaxy-s24-ultra-5g-sm-s928-0.jpg',
      'screen': '6.8" Dynamic LTPO AMOLED 2X',
      'soc': 'Qualcomm Snapdragon 8 Gen 3',
      'main_camera': '4(200MP+10MP+50MP+12MP)',
      'battery': '5000mAh - 45W',
      'os': 'Android 14',
      'weight': '232 g or 233 g (8.18 oz)',
      'ratings': {'performance': 90, 'camera': 85, 'display': 93, 'battery': 80, 'features': 75}
    },
    {
      'title': 'phone_details.apple_iphone_16_pro_max',
      'image': 'https://fdn2.gsmarena.com/vv/pics/apple/apple-iphone-16-pro-max-1.jpg',
      'screen': '6.9" LTPO Super Retina XDR OLED',
      'soc': 'Apple A18 Pro (3 nm)',
      'main_camera': '3(48MP+12MP+48MP)',
      'battery': '4685mAh - 27W',
      'os': 'iOS 18',
      'weight': '227 g (8.01 oz)',
      'ratings': {'performance': 95, 'camera': 90, 'display': 95, 'battery': 78, 'features': 80}
    },
    {
      'title': 'phone_details.google_pixel_9_pro_xl',
      'image': 'https://fdn2.gsmarena.com/vv/pics/google/google-pixel-9-pro-xl-1.jpg',
      'screen': '6.8" LTPO OLED - 1344 x 2992',
      'soc': 'Google Tensor G4 (4 nm)',
      'main_camera': '3(50MP+48MP+48MP)',
      'battery': '5060mAh - 37W',
      'os': 'Android 14',
      'weight': '221 g (7.80 oz)',
      'ratings': {'performance': 85, 'camera': 78, 'display': 88, 'battery': 82, 'features': 72}
    },
    {
      'title': 'phone_details.samsung_galaxy_z_fold6',
      'image': 'https://fdn2.gsmarena.com/vv/pics/samsung/samsung-galaxy-z-fold6-2.jpg',
      'screen': '7.6" Foldable Dynamic LTPO AMOLED 2X',
      'soc': 'Qualcomm Snapdragon 8 Gen 3',
      'main_camera': '3(50MP+10MP+12MP)',
      'battery': '4400mAh - 25W',
      'os': 'Android 14',
      'weight': '239 g (8.43 oz)',
      'ratings': {'performance': 86, 'camera': 81, 'display': 87, 'battery': 75, 'features': 78}
    },
    {
      'title': 'phone_details.huawei_mate_xt_ultimate',
      'image': 'https://fdn2.gsmarena.com/vv/pics/huawei/huawei-mate-xt-ultimate-4.jpg',
      'screen': '10.2" Tri-foldable LTPO OLED',
      'soc': 'Kirin 9010 (7 nm)',
      'main_camera': '3(50MP+12MP+12MP)',
      'battery': '5600mAh - 66W',
      'os': 'HarmonyOS 4.2',
      'weight': '298 g (10.51 oz)',
      'ratings': {'performance': 88, 'camera': 83, 'display': 91, 'battery': 85, 'features': 80}
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? const Color(0xFF222222) : const Color(0xFFE0E0E0);
    final containerColor = isDarkMode ? const Color(0xFF333333) : const Color(0xFFEEEEEE);
    final listTileColor = isDarkMode ? const Color(0xFF444444) : const Color(0xFFF5F5F5);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final highlightColor = isDarkMode ? const Color(0xFFDDA0DD) : const Color(0xFF800080);

    final selectedPhone = phoneDetails[selectedIndex];

    // 방사형 차트를 위한 데이터 생성
    List<ChartData> chartData = [
      ChartData('성능', selectedPhone['ratings']['performance'].toDouble(), Colors.blue),
      ChartData('카메라', selectedPhone['ratings']['camera'].toDouble(), Colors.green),
      ChartData('화면', selectedPhone['ratings']['display'].toDouble(), Colors.orange),
      ChartData('배터리', selectedPhone['ratings']['battery'].toDouble(), Colors.purple),
      ChartData('특징', selectedPhone['ratings']['features'].toDouble(), Colors.red),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text(
              tr('selected_by_techpicks_top_5_flagship_latest_phones'),
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 250,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListView.builder(
                itemCount: phoneDetails.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    child: _buildListTile(
                      '${index + 1}  ${tr(phoneDetails[index]['title']!)}',
                      index == selectedIndex ? highlightColor : textColor,
                      listTileColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(selectedPhone['title'] ?? ''),
                    style: TextStyle(
                      color: highlightColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        flutter_image.Image.network(
                          selectedPhone['image'] ?? '',
                          height: 100,
                          width: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: textColor,
                            );
                          },
                        ),
                        const SizedBox(width: 16.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailText('${tr("phone_details.screen")}: ${selectedPhone['screen']}', textColor),
                            _buildDetailText('${tr("phone_details.soc")}: ${selectedPhone['soc']}', textColor),
                            _buildDetailText('${tr("phone_details.main_camera")}: ${selectedPhone['main_camera']}', textColor),
                            _buildDetailText('${tr("phone_details.battery")}: ${selectedPhone['battery']}', textColor),
                            _buildDetailText('${tr("phone_details.os")}: ${selectedPhone['os']}', textColor),
                            _buildDetailText('${tr("phone_details.weight")}: ${selectedPhone['weight']}', textColor),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Radial Bar Chart using Syncfusion Chart
                  Container(
                    height: 300,
                    child: SfCircularChart(
                      annotations: <CircularChartAnnotation>[
                        CircularChartAnnotation(
                          widget: Container(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.red, width: 4), // 기준 원을 명확하게 표시
                              ),
                            ),
                          ),
                        ),
                      ],
                      series: <CircularSeries>[
                        RadialBarSeries<ChartData, String>(
                          dataSource: chartData,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y,
                          pointColorMapper: (ChartData data, _) => data.color, // 항목별 색상 적용
                          dataLabelSettings: DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(color: textColor, fontSize: 12),
                          ),
                          cornerStyle: CornerStyle.bothCurve,
                          maximumValue: 100, // 최대 값 설정
                          radius: '100%',
                        ),
                      ],
                      legend: Legend(
                        isVisible: true,
                        position: LegendPosition.bottom, // 색상 표 위치 설정
                        textStyle: TextStyle(color: textColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            // Rive 애니메이션 추가 부분
            Container(
              height: 200,
              child: GestureDetector(
                onTap: () {
                  // 애니메이션 클릭 시 Scan.dart로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanPage()),
                  );
                },
                child: const rive_image.RiveAnimation.asset(
                  'assets/Rive/ocr_card.riv', // Rive 파일 경로
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(String title, Color textColor, Color tileColor) {
    return Container(
      color: tileColor,
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailText(String text, Color textColor) {
    return Text(
      text,
      style: TextStyle(color: textColor),
    );
  }
}

// 차트 데이터를 위한 클래스 정의
class ChartData {
  ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}
