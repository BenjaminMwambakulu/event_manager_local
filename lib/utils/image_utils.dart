import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Utility functions for handling image URLs
class ImageUtils {
  /// Fixes localhost URLs for Android emulator by replacing localhost with 10.0.2.2
  static String fixImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }
    
    // Replace localhost with Android emulator IP
    if (url.contains('localhost:8000')) {
      return url.replaceAll('localhost:8000', '10.0.2.2:8000');
    }
    
    // Replace 127.0.0.1 with Android emulator IP as well
    if (url.contains('127.0.0.1:8000')) {
      return url.replaceAll('127.0.0.1:8000', '10.0.2.2:8000');
    }
    
    return url;
  }
  
  /// Checks if an image URL is valid and accessible
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    
    // Check if it's a valid HTTP/HTTPS URL
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Creates a cached network image with proper error handling and placeholders
  static Widget cachedNetworkImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    final fixedUrl = fixImageUrl(imageUrl);
    
    if (!isValidImageUrl(fixedUrl)) {
      return errorWidget ?? _defaultErrorWidget(width, height);
    }

    Widget image = CachedNetworkImage(
      imageUrl: fixedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _defaultPlaceholder(width, height),
      errorWidget: (context, url, error) => errorWidget ?? _defaultErrorWidget(width, height),
    );

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius,
        child: image,
      );
    }

    return image;
  }

  /// Creates a cached network image for CircleAvatar
  static ImageProvider? cachedNetworkImageProvider(String? imageUrl) {
    final fixedUrl = fixImageUrl(imageUrl);
    
    if (!isValidImageUrl(fixedUrl)) {
      return null;
    }

    return CachedNetworkImageProvider(fixedUrl);
  }

  static Widget _defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade400),
        ),
      ),
    );
  }

  static Widget _defaultErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey.shade400,
        size: (width != null && height != null) ? (width < height ? width : height) * 0.4 : 32,
      ),
    );
  }
}