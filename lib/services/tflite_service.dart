import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

const List<double> kNormMean = [127.5, 127.5, 127.5];
const List<double> kNormStd = [127.5, 127.5, 127.5];

class TFLiteService {
  late final Interpreter _interpreter;
  bool _isModelLoaded = false;
  List<String> _labels = [];

  bool get isInitialized => _isModelLoaded;
  List<String> get labels => _labels;

  /// Load TFLite model from assets
  Future<void> loadModel() async {
    try {
      final rawAsset = await rootBundle.load('assets/model.tflite');
      final bytes = rawAsset.buffer.asUint8List();
      _interpreter = Interpreter.fromBuffer(bytes);
      _isModelLoaded = true;
      print('✅ Model loaded successfully with ${rawAsset.lengthInBytes} bytes');
    } catch (e) {
      print('❌ Failed to load model: $e');
    }
  }

  /// Load label list from assets/labels.txt
  Future<void> loadLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/labels.txt');
      _labels = labelData.split('\n').map((e) => e.trim()).toList();
      print('✅ Loaded ${_labels.length} labels');
    } catch (e) {
      print('❌ Failed to load labels: $e');
    }
  }

  /// Run inference on given image
  Future<List<double>> runModelOnImage(img.Image image) async {
    if (!_isModelLoaded) {
      throw Exception("Model is not loaded");
    }

    final inputShape = _interpreter.getInputTensor(0).shape;
    final outputShape = _interpreter.getOutputTensor(0).shape;

    final height = inputShape[1];
    final width = inputShape[2];

    // Resize image to model's input size
    final resized = img.copyResize(image, width: width, height: height);

    // Normalize pixels and prepare input buffer
    final input = Float32List(height * width * 3);
    int pixelIndex = 0;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = (pixel.r - kNormMean[0]) / kNormStd[0];
        input[pixelIndex++] = (pixel.g - kNormMean[1]) / kNormStd[1];
        input[pixelIndex++] = (pixel.b - kNormMean[2]) / kNormStd[2];
      }
    }

    final reshapedInput = input.reshape([1, height, width, 3]);
    final output =
        List.filled(outputShape[1], 0.0).reshape([1, outputShape[1]]);

    _interpreter.run(reshapedInput, output);

    return List<double>.from(output[0]);
  }

  /// Get label by index (with null safety)
  String getLabel(int index) {
    if (index < 0 || index >= _labels.length) {
      return 'Unknown';
    }
    return _labels[index];
  }

  /// Close interpreter and free resources
  void close() {
    if (_isModelLoaded) {
      _interpreter.close();
      _isModelLoaded = false;
      print('🔒 Interpreter closed');
    }
  }
}
