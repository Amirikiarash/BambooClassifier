import 'dart:typed_data'; // Required for ByteData
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart'
    as img; // Import the image package with a prefix

// Define your model's expected input size and normalization parameters
// YOU MUST ADJUST THESE VALUES BASED ON YOUR 'model.tflite'
// If your model is 224x224 pixels RGB input, these defaults are common.
const int kInputImageSize = 224;
// Example for -1 to 1 normalization common in many pre-trained models
// (pixel - mean) / std_dev
const List<double> kNormMean = [127.5, 127.5, 127.5];
const List<double> kNormStd = [127.5, 127.5, 127.5];

class TFLiteService {
  late Interpreter _interpreter;
  bool _isModelLoaded = false;

  /// Check if interpreter has been loaded
  bool get isInitialized => _isModelLoaded;

  /// Load the TensorFlow Lite model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      _isModelLoaded = true;
      print('✅ Interpreter loaded successfully');
      print('Model Input Shape: ${_interpreter.getInputTensor(0).shape}');
      print('Model Input Type: ${_interpreter.getInputTensor(0).type}');
    } catch (e) {
      print('❌ Error while loading model: $e');
      _isModelLoaded = false;
      // Consider throwing the error or providing user feedback here
    }
  }

  /// Run inference on an [img.Image]
  Future<List<double>> runModelOnImage(img.Image inputImage) async {
    if (!_isModelLoaded) {
      print('❌ Error: Interpreter not loaded. Call loadModel() first.');
      return []; // Or throw an exception
    }

    // Get input tensor details from the loaded model
    final inputTensor = _interpreter.getInputTensor(0);
    final inputShape = inputTensor.shape;
    final TensorType inputTfType =
        inputTensor.type; // Use TensorType directly for comparison

    // Ensure the image matches the model's expected dimensions
    final int modelHeight = inputShape[1];
    final int modelWidth = inputShape[2];
    final int modelChannels = inputShape[3];

    // Resize the input image to the model's expected dimensions
    final resizedImage =
        img.copyResize(inputImage, width: modelWidth, height: modelHeight);

    // Create input buffer based on model's input type
    Uint8List inputBytes;
    if (inputTfType == TfLiteType.float32) {
      // Corrected: Comparing TensorType with TfLiteType
      final float32List =
          Float32List(1 * modelHeight * modelWidth * modelChannels);
      int pixelIndex = 0;
      for (int y = 0; y < modelHeight; y++) {
        for (int x = 0; x < modelWidth; x++) {
          final pixel = resizedImage.getPixel(x, y);

          // These are now correctly called as static methods on 'img'
          final r = img.getRed(pixel);
          final g = img.getGreen(pixel);
          final b = img.getBlue(pixel);

          float32List[pixelIndex++] = (r - kNormMean[0]) / kNormStd[0];
          float32List[pixelIndex++] = (g - kNormMean[1]) / kNormStd[1];
          float32List[pixelIndex++] = (b - kNormMean[2]) / kNormStd[2];
        }
      }
      inputBytes = float32List.buffer.asUint8List();
    } else if (inputTfType == TfLiteType.uint8) {
      // Corrected: Comparing TensorType with TfLiteType
      final uint8List = Uint8List(1 * modelHeight * modelWidth * modelChannels);
      int pixelIndex = 0;
      for (int y = 0; y < modelHeight; y++) {
        for (int x = 0; x < modelWidth; x++) {
          final pixel = resizedImage.getPixel(x, y);
          uint8List[pixelIndex++] = img.getRed(pixel);
          uint8List[pixelIndex++] = img.getGreen(pixel);
          uint8List[pixelIndex++] = img.getBlue(pixel);
        }
      }
      inputBytes = uint8List;
    } else {
      print('❌ Unsupported input type: $inputTfType');
      return [];
    }

    final input = [inputBytes.buffer]; // Pass as ByteBuffer directly

    // Get output tensor details
    final outputTensor = _interpreter.getOutputTensor(0);
    final outputShape = outputTensor.shape;
    final TensorType outputTfType =
        outputTensor.type; // Use TensorType directly

    // Create output buffer
    final outputBuffer = TensorBuffer.createFixedSize(
        outputShape, outputTfType); // Corrected: Use outputTfType here

    // Run inference
    _interpreter.run(input, outputBuffer.buffer);

    // Convert output buffer to a list of doubles
    if (outputTfType == TfLiteType.float32) {
      // Corrected: Comparing TensorType with TfLiteType
      return outputBuffer.getDoubleList();
    } else if (outputTfType == TfLiteType.uint8 ||
        outputTfType == TfLiteType.int32) {
      // Corrected
      return outputBuffer.getIntList().map((e) => e.toDouble()).toList();
    } else {
      print('❌ Unsupported output type: $outputTfType');
      return [];
    }
  }

  /// Close the interpreter when no longer needed
  void close() {
    if (_isModelLoaded) {
      _interpreter.close();
      _isModelLoaded = false;
      print('Interpreter closed.');
    }
  }
}
