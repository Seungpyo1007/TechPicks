import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'ChatAI.dart';
import 'Model3D.dart';
import 'RankingPage/RankingCPU.dart'; // RankingCPU 페이지 import
import 'RankingPage/RankingPhone.dart'; // RankingPhone 페이지 import
import 'RankingPage/RankingLaptop.dart'; // RankingLaptop 페이지 import

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 그라데이션 배경
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.blue], // 검정색에서 파란색으로 그라데이션
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 이미지 배너 영역
                  Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.transparent, // 배너를 투명하게 설정하여 배경색과 일치
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'together_technology'.tr(), // 번역된 텍스트로 변경
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'ranking list 2024'.tr() + ' ->', // 번역된 텍스트로 변경
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 서비스 아이콘 목록
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: GridView.count(
                      crossAxisCount: 4, // 한 줄에 4개의 아이콘
                      shrinkWrap: true, // GridView의 크기를 자식 위젯 크기로 맞춤
                      physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
                      children: [
                        GestureDetector(
                          onTap: () {
                            // CPU 아이콘 클릭 시 RankingCPU 페이지로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RankingCPUScreen()),
                            );
                          },
                          child: _buildServiceIcon(Icons.memory, 'cpu'.tr()),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Phone 아이콘 클릭 시 RankingPhone 페이지로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RankingPhoneScreen()),
                            );
                          },
                          child: _buildServiceIcon(Icons.phone_android, 'phone'.tr()), // 번역된 텍스트로 변경
                        ),
                        _buildServiceIcon(Icons.newspaper_rounded, 'news'.tr()), // 번역된 텍스트로 변경
                        _buildServiceIcon(Icons.event, 'reserve'.tr()), // 번역된 텍스트로 변경
                        GestureDetector(
                          onTap: () {
                            // Laptop 아이콘 클릭 시 RankingLaptop 페이지로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RankingLaptopScreen()),
                            );
                          },
                          child: _buildServiceIcon(Icons.laptop, 'laptop'.tr()), // 번역된 텍스트로 변경
                        ),
                        _buildServiceIcon(Icons.person_outline, 'profile'.tr()), // 번역된 텍스트로 변경
                        _buildServiceIcon(Icons.more_horiz, 'more'.tr()), // 번역된 텍스트로 변경
                        _buildServiceIcon(Icons.star, 'bookmarks'.tr()), // 번역된 텍스트로 변경
                      ],
                    ),
                  ),

                  // 검색창
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.black),
                        hintText: 'where_to'.tr(), // 번역된 텍스트로 변경
                        hintStyle: TextStyle(color: Colors.black), // 힌트 텍스트 색상 변경
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      style: TextStyle(color: Colors.black), // 입력 텍스트 색상 변경
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 옵션 리스트
                  ListTile(
                    leading: const Icon(Icons.star, color: Colors.white),
                    title: Text('choose_bookmark'.tr(), // 번역된 텍스트로 변경
                        style: TextStyle(color: Colors.white)), // 텍스트 색상 변경
                  ),
                  ListTile(
                    leading: const Icon(Icons.map, color: Colors.white),
                    title: Text('set_destination_on_map'.tr(), // 번역된 텍스트로 변경
                        style: TextStyle(color: Colors.white)), // 텍스트 색상 변경
                  ),
                  const Divider(color: Colors.white), // 구분선 색상 변경

                  // 주변 정보 텍스트
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('around_you'.tr(), // 번역된 텍스트로 변경
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white)), // 텍스트 색상 변경
                    ),
                  ),

                  // 6개의 버튼 추가
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: GridView.count(
                      crossAxisCount: 3, // 한 줄에 3개의 아이콘
                      shrinkWrap: true, // GridView의 크기를 자식 위젯 크기로 맞춤
                      physics: NeverScrollableScrollPhysics(), // 스크롤 비활성화
                      children: [
                        GestureDetector(
                          onTap: () {
                            // button1 클릭 시 Model3D 페이지로 이동
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const Model3DScreen()),
                            );
                          },
                          child: _buildServiceIcon(Icons.map, 'button1'.tr()),
                        ),
                        _buildServiceIcon(Icons.camera, 'button2'.tr()), // 버튼 2
                        _buildServiceIcon(Icons.shopping_cart, 'button3'.tr()), // 버튼 3
                        _buildServiceIcon(Icons.directions_car, 'button4'.tr()), // 버튼 4
                        _buildServiceIcon(Icons.flight, 'button5'.tr()), // 버튼 5
                        _buildServiceIcon(Icons.restaurant, 'button6'.tr()), // 버튼 6
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ChatAIScreen()),
                            );
                          },
                          child: _buildServiceIcon(Icons.restaurant, 'button6'.tr()),
                        ),

                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceIcon(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 35, // 아이콘 크기 증가
          backgroundColor: Colors.grey[200],
          child: Icon(icon, size: 30, color: Colors.black), // 아이콘 크기 증가
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white), // 텍스트 색상 변경
        ),
      ],
    );
  }
}
