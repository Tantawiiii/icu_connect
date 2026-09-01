import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../network/api_storage_fetch.dart';

/// Bounded in-memory byte cache so revisiting a screen or re-scrolling a list
/// doesn't refetch/redecode the same authenticated image. Simple FIFO
/// eviction once the cache grows past [_maxEntries] — good enough for the
/// handful of avatars/photos visible at once, no need for a full LRU.
class _ImageByteCache {
  static const int _maxEntries = 50;
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? get(String url) => _cache[url];

  static void put(String url, Uint8List bytes) {
    if (_cache.length >= _maxEntries && !_cache.containsKey(url)) {
      _cache.remove(_cache.keys.first);
    }
    _cache[url] = bytes;
  }
}

/// Loads images with [package:http] + [Image.memory] (User-Agent + optional Bearer).
class StorageNetworkImage extends StatefulWidget {
  const StorageNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext)? errorBuilder;

  @override
  State<StorageNetworkImage> createState() => _StorageNetworkImageState();
}

class _StorageNetworkImageState extends State<StorageNetworkImage> {
  late Future<Uint8List?> _load;

  @override
  void initState() {
    super.initState();
    _load = _loadCached(widget.url);
  }

  @override
  void didUpdateWidget(StorageNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load = _loadCached(widget.url);
    }
  }

  Future<Uint8List?> _loadCached(String url) async {
    final cached = _ImageByteCache.get(url);
    if (cached != null) return cached;
    final bytes = await fetchHttpImageBytes(url);
    if (bytes != null && bytes.isNotEmpty) {
      _ImageByteCache.put(url, bytes);
    }
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return widget.errorBuilder?.call(context) ?? const SizedBox.shrink();
        }

        final dpr = MediaQuery.of(context).devicePixelRatio;
        final cacheWidth = widget.width != null
            ? (widget.width! * dpr).round()
            : null;
        final cacheHeight = widget.height != null
            ? (widget.height! * dpr).round()
            : null;
        return Image.memory(
          data,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          errorBuilder: widget.errorBuilder != null
              ? (c, _, __) => widget.errorBuilder!(c)
              : null,
        );
      },
    );
  }
}
