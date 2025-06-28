import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart'
    as img; // Import the image package with a prefix
import '../services/tflite_service.dart';
import '../widgets/image_picker_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TFLiteService _tfliteService = TFLiteService();
  String _result = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _tfliteService.loadModel();
  }

  Future<void> _runModel(File imageFile) async {
    setState(() => _isLoading = true);

    // 1. Read the image file as bytes
    final bytes = await imageFile.readAsBytes();
    // 2. Decode the image using the 'image' package
    final originalImage = img.decodeImage(bytes);

    if (originalImage == null) {
      // Handle the case where image decoding fails
      setState(() {
        _result = 'Error: Could not decode image.';
        _isLoading = false;
      });
      return; // Exit the function
    }

    // Now pass the img.Image object to your TFLiteService
    final List<double> output =
        await _tfliteService.runModelOnImage(originalImage);

    setState(() {
      _result = "Output: ${output.map((v) => v.toStringAsFixed(3)).join(', ')}";
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bamboo Classifier'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ImagePickerWidget(onImageSelected: _runModel),
            const SizedBox(height: 20),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Text(_result, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
