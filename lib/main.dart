import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle; // برای تست asset
import 'screens/home_screen.dart';

void main() {
  runApp(const BambooApp());
  checkAssetExist(); // تست لود شدن فایل مدل
}

/// تابع تست برای بررسی وجود و دسترسی به فایل مدل
void checkAssetExist() async {
  try {
    final byteData = await rootBundle.load('assets/model.tflite');
    debugPrint('✅ Model loaded successfully with ${byteData.lengthInBytes} bytes');
  } catch (e) {
    debugPrint('❌ Model asset not found or unreadable: $e');
  }
}

class BambooApp extends StatelessWidget {
  const BambooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bamboo Classifier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
