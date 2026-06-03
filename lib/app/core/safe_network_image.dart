import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import '../data/services/api_service.dart';

/// Fetch image bytes ourselves (with a browser UA so Cloudflare WAF serves
/// the actual asset instead of an HTML interstitial), then hand the bytes
/// to `Image.memory`. Keeps a per-URL byte cache so subsequent renders skip
/// the network.
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
  static final Map<String, Uint8List> _cache = {};
  static final Map<String, Future<Uint8List>> _inflight = {};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFor(widget.url),
      builder: (ctx, snapshot) {
        if (snapshot.hasError) {
          debugPrint('[SafeNetworkImage] fetch error url=${widget.url} err=${snapshot.error}');
          return widget.errorBuilder?.call(ctx, snapshot.error!) ??
              const SizedBox.shrink();
        }
        final bytes = snapshot.data;
        if (bytes == null) {
          return widget.placeholder?.call(ctx) ?? const SizedBox.shrink();
        }
        return Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (c, e, _) {
            debugPrint('[SafeNetworkImage] Image.memory decode error url=${widget.url} err=$e');
            return widget.errorBuilder?.call(c, e) ?? const SizedBox.shrink();
          },
        );
      },
    );
  }

  Future<Uint8List> _bytesFor(String url) {
    final cached = _cache[url];
    if (cached != null) return Future.value(cached);
    return _inflight.putIfAbsent(url, () async {
      try {
        final bytes = await _fetch(url);
        _cache[url] = bytes;
        return bytes;
      } finally {
        _inflight.remove(url);
      }
    });
  }

  static Future<Uint8List> _fetch(String url) async {
    // Cloudflare's WAF gates the public r2.dev subdomain on TLS / JA3
    // fingerprint and serves a 5KB HTML interstitial to Dart's HttpClient
    // regardless of User-Agent. Route the fetch through our own BE
    // (`GET /api/mobile/me/avatar`) which already speaks S3 to R2 and
    // streams the bytes back to us over the authenticated session.
    //
    // For non-avatar images (anything that's not the current user's own
    // avatar URL), we still try the direct fetch — those use cases (report
    // photos, etc.) may need a different proxy later but aren't broken
    // today.
    final api = Get.find<ApiService>();
    final currentImage =
        api.currentUser?['image']?.toString();
    if (currentImage != null && currentImage == url) {
      final res = await api.dio.get<List<int>>(
        '/mobile/me/avatar',
        options: Options(
          responseType: ResponseType.bytes,
          // Bypass our axios-style JSON content-type interceptor.
          headers: {'Accept': 'image/*'},
        ),
        queryParameters: {
          't': DateTime.now().millisecondsSinceEpoch,
        },
      );
      final bytes = Uint8List.fromList(res.data ?? const []);
      final ct = res.headers.value('content-type') ?? '';
      debugPrint(
          '[SafeNetworkImage] proxy fetched bytes=${bytes.length} ct=$ct');
      if (bytes.isEmpty) {
        throw Exception('Empty proxy response');
      }
      return bytes;
    }

    // Fallback: direct r2.dev hit with cache buster + browser UA.
    final fetchUrl =
        '$url${url.contains('?') ? '&' : '?'}t=${DateTime.now().millisecondsSinceEpoch}';
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    final res = await dio.get<List<int>>(
      fetchUrl,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          'Accept':
              'image/avif,image/webp,image/apng,image/png,image/jpeg,image/*,*/*;q=0.8',
        },
      ),
    );
    final bytes = Uint8List.fromList(res.data ?? const []);
    final ct = res.headers.value('content-type') ?? '';
    debugPrint(
        '[SafeNetworkImage] direct fetched bytes=${bytes.length} ct=$ct url=$url');
    if (bytes.isEmpty) {
      throw Exception('Empty response body');
    }
    if (!ct.startsWith('image/')) {
      throw Exception('Unexpected content-type: $ct');
    }
    return bytes;
  }
}
