import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger_clone/core/widgets/elements/video_player_preview_widget.dart';
import 'package:messenger_clone/features/messages/presentation/bloc/message_bloc.dart';

import 'dart:io';

import 'package:messenger_clone/core/utils/custom_theme_extension.dart';

class CustomMessagesBottomBar extends StatefulWidget {
  final TextEditingController textController;
  final void Function()? onSendMessage;
  final void Function(XFile media)? onSendMediaMessage;
  const CustomMessagesBottomBar({
    super.key,
    required this.textController,
    this.onSendMessage,
    this.onSendMediaMessage,
  });

  @override
  State<CustomMessagesBottomBar> createState() =>
      _CustomMessagesBottomBarState();
}

class _CustomMessagesBottomBarState extends State<CustomMessagesBottomBar> {
  final FocusNode _focusNode = FocusNode();
  late bool _isFocused;
  late bool _isExpandedLeft;
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedMedias = [];
  bool _showMediaPreview = false;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _isFocused = false;
    _isExpandedLeft = false;
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    widget.textController.addListener(() {
      setState(() {});
    });
  }

  void _pickMedia() async {
    try {
      final List<XFile> pickedMedias = await _imagePicker.pickMultipleMedia();
      if (pickedMedias.isNotEmpty) {
        setState(() {
          _selectedMedias = pickedMedias;
          _showMediaPreview = true;
          _isVideo = pickedMedias.any((media) => _isVideoFile(media));
        });
      }
    } catch (e) {
      debugPrint('Error picking media: $e');
    }
  }

  void _captureImage() async {
    try {
      final XFile? capturedImage = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (capturedImage != null) {
        setState(() {
          _selectedMedias = [capturedImage];
          _showMediaPreview = true;
          _isVideo = false;
        });
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  void _recordVideo() async {
    try {
      final XFile? recordedVideo = await _imagePicker.pickVideo(
        source: ImageSource.camera,
      );
      if (recordedVideo != null) {
        setState(() {
          _selectedMedias = [recordedVideo];
          _showMediaPreview = true;
          _isVideo = true;
        });
      }
    } catch (e) {
      debugPrint('Error recording video: $e');
    }
  }

  bool _isVideoFile(XFile file) {
    final String path = file.path.toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.avi') ||
        (file.mimeType?.startsWith('video/') ?? false);
  }

  void _sendMedia() {
    if (_selectedMedias.isNotEmpty && widget.onSendMediaMessage != null) {
      for (var media in _selectedMedias) {
        widget.onSendMediaMessage!(media);
      }
      setState(() {
        _selectedMedias = [];
        _showMediaPreview = false;
      });
    }
  }

  void _cancelMediaSelection() {
    setState(() {
      _selectedMedias = [];
      _showMediaPreview = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMediaPreview) {
      return _buildMediaPreview(context);
    }

    return IconTheme(
      data: IconThemeData(color: context.theme.blue),
      child: Container(
        decoration: BoxDecoration(color: context.theme.appBar),
        height: 50,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(onPressed: () {}, icon: Icon(Icons.add_circle)),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(
                  onPressed: _captureImage,
                  icon: Icon(Icons.camera_alt),
                ),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(
                  onPressed: _recordVideo,
                  icon: Icon(Icons.videocam),
                ),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(
                  onPressed: _pickMedia,
                  icon: Icon(Icons.photo_library),
                ),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox()
                : IconButton(onPressed: () {}, icon: Icon(Icons.mic)),
            (_isFocused && _isExpandedLeft == false)
                ? SizedBox(
                  width: 30,
                  child: IconButton(
                    padding: EdgeInsets.all(0),
                    onPressed: () {
                      setState(() {
                        _isExpandedLeft = !_isExpandedLeft;
                      });
                    },
                    icon: Icon(Icons.keyboard_arrow_right),
                  ),
                )
                : SizedBox(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  onTap: () {
                    setState(() {
                      _isExpandedLeft = false;
                    });
                  },
                  focusNode: _focusNode,
                  controller: widget.textController,
                  style: TextStyle(
                    color: context.theme.textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    filled: true,
                    fillColor: context.theme.grey,
                    hintText: "Nháº¯n tin",
                    hintStyle: TextStyle(color: context.theme.textColor),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 0,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                if (widget.textController.text.isNotEmpty) {
                  widget.onSendMessage?.call();
                  _focusNode.requestFocus();
                } else {
                  context.read<MessageBloc>().add(MessageSendEvent("ðŸ‘"));
                }
              },
              icon: Icon(
                widget.textController.text.isNotEmpty
                    ? Icons.send
                    : Icons.thumb_up_alt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    return Container(
      color: context.theme.appBar,
      height: 200,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedMedias.length,
              itemBuilder: (context, index) {
                final media = _selectedMedias[index];
                final bool isVideoFile = _isVideoFile(media);

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            isVideoFile
                                ? VideoPlayerPreviewWidget(path: media.path)
                                : Image.file(
                                  File(media.path),
                                  height: 150,
                                  width: 150,
                                  fit: BoxFit.cover,
                                ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMedias.removeAt(index);
                              if (_selectedMedias.isEmpty) {
                                _showMediaPreview = false;
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _cancelMediaSelection,
                  child: Text('Cancel'),
                ),
                SizedBox(width: 8),
                ElevatedButton(onPressed: _sendMedia, child: Text('Send')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


