import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../Loading.dart';
import 'ChatAI.dart';
import 'Model3D.dart';
import 'RankingPage/RankingCPU.dart';
import 'RankingPage/RankingPhone.dart';
import 'RankingPage/RankingLaptop.dart';
import 'Test.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 다크 모드 여부 확인
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // 다크 모드와 라이트 모드에 따른 테마 색상 설정
    final backgroundColor = isDarkMode ? Color(0xFF222222) : Color(0xFFE0E0E0); // 다크 모드: 어두운 색, 라이트 모드: 밝은 색
    final textColor = isDarkMode ? Colors.white : Colors.black; // 다크 모드: 흰색, 라이트 모드: 검정색

    return WillPopScope(
      onWillPop: () async {
        // 뒤로가기 버튼 눌렀을 때 아무 동작도 하지 않음
        return false; // false를 반환하여 뒤로 가지 않도록 함
      },
      child: Scaffold(
        backgroundColor: backgroundColor, // 전체 배경색 설정
        body: SafeArea(
          child: GestureDetector(
            onVerticalDragEnd: (details) {
              // 위로 스와이프 감지 시 투명 모달 채팅창 열기
              if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                _openTransparentChatModal(context);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBannerSection(backgroundColor, textColor), // 상단 바 (로고 포함) 영역
                _buildServiceIcons(context, textColor),
                _buildSearchBar(isDarkMode, textColor),
                _buildOptionsList(isDarkMode, textColor),
                _buildAroundYouSection(textColor),
                _buildBottomGrid(context, textColor), // 버튼 1, 2, 3만 표시되는 영역
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTransparentChatModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false, // 클릭으로 모달 닫기 비활성화
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.2), // 배경을 반투명하게 설정
      pageBuilder: (context, anim1, anim2) {
        final ScrollController scrollController = ScrollController();
        return Scaffold(
          backgroundColor: Colors.transparent, // 전체 화면 투명하게 설정
          body: GestureDetector(
            onVerticalDragEnd: (details) {
              // 아래로 스와이프 감지 시 모달 닫기
              if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                Navigator.of(context).pop(); // 아래로 스와이프할 때만 닫기
              }
            },
            child: Container(
              color: Colors.black.withOpacity(0.5), // 전체 화면 반투명 배경
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width, // 화면의 전체 너비 사용
                  height: MediaQuery.of(context).size.height, // 화면의 전체 높이 사용
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8), // 투명한 흰색 배경
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ChatAIScreen(scrollController: scrollController), // scrollController 전달
                      ),
                      Container(
                        height: 20,
                        child: const Center(
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.grey,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(CurvedAnimation(
            parent: anim1,
            curve: Curves.easeOut,
          )),
          child: child,
        );
      },
    );
  }

  Widget _buildBannerSection(Color backgroundColor, Color textColor) {
    return Container(
      width: double.infinity,
      height: 150,
      color: backgroundColor, // 상단 바도 전체 배경색과 동일하게 설정
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'together_technology'.tr(),
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'ranking list 2024'.tr() + ' ->',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcons(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RankingCPUScreen()),
              );
            },
            child: _buildServiceIcon(Icons.memory, 'cpu'.tr(), textColor),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RankingPhoneScreen()),
              );
            },
            child: _buildServiceIcon(Icons.phone_android, 'phone'.tr(), textColor),
          ),
          _buildServiceIcon(Icons.newspaper_rounded, 'news'.tr(), textColor),
          _buildServiceIcon(Icons.event, 'reserve'.tr(), textColor),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RankingLaptopScreen()),
              );
            },
            child: _buildServiceIcon(Icons.laptop, 'laptop'.tr(), textColor),
          ),
          _buildServiceIcon(Icons.person_outline, 'profile'.tr(), textColor),
          _buildServiceIcon(Icons.more_horiz, 'more'.tr(), textColor),
          _buildServiceIcon(Icons.star, 'bookmarks'.tr(), textColor),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDarkMode, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: textColor),
          hintText: 'where_to'.tr(),
          hintStyle: TextStyle(color: textColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        ),
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildOptionsList(bool isDarkMode, Color textColor) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.star, color: textColor),
          title: Text('choose_bookmark'.tr(), style: TextStyle(color: textColor)),
        ),
        ListTile(
          leading: Icon(Icons.map, color: textColor),
          title: Text('set_destination_on_map'.tr(), style: TextStyle(color: textColor)),
        ),
        Divider(color: textColor),
      ],
    );
  }

  Widget _buildAroundYouSection(Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'around_you'.tr(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGrid(BuildContext context, Color textColor) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: GridView.count(
          crossAxisCount: 3, // 한 줄에 3개의 아이콘
          shrinkWrap: true, // GridView의 크기를 자식 위젯 크기로 맞춤
          physics: const NeverScrollableScrollPhysics(), // 스크롤 비활성화
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Model3DScreen()),
                );
              },
              child: _buildServiceIcon(Icons.map, 'button1'.tr(), textColor),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TestScreen()),
                );
              },
              child: _buildServiceIcon(Icons.camera, 'button2'.tr(), textColor), // 버튼 2
            ),
            _buildServiceIcon(Icons.shopping_cart, 'button3'.tr(), textColor), // 버튼 3
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(IconData icon, String label, Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: Colors.grey[200],
          child: Icon(icon, size: 30, color: Colors.black), // 아이콘 색상 변경 없이 유지
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: textColor),
        ),
      ],
    );
  }
}
