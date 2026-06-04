import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// MobileFaceNet embedding pipeline.
///
/// Input model: [1, 112, 112, 3] float32 normalized to [-1, 1]
/// Output:      [1, 192]         float32 — the L2-comparable embedding
///
/// Asset bundle must contain `assets/models/mobilefacenet.tflite`.
class FaceEmbedder {
  FaceEmbedder._();
  static final FaceEmbedder instance = FaceEmbedder._();

  Interpreter? _interpreter;
  bool _initFailed = false;

  Future<void> _ensureInit() async {
    if (_interpreter != null || _initFailed) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobilefacenet.tflite',
      );
      debugPrint('[face_embed] interpreter loaded');
    } catch (e) {
      _initFailed = true;
      debugPrint('[face_embed] init failed: $e');
    }
  }

  /// Returns null when:
  /// - model not bundled / failed to load
  /// - no face detected in [imagePath]
  /// - decode/crop error
  Future<Float32List?> embedFromFile(String imagePath) async {
    await _ensureInit();
    final interp = _interpreter;
    if (interp == null) return null;

    final detector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
    try {
      final faces = await detector.processImage(
        InputImage.fromFilePath(imagePath),
      );
      if (faces.isEmpty) return null;

      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final box = faces.first.boundingBox;
      final cropX = box.left.toInt().clamp(0, decoded.width - 1);
      final cropY = box.top.toInt().clamp(0, decoded.height - 1);
      final cropW = box.width.toInt().clamp(1, decoded.width - cropX);
      final cropH = box.height.toInt().clamp(1, decoded.height - cropY);

      final cropped = img.copyCrop(
        decoded,
        x: cropX,
        y: cropY,
        width: cropW,
        height: cropH,
      );
      final resized = img.copyResize(cropped, width: 112, height: 112);

      final input = Float32List(1 * 112 * 112 * 3);
      var idx = 0;
      for (var y = 0; y < 112; y++) {
        for (var x = 0; x < 112; x++) {
          final pixel = resized.getPixel(x, y);
          input[idx++] = (pixel.r - 127.5) / 128.0;
          input[idx++] = (pixel.g - 127.5) / 128.0;
          input[idx++] = (pixel.b - 127.5) / 128.0;
        }
      }

      final output = List<List<double>>.generate(
        1,
        (_) => List<double>.filled(192, 0),
      );
      interp.run(input.reshape([1, 112, 112, 3]), output);
      return Float32List.fromList(output[0]);
    } catch (e) {
      debugPrint('[face_embed] embed error: $e');
      return null;
    } finally {
      await detector.close();
    }
  }

  /// Cosine similarity in [-1, 1]. Higher = more similar.
  static double cosineSimilarity(Float32List a, Float32List b) {
    if (a.length != b.length) return -1;
    var dot = 0.0;
    var normA = 0.0;
    var normB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return -1;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }
}
