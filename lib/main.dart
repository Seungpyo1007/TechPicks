import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 가 없어도 앱은 뜬다. 로그인만 안 되고 랭킹·비교·상담은 다 된다.
  // google-services.json 이 아직 온전하지 않아 (oauth_client 가 비어 있다)
  // 여기서 죽으면 개발 중에 아무것도 못 본다.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // 로그인 화면이 "연결되지 않았다"로 떨어진다.
  }

  runApp(const ProviderScope(child: TechPicksApp()));
}
