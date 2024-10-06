import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LoginPage/LoginPage.dart';
import 'NewPage/FirstTutorial.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // SharedPreferences에서 저장된 언어 및 테마 설정 불러오기
  final prefs = await SharedPreferences.getInstance();
  final String? savedLocale = prefs.getString('selected_locale');
  final bool isDarkMode = prefs.getBool('is_dark_mode') ?? false;
  final bool isTutorialCompleted = prefs.getBool('is_tutorial_completed') ?? false;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('ko', 'KR')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      startLocale: savedLocale != null
          ? Locale(savedLocale.split('_')[0], savedLocale.split('_')[1])
          : const Locale('en', 'US'),
      child: MyApp(
        isDarkMode: isDarkMode,
        isTutorialCompleted: isTutorialCompleted,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isDarkMode;
  final bool isTutorialCompleted;

  const MyApp({
    Key? key,
    required this.isDarkMode,
    required this.isTutorialCompleted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // isTutorialCompleted가 false일 경우 TutorialPage로 이동
      home: isTutorialCompleted ? LoginPage() : WelcomeScreen(),
    );
  }
}
