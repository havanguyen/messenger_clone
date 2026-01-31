import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerPreviewWidget extends StatefulWidget {
  final String path;

  const VideoPlayerPreviewWidget({super.key, required this.path});

  @override
  State<VideoPlayerPreviewWidget> createState() =>
      _VideoPlayerPreviewWidgetState();
}

class _VideoPlayerPreviewWidgetState extends State<VideoPlayerPreviewWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  void _initVideoPlayer() {
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.setVolume(0.0);
          _controller.seekTo(Duration(milliseconds: 100));
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
            Container(decoration: BoxDecoration(color: Colors.black26)),
            Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
