import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Lightweight face presence check. Returns true if at least one face is
/// detected in the image at [imagePath]. Uses ML Kit face detection in fast
/// mode (no contours / landmarks) — purpose is anti-spoof (gallery still has
/// no face, blurry shots fail) and cheap enough to run after each capture.
///
/// Caller MUST handle false → reject capture, prompt retake.
Future<bool> hasFace(String imagePath) async {
  final detector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableLandmarks: false,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.15,
    ),
  );
  try {
    final input = InputImage.fromFilePath(imagePath);
    final faces = await detector.processImage(input);
    return faces.isNotEmpty;
  } catch (_) {
    // Fail open on detector error so we don't block a legit user on a flaky
    // device — server still gates with watermark + GPS + zone check.
    return true;
  } finally {
    await detector.close();
  }
}
