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
      child = ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Cache key: explicit URL so when the same widget rebuilds with
          // a different URL Flutter actually re-fetches.
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
          loadingBuilder: (ctx, c, progress) {
            if (progress == null) return c;
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
