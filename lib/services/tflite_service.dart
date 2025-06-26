import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

class TFLiteService {
  late final Interpreter _interpreter;

  /// Check if interpreter has been loaded
  bool get isInitialized => _interpreter != null;

  /// Load the TensorFlow Lite model
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('model.tflite');
      print('✅ Interpreter loaded successfully');
    } catch (e) {
      print('❌ Error while loading model: $e');
    }
  }

  /// Run inference on a [TensorImage]
  Future<List<double>> runModelOnImage(TensorImage inputImage) async {
    // Prepare input as tensor buffer
    final inputTensor = inputImage.tensorBuffer.buffer;

    // Determine output shape from model
    final outputShape = _interpreter.getOutputTensor(0).shape;
    final outputType = _interpreter.getOutputTensor(0).type;

    // Create output buffer
    final outputTensor = TensorBuffer.createFixedSize(outputShape, outputType);

    // Run inference
    _interpreter.run(inputTensor, outputTensor.buffer);

    // Convert buffer to list of doubles
    return outputTensor.getDoubleList();
  }
}
