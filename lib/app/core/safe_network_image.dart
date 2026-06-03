import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Network image widget that fully bypasses Android's native ImageDecoder.
///
/// Why: Android's ImageDecoder on certain Xiaomi / MediaTek hardware throws
/// `Failed to create image decoder with message 'unimplemented'` on JPEGs
/// that every other decoder (browsers, Skia desktop, Chrome on the same
/// device) handles fine. Flutter's `Image.network` and `CachedNetworkImage`
/// both ultimately route bytes through that broken native decoder.
///
/// This widget instead:
///   1. Fetches bytes with Dio
///   2. Decodes them in pure Dart via the `image` package
///   3. Lifts the resulting RGBA pixels into a `ui.Image` via
///      `decodeImageFromPixels` (a path that does NOT touch the JPEG/PNG
///      native decoder)
///   4. Renders with `RawImage`
///
/// Decoded `ui.Image` instances are cached per URL across widget mounts so
/// subsequent renders are immediate.
class SafeNetworkImage extends StatefulWidget {
  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final WidgetBuilder? placeholder;
  final Widget Function(BuildContext, Object error)? errorBuilder;

  const SafeNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorBuilder,
  });

  @override
  State<SafeNetworkImage> createState() => _SafeNetworkImageState();
}

class _SafeNetworkImageState extends State<SafeNetworkImage> {
  static final Map<String, ui.Image> _cache = {};
  static final Map<String, Future<ui.Image>> _inflight = {};

  ui.Image? _image;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SafeNetworkImage old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _image = null;
      _error = null;
      _load();
    }
  }

  Future<void> _load() async {
    final url = widget.url;

    final cached = _cache[url];
    if (cached != null) {
      if (mounted) setState(() => _image = cached);
      return;
    }

    try {
      final future = _inflight.putIfAbsent(url, () => _fetchAndDecode(url));
      final decoded = await future;
      _inflight.remove(url);
      if (!mounted) return;
      setState(() => _image = decoded);
    } catch (e) {
      _inflight.remove(url);
      debugPrint('[SafeNetworkImage] decode failed url=$url err=$e');
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  static Future<ui.Image> _fetchAndDecode(String url) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        // Cloudflare's default WAF served an HTML interstitial when Dio
        // sent its default User-Agent (Dio/x.y.z). A browser-like UA
        // makes the request indistinguishable from a Chrome page load
        // and gets through to the actual object.
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': 'image/avif,image/webp,image/apng,image/png,image/jpeg,image/*,*/*;q=0.8',
      },
    ));
    final res = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
    );
    final bytes = Uint8List.fromList(res.data ?? const []);
    debugPrint(
        '[SafeNetworkImage] fetched url=$url status=${res.statusCode} bytes=${bytes.length} content-type=${res.headers.value('content-type')}');
    if (bytes.isEmpty) {
      throw Exception('Empty response body');
    }
    debugPrint(
        '[SafeNetworkImage] magic bytes: ${bytes.take(8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (e) {
      debugPrint('[SafeNetworkImage] decodeImage threw: $e');
    }
    // Auto-detect failed — fall back to format-specific decoders.
    if (decoded == null) {
      try {
        decoded = img.decodePng(bytes);
        if (decoded != null) {
          debugPrint('[SafeNetworkImage] fallback decodePng worked');
        }
      } catch (_) {}
    }
    if (decoded == null) {
      try {
        decoded = img.decodeJpg(bytes);
        if (decoded != null) {
          debugPrint('[SafeNetworkImage] fallback decodeJpg worked');
        }
      } catch (_) {}
    }
    if (decoded == null) {
      throw Exception(
          'Pure-Dart decode returned null after auto + png + jpg attempts');
    }

    final rgba = decoded.getBytes(order: img.ChannelOrder.rgba);
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      Uint8List.fromList(rgba),
      decoded.width,
      decoded.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final uiImage = await completer.future;
    _cache[url] = uiImage;
    return uiImage;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          const SizedBox.shrink();
    }
    if (_image == null) {
      return widget.placeholder?.call(context) ?? const SizedBox.shrink();
    }
    return RawImage(
      image: _image,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
    );
  }
}
