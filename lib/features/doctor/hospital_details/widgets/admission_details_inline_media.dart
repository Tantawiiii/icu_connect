import 'package:flutter/material.dart';
import 'package:icu_connect/core/constants/app_colors.dart';
import 'package:icu_connect/core/network/api_storage_fetch.dart';
import 'package:icu_connect/core/widgets/storage_network_image.dart';
import 'package:video_player/video_player.dart';

class AdmissionDetailsInlineImage extends StatelessWidget {
  const AdmissionDetailsInlineImage({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            body: Center(
              child: InteractiveViewer(
                child: StorageNetworkImage(
                  url: url,
                  fit: BoxFit.contain,
                  errorBuilder: (_) => const Icon(
                    Icons.broken_image_rounded,
                    size: 64,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      child: StorageNetworkImage(
        url: url,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_) => Container(
          height: 200,
          color: AppColors.border,
          child: const Center(
            child: Icon(
              Icons.broken_image_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class AdmissionDetailsInlineVideoPlayer extends StatefulWidget {
  const AdmissionDetailsInlineVideoPlayer({super.key, required this.url});

  final String url;

  @override
  State<AdmissionDetailsInlineVideoPlayer> createState() =>
      _AdmissionDetailsInlineVideoPlayerState();
}

class _AdmissionDetailsInlineVideoPlayerState
    extends State<AdmissionDetailsInlineVideoPlayer> {
  VideoPlayerController? _ctrl;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final canonical = normalizeApiStorageUrl(widget.url);
    final headers = needsAuthenticatedMediaFetch(widget.url)
        ? await apiStorageAuthHeaders()
        : const <String, String>{};

    VideoPlayerController? c;
    try {
      c = VideoPlayerController.networkUrl(
        Uri.parse(canonical),
        httpHeaders: headers,
      );
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _ctrl = c;
        _initialized = true;
      });
    } catch (_) {
      await c?.dispose();
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.videocam_off, color: Colors.white54),
        ),
      );
    }
    if (!_initialized || _ctrl == null) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    final ctrl = _ctrl!;
    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: ctrl.value.aspectRatio,
          child: VideoPlayer(ctrl),
        ),
        GestureDetector(
          onTap: () => setState(() {
            ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
          }),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: Icon(
              ctrl.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
