import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;

  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                width: size.width
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
                "assets/images/top2.png",
                width: size.width
            ),
          ),
          Positioned(
            top: 50,
            right: 30,
            child: Image.asset(
              "assets/logo/NBlogo.png",
              width: 70,  // 고정된 너비
              height: 110, // 고정된 높이
              fit: BoxFit.cover, // 이미지가 크기에 맞게 잘림 없이 채워지도록 설정
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
                "assets/images/Bottom1.png",
                width: size.width
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
                "assets/images/Bottom2.png",
                width: size.width
            ),
          ),
          child
        ],
      ),
    );
  }
}
