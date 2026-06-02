import 'dart:io';
import 'package:image/image.dart' as img;

/// Re-encode the file as JPEG without EXIF, return path to a new tmp file.
Future<File> stripExif(File source) async {
  final bytes = await source.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return source; // fallback
  final stripped = img.encodeJpg(decoded, quality: 90);
  final out = File(
      '${source.parent.path}/no_exif_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await out.writeAsBytes(stripped);
  return out;
}
