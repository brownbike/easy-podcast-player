import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PodcastArtwork extends StatelessWidget {
  const PodcastArtwork({super.key, required this.url, this.size});

  final String? url;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Fallback(size: size);
    final target = url;
    if (target == null || target.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: target,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({this.size});
  final double? size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      color: scheme.primaryContainer,
      alignment: Alignment.center,
      child: Icon(
        Icons.headphones,
        size: (size ?? 96) * 0.4,
        color: scheme.onPrimaryContainer,
      ),
    );
  }
}
