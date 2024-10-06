import 'package:flutter/material.dart';

class Background extends StatefulWidget {
  final Widget child;

  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _BackgroundState createState() => _BackgroundState();
}

class _BackgroundState extends State<Background> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _positionAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true); // 애니메이션 반복

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
    _positionAnimation = Tween<double>(begin: 50, end: 70).animate(_controller); // top 위치 애니메이션
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 여부 확인
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Size size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              "assets/images/top1.png",
              width: size.width,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              "assets/images/top2.png",
              width: size.width,
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned(
                top: _positionAnimation.value, // 애니메이션으로 top 위치 조정
                right: 30, // 고정된 right 위치
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Image.asset(
                    isDarkMode ? "assets/logo/NBlogo.png" : "assets/logo/NBlogo_black.png", // 다크 모드 여부에 따라 로고 변경
                    width: 70,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              "assets/images/Bottom1.png",
              width: size.width,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              "assets/images/Bottom2.png",
              width: size.width,
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
