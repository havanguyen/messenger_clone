import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_clone/core/widgets/elements/video_player_widget.dart';
import 'package:messenger_clone/features/messages/presentation/bloc/message_bloc.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';
import 'package:video_player/video_player.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import '../custom_text_style.dart';

class CustomMessageItem extends StatefulWidget {
  final bool isMe;
  final MessageModel message;
  const CustomMessageItem({
    super.key,
    required this.isMe,
    required this.message,
  });

  @override
  State<CustomMessageItem> createState() => _CustomMessageItemState();
}

class _CustomMessageItemState extends State<CustomMessageItem> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final messageBloc = context.read<MessageBloc>();
    List<String> reactions = widget.message.reactions;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: GestureDetector(
            onLongPress: () {
              showDialog<List<String>>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      contentPadding: EdgeInsets.all(5),
                      backgroundColor: context.theme.tileColor,
                      content: SizedBox(
                        width: 250,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,

                          children:
                              ['👍', '❤️', '😂', '😮', '😢', '👏'].map((
                                reaction,
                              ) {
                                return GestureDetector(
                                  onTap: () {
                                    messageBloc.add(
                                      AddReactionEvent(
                                        widget.message.id,
                                        reaction,
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  child: ContentText(
                                    reaction,
                                    fontSize: 22,
                                    overflow: TextOverflow.clip,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color:
                    widget.message.type == "image" ||
                            widget.message.type == "video"
                        ? null
                        : widget.isMe
                        ? context.theme.blue
                        : context.theme.grey,
                borderRadius: BorderRadius.all(Radius.circular(15)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                      widget.message.type == "image" ||
                              widget.message.type == "video"
                          ? MediaQuery.of(context).size.width * 0.6
                          : MediaQuery.of(context).size.width * 0.7,
                  maxHeight:
                      widget.message.type == "image" ||
                              widget.message.type == "video"
                          ? MediaQuery.of(context).size.width * 0.5
                          : double.infinity,
                  minWidth: 0,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _buildMessageContent(widget.message),
                ),
              ),
            ),
          ),
        ),
        if (reactions.isNotEmpty)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 2, horizontal: 5),
              decoration: BoxDecoration(
                color: context.theme.grey,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Wrap(
                spacing: 4.0,
                children: [
                  ...reactions.toSet().map(
                    (reaction) => ContentText(reaction, fontSize: 12),
                  ),
                  ContentText("${reactions.length}", fontSize: 12),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageContent(MessageModel message) {
    final messageBloc = context.read<MessageBloc>();
    if (messageBloc.state is! MessageLoaded) return Container();
    switch (message.type) {
      case "text":
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: ContentText(
            message.content,
            fontSize: 14,
            color: widget.isMe ? Colors.white : context.theme.textColor,
          ),
        );
      case "image":
        return Image.network(
          message.content,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(child: Icon(Icons.error, color: Colors.red));
          },
        );
      case "video":
        VideoPlayerController? videoPlayer =
            (messageBloc.state as MessageLoaded).videoPlayers[message.id];
        return VideoPlayerWidget(
          videoUrl: message.content,
          controller: videoPlayer,
          aspectRatio: 1 / 1.777777,
        );
      default:
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: ContentText(
            message.content,
            fontSize: 14,
            color: widget.isMe ? Colors.white : context.theme.textColor,
          ),
        );
    }
  }
}




