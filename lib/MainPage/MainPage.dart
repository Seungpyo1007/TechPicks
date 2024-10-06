import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
  int _selectedIndex = 0;
  BottomNavigationBarType _bottomNavType = BottomNavigationBarType.fixed;

  final List<Widget> _pages = [
    const HomeScreen(),
    const CPUScreen(),
    const PhoneScreen(),
    const LaptopScreen(),
    const ProfileScreen(),
  ];

  bool isDarkMode() {
    // 다크모드 여부 확인
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    bool darkModeEnabled = isDarkMode(); // 다크모드가 활성화된 상태인지 확인

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            darkModeEnabled
                ? 'assets/logo/NBlogo.png' // 다크모드일 경우 원래 로고
                : 'assets/logo/NBlogo_black.png', // 그렇지 않으면 검정 로고
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black, Colors.blue],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _pages[_selectedIndex],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: darkModeEnabled ? Colors.white : Colors.black, // 다크모드면 하얀색, 아니면 검정색
        unselectedItemColor: darkModeEnabled ? Colors.white70 : Colors.black54, // 다크모드면 하얀색, 아니면 검정색
        backgroundColor: darkModeEnabled ? Colors.black : Colors.white, // 다크모드면 검정색, 아니면 하얀색
        type: _bottomNavType,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, color: darkModeEnabled ? Colors.white : Colors.black),
            activeIcon: Icon(Icons.home_rounded, color: darkModeEnabled ? Colors.white : Colors.black),
            label: 'home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.memory, color: darkModeEnabled ? Colors.white : Colors.black),
            activeIcon: Icon(Icons.memory, color: darkModeEnabled ? Colors.white : Colors.black),
            label: 'cpu'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.phone_android, color: darkModeEnabled ? Colors.white : Colors.black),
            activeIcon: Icon(Icons.phone_android, color: darkModeEnabled ? Colors.white : Colors.black),
            label: 'phone'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.laptop, color: darkModeEnabled ? Colors.white : Colors.black),
            activeIcon: Icon(Icons.laptop, color: darkModeEnabled ? Colors.white : Colors.black),
            label: 'laptop'.tr(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline, color: darkModeEnabled ? Colors.white : Colors.black),
            activeIcon: Icon(Icons.person_outline, color: darkModeEnabled ? Colors.white : Colors.black),
            label: 'profile'.tr(),
          ),
        ],
      ),
    );
  }
}
