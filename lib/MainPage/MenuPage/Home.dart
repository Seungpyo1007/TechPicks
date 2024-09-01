import 'package:flutter/material.dart';

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
                          'Get out and about',
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
                              'Together Technology ->',
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
                      _buildServiceIcon(Icons.memory, 'CPU'),
                      _buildServiceIcon(Icons.phone_android, 'Phone'),
                      _buildServiceIcon(Icons.newspaper_rounded, 'News'),
                      _buildServiceIcon(Icons.event, 'Reserve'),
                      _buildServiceIcon(Icons.laptop, 'Laptop'),
                      _buildServiceIcon(Icons.person_outline, 'Profile'),
                      _buildServiceIcon(Icons.more_horiz, 'More'),
                      _buildServiceIcon(Icons.star, 'Bookmarks'),
                    ],
                  ),
                ),

                // 검색창
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      hintText: 'Where to?',
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
                  title: const Text('Choose a Bookmark',
                      style: TextStyle(color: Colors.white)), // 텍스트 색상 변경
                ),
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.white),
                  title: const Text('Set destination on map',
                      style: TextStyle(color: Colors.white)), // 텍스트 색상 변경
                ),
                const Divider(color: Colors.white), // 구분선 색상 변경

                // 주변 정보 텍스트
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Around you',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)), // 텍스트 색상 변경
                  ),
                ),
              ],
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

void main() {
  runApp(const MaterialApp(
    home: HomeScreen(),
  ));
}
