import 'dart:io';
import 'package:image/image.dart' as img;

/// Re-encode the file as JPEG without EXIF, return path to a new tmp file.
/// If [maxDimension] is provided, the longest side is resized to fit so the
/// output stays under the BE 5MB avatar limit and the upload doesn't time out
/// on slow connections.
Future<File> stripExif(File source, {int? maxDimension, int quality = 85}) async {
  final bytes = await source.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return source; // fallback — return original on decode failure

  img.Image working = decoded;
  if (maxDimension != null) {
    final longest =
        working.width > working.height ? working.width : working.height;
    if (longest > maxDimension) {
      working = img.copyResize(
        working,
        width: working.width >= working.height ? maxDimension : null,
        height: working.height > working.width ? maxDimension : null,
        interpolation: img.Interpolation.linear,
      );
    }
  }

  final encoded = img.encodeJpg(working, quality: quality);
  final out = File(
      '${source.parent.path}/no_exif_${DateTime.now().millisecondsSinceEpoch}.jpg');
  await out.writeAsBytes(encoded);
  return out;
}
