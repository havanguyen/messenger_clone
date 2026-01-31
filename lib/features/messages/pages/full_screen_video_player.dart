import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;
  const FullScreenVideoPlayer({super.key, required this.controller});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideControlsTimer();
    }
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      widget.controller.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 30.0, left: 8, right: 8),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1 / widget.controller.value.aspectRatio,
                    child: Container(
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: VideoPlayer(widget.controller),
                    ),
                  ),
                ),
              ),
              if (_showControls)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                _isMuted ? Icons.volume_off : Icons.volume_up,
                                color: Colors.white,
                              ),
                              onPressed: _toggleMute,
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            ValueListenableBuilder(
                              valueListenable: widget.controller,
                              builder: (
                                context,
                                VideoPlayerValue value,
                                child,
                              ) {
                                return Column(
                                  children: [
                                    SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 2.0,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 6.0,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 12.0,
                                            ),
                                        activeTrackColor: Colors.red,
                                        inactiveTrackColor: Colors.white
                                            .withOpacity(0.3),
                                        thumbColor: Colors.red,
                                        overlayColor: Colors.red.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                      child: Slider(
                                        value:
                                            value.position.inMilliseconds
                                                .toDouble(),
                                        min: 0.0,
                                        max:
                                            value.duration.inMilliseconds
                                                .toDouble(),
                                        onChanged: (newPosition) {
                                          widget.controller.seekTo(
                                            Duration(
                                              milliseconds: newPosition.toInt(),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _formatDuration(value.position),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              value.isPlaying
                                                  ? Icons.pause
                                                  : Icons.play_arrow,
                                              color: Colors.white,
                                              size: 32.0,
                                            ),
                                            onPressed: () {
                                              if (value.isPlaying) {
                                                widget.controller.pause();
                                              } else {
                                                widget.controller.play();
                                              }
                                            },
                                          ),
                                          Text(
                                            _formatDuration(value.duration),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
