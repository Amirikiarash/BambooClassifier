import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../services/tflite_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TFLiteService _tfliteService = TFLiteService();
  Uint8List? _imageBytes;
  String _resultLabel = '';
  double _confidence = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _tfliteService.loadModel();
    await _tfliteService.loadLabels();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return;

    setState(() {
      _isLoading = true;
      _imageBytes = bytes;
      _resultLabel = '';
      _confidence = 0.0;
    });

    final predictions = await _tfliteService.runModelOnImage(image);

    final topIndex = predictions
        .indexWhere((e) => e == predictions.reduce((a, b) => a > b ? a : b));
    final topLabel = _tfliteService.labels[topIndex];
    final topConfidence = predictions[topIndex] * 100;

    setState(() {
      _resultLabel = topLabel;
      _confidence = topConfidence;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tfliteService.close();
    super.dispose();
  }

  void _exitApp() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCEEFF),
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text('Bamboo Classifier', style: TextStyle(fontSize: 20)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 5),
            Center(
              child: Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[300],
                ),
                child: _imageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.image_search),
              label: const Text('Select Image'),
              onPressed: _pickImage,
            ),
            const SizedBox(height: 10),
            if (_imageBytes != null) ...[
              const Text(
                'Identification result:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                _resultLabel,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: LinearProgressIndicator(
                  value: _confidence / 100,
                  minHeight: 16,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_confidence.toStringAsFixed(2)} %',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                onPressed: _exitApp,
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
                label: const Text('Exit App'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
