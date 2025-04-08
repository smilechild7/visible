import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
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
