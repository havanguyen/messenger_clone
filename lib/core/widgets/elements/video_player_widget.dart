import 'package:flutter/material.dart';
import 'package:messenger_clone/features/messages/pages/full_screen_video_player.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final double? aspectRatio;
  final VideoPlayerController? controller;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.aspectRatio,
    this.controller,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _controller =
        widget.controller ??
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      if (widget.controller == null) {
        await _controller.initialize();
      }
      if (widget.autoPlay) {
        await _controller.play();
      }
      if (widget.looping) {
        await _controller.setLooping(true);
      }
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio ?? 1 / _controller.value.aspectRatio,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Icon(Icons.error_outline, color: Colors.white, size: 42),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio ?? 1 / _controller.value.aspectRatio,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: widget.aspectRatio ?? 1 / _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          _VideoControls(controller: _controller),
        ],
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  final VideoPlayerController controller;

  const _VideoControls({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: controller,
      builder: (context, VideoPlayerValue value, child) {
        return GestureDetector(
          onDoubleTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => FullScreenVideoPlayer(controller: controller),
              ),
            );
          },
          onTap: () {
            if (value.isPlaying) {
              controller.pause();
            } else {
              controller.play();
            }
          },
          child: Container(
            color: Colors.black26,
            child: Center(
              child: Icon(
                value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 50.0,
              ),
            ),
          ),
        );
      },
    );
  }
}
