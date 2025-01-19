import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:developer' as developer;

class NetworkImageWithRetry extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const NetworkImageWithRetry({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
  }) : super(key: key);

  static const int maxMemoryCacheSize = 100 * 1024 * 1024; // 100MB

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      memCacheWidth: 300,
      memCacheHeight: 300,
      maxWidthDiskCache: 600,
      maxHeightDiskCache: 600,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: const Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
} 