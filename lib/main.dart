import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BambooApp());
}

class BambooApp extends StatelessWidget {
  const BambooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bamboo Classifier',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
