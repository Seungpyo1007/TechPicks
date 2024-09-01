import 'package:flutter/material.dart';
import 'MenuPage/Home.dart';
import 'MenuPage/Phone.dart';
import 'MenuPage/CPU.dart';
import 'MenuPage/Profile.dart';
import 'MenuPage/Laptop.dart';

class SimpleBottomNavigation extends StatefulWidget {
  const SimpleBottomNavigation({Key? key}) : super(key: key);

  @override
  State<SimpleBottomNavigation> createState() => _SimpleBottomNavigationState();
}

class _SimpleBottomNavigationState extends State<SimpleBottomNavigation> {
  int _selectedIndex = 0; // 기본 선택된 탭을 PHONE으로 설정
  BottomNavigationBarType _bottomNavType = BottomNavigationBarType.fixed;

  // 각 페이지를 리스트로 정의
  final List<Widget> _pages = [
    const HomeScreen(),
    const CPUScreen(),
    const PhoneScreen(),
    const LaptopScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // AppBar 뒤로 바디 확장
      appBar: AppBar(
        backgroundColor: Colors.transparent, // AppBar 배경을 투명하게 설정
        elevation: 0, // 그림자 제거
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/logo/NBlogo.png'), // 상단 로고 이미지
        ),
      ),
      body: Stack(
        children: [
          // 그라데이션 배경
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.blue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 선택된 페이지를 애니메이션과 함께 보여줍니다
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _pages[_selectedIndex], // 선택된 페이지
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white, // 선택된 아이템 색상 (하얀색)
        unselectedItemColor: Colors.white, // 선택되지 않은 아이템 색상 (하얀색)
        backgroundColor: Colors.black,
        type: _bottomNavType,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: _navBarItems,
      ),
    );
  }
}

const _navBarItems = [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined, color: Colors.white),
    activeIcon: Icon(Icons.home_rounded, color: Colors.white),
    label: 'Home',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.memory, color: Colors.white),
    activeIcon: Icon(Icons.memory, color: Colors.white),
    label: 'CPU',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.phone_android, color: Colors.white),
    activeIcon: Icon(Icons.phone_android, color: Colors.white),
    label: 'Phone',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.laptop, color: Colors.white),
    activeIcon: Icon(Icons.laptop, color: Colors.white),
    label: 'Laptop',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline, color: Colors.white),
    activeIcon: Icon(Icons.person_outline, color: Colors.white),
    label: 'Profile',
  ),
];
