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
    ));
    final res = await dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = Uint8List.fromList(res.data ?? const []);
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Pure-Dart decode returned null');
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
