import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 전체 화면 설정
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(const VisibleApp());
}

class VisibleApp extends StatelessWidget {
  const VisibleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visible',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
