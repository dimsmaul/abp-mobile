import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'theme.dart';

/// Renders a circular avatar that gracefully degrades:
/// - Network image (with loading + error fallback) when [imageUrl] is set
/// - Initial letter (first char of [name]) on bg [backgroundColor] otherwise,
///   or when the image fails to load.
///
/// Existing CircleAvatar(backgroundImage: NetworkImage(...)) silently falls
/// back to backgroundColor on error, which read as "blank white" when the
/// image URL was momentarily unreachable. This widget surfaces the initial
/// so the avatar never goes blank.
class AvatarBubble extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final Color backgroundColor;
  final Color foregroundColor;
  final double? fontSize;
  final BoxBorder? border;

  const AvatarBubble({
    super.key,
    required this.imageUrl,
    required this.name,
    this.radius = 24,
    this.backgroundColor = AppTheme.primaryLight,
    this.foregroundColor = AppTheme.primary,
    this.fontSize,
    this.border,
  });

  String get _initial =>
      name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initial,
        style: TextStyle(
          color: foregroundColor,
          fontSize: fontSize ?? (radius * 0.75),
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    Widget child;
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      child = fallback;
    } else {
      debugPrint('[AvatarBubble] render url=$url');
      child = ClipOval(
        key: ValueKey(url),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          headers: const {'Accept': 'image/*'},
          errorBuilder: (_, error, stack) {
            debugPrint('[AvatarBubble] LOAD FAILED url=$url err=$error');
            return fallback;
          },
          loadingBuilder: (ctx, c, progress) {
            if (progress == null) {
              debugPrint('[AvatarBubble] LOAD OK url=$url');
              return c;
            }
            return fallback;
          },
        ),
      );
    }

    if (border == null) return child;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border,
      ),
      child: ClipOval(child: child),
    );
  }
}
