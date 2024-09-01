import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart'; // easy_localization 패키지 추가
import 'LoginPage/LoginPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')], // 지원하는 로케일 설정
      path: 'assets/translations', // 번역 파일 경로
      fallbackLocale: const Locale('en', 'US'), // 기본 로케일 설정
      startLocale: const Locale('en', 'US'), // 초기 로케일 설정
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates, // 번역 설정 추가
      supportedLocales: context.supportedLocales, // 지원하는 로케일 추가
      locale: context.locale, // 현재 로케일 설정
      home: LoginPage(),
    );
  }
}
