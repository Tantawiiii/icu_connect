import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../network/api_storage_fetch.dart';

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
    _load = fetchHttpImageBytes(widget.url);
  }

  @override
  void didUpdateWidget(StorageNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _load = fetchHttpImageBytes(widget.url);
    }
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
        return Image.memory(
          data,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          errorBuilder: widget.errorBuilder != null
              ? (c, _, __) => widget.errorBuilder!(c)
              : null,
        );
      },
    );
  }
}
