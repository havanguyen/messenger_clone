import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:messenger_clone/features/tin/widgets/story_item.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/utils/date_time_extensions.dart';
import '../../../core/widgets/dialog/custom_alert_dialog.dart';

class StoryDetailPage extends StatefulWidget {
  final List<StoryItem> stories;
  final int initialIndex;

  const StoryDetailPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<StoryDetailPage> createState() => _StoryDetailPageState();
}

class _StoryDetailPageState extends State<StoryDetailPage>
    with TickerProviderStateMixin {
  late List<AnimationController> _progressControllers;
  late int _currentIndex;
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  VideoPlayerController? _nextVideoPlayerController;
  ChewieController? _nextChewieController;
  VideoPlayerController? _prevVideoPlayerController;
  ChewieController?
  _prevChewieController;
  bool _isPlaying = true;
  bool _isLoading = false;
  double _dragOffset = 0.0;
  bool _isDragging = false;
  int _nextIndex = 0;
  int _prevIndex = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _currentIndex = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _updateAdjacentIndices();
    _progressControllers = List.generate(
      widget.stories.length,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(seconds: 15),
      ),
    );
    _resetVideo();
  }

  void _updateAdjacentIndices() {
    _nextIndex =
        _currentIndex < widget.stories.length - 1
            ? _currentIndex + 1
            : _currentIndex;
    _prevIndex = _currentIndex > 0 ? _currentIndex - 1 : _currentIndex;
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (var controller in _progressControllers) {
      controller.dispose();
    }
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _nextVideoPlayerController?.dispose();
    _nextChewieController?.dispose();
    _prevVideoPlayerController?.dispose();
    _prevChewieController?.dispose();
    super.dispose();
  }

  void _startProgressForCurrentSequence() {
    if (_isDisposed || _currentIndex >= widget.stories.length) return;
    _progressControllers[_currentIndex].reset();
    if (!_isPlaying) return;
    _progressControllers[_currentIndex].forward().then((_) {
      if (_isDisposed) return;
      if (_currentIndex < widget.stories.length - 1) {
        _nextStory();
      } else {
        Navigator.of(context).pop();
      }
    });
  }

  void _nextStory() {
    if (_isDisposed || _currentIndex >= widget.stories.length - 1) return;
    _progressControllers[_currentIndex].stop();
    setState(() {
      _currentIndex++;
      _updateAdjacentIndices();
      _resetVideo();
    });
  }

  void _previousStory() {
    if (_isDisposed || _currentIndex <= 0) return;
    _progressControllers[_currentIndex].stop();
    setState(() {
      _currentIndex--;
      _updateAdjacentIndices();
      _resetVideo();
    });
  }

  Future<void> _resetVideo() async {
    if (_isDisposed) return;
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    setState(() => _isLoading = true);

    final story = widget.stories[_currentIndex];
    if (story.isVideo) {
      try {
        if (_nextVideoPlayerController != null && _currentIndex == _nextIndex) {
          _videoPlayerController = _nextVideoPlayerController;
          _chewieController = _nextChewieController;
          _nextVideoPlayerController = null;
          _nextChewieController = null;
        } else if (_prevVideoPlayerController != null &&
            _currentIndex == _prevIndex) {
          _videoPlayerController = _prevVideoPlayerController;
          _chewieController = _prevChewieController;
          _prevVideoPlayerController = null;
          _prevChewieController = null;
        } else {
          _videoPlayerController = VideoPlayerController.network(
            story.imageUrl,
          );
        }
        await _videoPlayerController!.initialize();
        if (_isDisposed) return;

        final videoDuration = _videoPlayerController!.value.duration;
        if (videoDuration == Duration.zero) {
          if (mounted) {
            CustomAlertDialog.show(
              context: context,
              title: 'Error',
              message:
                  'Invalid video duration. Using default duration of 15 seconds.',
              onPressed: () {
                _progressControllers[_currentIndex] = AnimationController(
                  vsync: this,
                  duration: const Duration(seconds: 15),
                );
                _chewieController = ChewieController(
                  videoPlayerController: _videoPlayerController!,
                  autoPlay: true,
                  looping: true,
                  showControls: false,
                  aspectRatio: _videoPlayerController!.value.aspectRatio.clamp(
                    0.5,
                    2.0,
                  ),
                );
                setState(() => _isLoading = false);
                _startProgressForCurrentSequence();
              },
            );
          }
          return;
        }

        _progressControllers[_currentIndex] = AnimationController(
          vsync: this,
          duration: videoDuration,
        );

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: true,
          showControls: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio.clamp(
            0.5,
            2.0,
          ),
        );
      } catch (e) {
        if (mounted) {
          CustomAlertDialog.show(
            context: context,
            title: 'Error',
            message: 'Failed to load video: $e',
          );
        }
        _progressControllers[_currentIndex] = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 15),
        );
      }
    } else {
      _progressControllers[_currentIndex] = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 15),
      );
    }

    _nextVideoPlayerController?.dispose();
    _nextChewieController?.dispose();
    _nextVideoPlayerController = null;
    _nextChewieController = null;
    if (_nextIndex != _currentIndex && widget.stories[_nextIndex].isVideo) {
      try {
        _nextVideoPlayerController = VideoPlayerController.network(
          widget.stories[_nextIndex].imageUrl,
        );
        await _nextVideoPlayerController!.initialize();
        if (_isDisposed) {
          _nextVideoPlayerController?.dispose();
          _nextChewieController?.dispose();
          return;
        }
        _nextChewieController = ChewieController(
          videoPlayerController: _nextVideoPlayerController!,
          autoPlay: false,
          looping: false,
          showControls: false,
          aspectRatio: _nextVideoPlayerController!.value.aspectRatio.clamp(
            0.5,
            2.0,
          ),
        );
      } catch (e) {
        if (mounted) {
          CustomAlertDialog.show(
            context: context,
            title: 'Error',
            message: 'Failed to preload next video: $e',
          );
        }
        _nextVideoPlayerController?.dispose();
        _nextChewieController?.dispose();
        _nextVideoPlayerController = null;
        _nextChewieController = null;
      }
    }

    _prevVideoPlayerController?.dispose();
    _prevChewieController?.dispose();
    _prevVideoPlayerController = null;
    _prevChewieController = null;
    if (_prevIndex != _currentIndex && widget.stories[_prevIndex].isVideo) {
      try {
        _prevVideoPlayerController = VideoPlayerController.network(
          widget.stories[_prevIndex].imageUrl,
        );
        await _prevVideoPlayerController!.initialize();
        if (_isDisposed) {
          _prevVideoPlayerController?.dispose();
          _prevChewieController?.dispose();
          return;
        }
        _prevChewieController = ChewieController(
          videoPlayerController: _prevVideoPlayerController!,
          autoPlay: false,
          looping: false,
          showControls: false,
          aspectRatio: _prevVideoPlayerController!.value.aspectRatio.clamp(
            0.5,
            2.0,
          ),
        );
      } catch (e) {
        if (mounted) {
          CustomAlertDialog.show(
            context: context,
            title: 'Error',
            message: 'Failed to preload previous video: $e',
          );
        }
        _prevVideoPlayerController?.dispose();
        _prevChewieController?.dispose();
        _prevVideoPlayerController = null;
        _prevChewieController = null;
      }
    }

    setState(() => _isLoading = false);
    _startProgressForCurrentSequence();
  }

  void _togglePlayPause() {
    if (_isDisposed) return;
    final story = widget.stories[_currentIndex];
    if (story.isVideo && _videoPlayerController?.value.isInitialized == true) {
      setState(() {
        if (_isPlaying) {
          _videoPlayerController!.pause();
          _progressControllers[_currentIndex].stop();
        } else {
          _videoPlayerController!.play();
          _startProgressForCurrentSequence();
        }
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _handleDragStart(DragStartDetails details) {
    if (_isDisposed) return;
    setState(() {
      _isDragging = true;
      _dragOffset = 0.0;
    });
    _progressControllers[_currentIndex].stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isDisposed || !_isDragging) return;
    final width = MediaQuery.of(context).size.width;
    setState(() => _dragOffset += details.delta.dx / width);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isDisposed || !_isDragging) return;
    setState(() => _isDragging = false);
    if (_dragOffset.abs() > 0.3) {
      if (_dragOffset < 0 && _currentIndex < widget.stories.length - 1) {
        _nextStory();
      } else if (_dragOffset > 0 && _currentIndex > 0)
        _previousStory();
    } else if (details.primaryVelocity != null) {
      if (details.primaryVelocity! > 500 && _currentIndex > 0) {
        _previousStory();
      } else if (details.primaryVelocity! < -500 &&
          _currentIndex < widget.stories.length - 1)
        _nextStory();
    } else {
      _startProgressForCurrentSequence();
    }
    setState(() => _dragOffset = 0.0);
  }

  void _handleVerticalDrag(DragEndDetails details) {
    if (_isDisposed ||
        details.primaryVelocity == null ||
        details.primaryVelocity! <= 300) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _handleTap(TapDetails details) {
    if (_isDisposed) return;
    final width = MediaQuery.of(context).size.width;
    if (details.localPosition.dx < width * 0.3 && _currentIndex > 0) {
      _previousStory();
    } else if (details.localPosition.dx > width * 0.7 &&
        _currentIndex < widget.stories.length - 1)
      _nextStory();
    else if (widget.stories[_currentIndex].isVideo &&
        _videoPlayerController != null)
      _togglePlayPause();
  }

  String _formatPostedTime(DateTime postedAt) {
    final difference = DateTime.now().difference(postedAt);
    return difference.inHours > 0
        ? 'Posted ${difference.inHours} hours ago'
        : difference.inMinutes > 0
        ? 'Posted ${difference.inMinutes} minutes ago'
        : 'Posted ${difference.inSeconds} seconds ago';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= widget.stories.length) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    final story = widget.stories[_currentIndex];
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final dragFactor = _dragOffset.clamp(-1.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragStart: _handleDragStart,
        onHorizontalDragUpdate: _handleDragUpdate,
        onHorizontalDragEnd: _handleDragEnd,
        onVerticalDragEnd: _handleVerticalDrag,
        onTapUp:
            (details) =>
                _handleTap(TapDetails(localPosition: details.localPosition)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isDragging && _currentIndex > 0)
              Positioned(
                left: -width * (1.0 - dragFactor.abs()),
                top: 0,
                child: Opacity(
                  opacity: dragFactor.abs().clamp(0.0, 1.0),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child:
                        widget.stories[_prevIndex].isVideo &&
                                _prevChewieController != null
                            ? Chewie(controller: _prevChewieController!)
                            : CachedNetworkImage(
                              imageUrl: widget.stories[_prevIndex].imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (_, __, ___) => const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                            ),
                  ),
                ),
              ),
            Center(
              child: Transform(
                transform:
                    Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..translate(width * dragFactor * 0.5)
                      ..rotateY(dragFactor * 0.3)
                      ..scale(1.0 - dragFactor.abs() * 0.2),
                child:
                    (story.isVideo) && _chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : CachedNetworkImage(
                          imageUrl: story.imageUrl,
                          fit: BoxFit.cover,
                          placeholder:
                              (_, __) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                          errorWidget:
                              (_, __, ___) =>
                                  const Icon(Icons.error, color: Colors.red),
                        ),
              ),
            ),
            if (_isDragging && _currentIndex < widget.stories.length - 1)
              Positioned(
                right: -width * (1.0 - dragFactor.abs()),
                top: 0,
                child: Opacity(
                  opacity: dragFactor.abs().clamp(0.0, 1.0),
                  child: SizedBox(
                    width: width,
                    height: height,
                    child:
                        widget.stories[_nextIndex].isVideo &&
                                _nextChewieController != null
                            ? Chewie(controller: _nextChewieController!)
                            : CachedNetworkImage(
                              imageUrl: widget.stories[_nextIndex].imageUrl,
                              fit: BoxFit.cover,
                              placeholder:
                                  (_, __) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                              errorWidget:
                                  (_, __, ___) => const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                  ),
                            ),
                  ),
                ),
              ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            Positioned(
              top: 28,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.stories.length, (index) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: context.theme.grey.withOpacity(0.3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedBuilder(
                          animation: _progressControllers[index],
                          builder:
                              (_, __) => LinearProgressIndicator(
                                value:
                                    index < _currentIndex
                                        ? 1.0
                                        : index == _currentIndex
                                        ? _progressControllers[index].value
                                        : 0.0,
                                backgroundColor: context.theme.grey.withOpacity(
                                  0.3,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  context.theme.white,
                                ),
                              ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Positioned(
              top: 40,
              left: 8,
              right: 8,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: CachedNetworkImageProvider(
                          story.avatarUrl,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: TextStyle(
                              color: context.theme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatPostedTime(story.postedAt),
                            style: TextStyle(
                              color: context.theme.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: context.theme.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            if ((story.isVideo) && !_isPlaying)
              Center(
                child: Icon(
                  Icons.play_arrow,
                  color: context.theme.white.withOpacity(0.7),
                  size: 60,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TapDetails {
  final Offset localPosition;

  const TapDetails({required this.localPosition});
}
