import 'package:flutter/material.dart';
import 'package:messenger_clone/core/utils/custom_theme_extension.dart';
import 'package:messenger_clone/core/utils/common_utils.dart';
import 'package:messenger_clone/core/utils/date_time_extensions.dart';
import 'package:messenger_clone/core/local/hive_storage.dart';
import 'package:messenger_clone/features/chat/model/user.dart';

import '../../../core/widgets/custom_text_style.dart';
import '../../../core/widgets/elements/custom_round_avatar.dart';
import '../model/chat_item.dart';

class ChatItemWidget extends StatelessWidget {
  final ChatItem item;
  final VoidCallback? onTap;
  final Function(ChatItem)? onLongPress;
  final double avatarRadius;

  const ChatItemWidget({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.avatarRadius = 30,
  });

  Future<String> _getCurrentUserId() async {
    return await HiveService.instance.getCurrentUserId();
  }

  String _getMessageContent(String currentUserId) {
    final lastMessage = item.groupMessage.lastMessage;
    if (lastMessage == null) return "";

    final List<User> users = item.groupMessage.users;
    late final String senderName;

    if (lastMessage.idFrom == currentUserId) {
      senderName = "Báº¡n";
    } else {
      senderName =
          users
              .firstWhere((user) => user.id == lastMessage.idFrom)
              .name
              .split(" ")
              .last;
    }

    switch (lastMessage.type) {
      case "text":
        return "$senderName: ${lastMessage.content}";
      case "image":
        return "$senderName: ÄÃ£ gá»­i má»™t áº£nh";
      case "video":
        return "$senderName: ÄÃ£ gá»­i má»™t video";
      default:
        return "$senderName: ÄÃ£ gá»­i má»™t tin nháº¯n";
    }
  }

  Widget _buildSeenIndicator(BuildContext context, String currentUserId) {
    final lastMessage = item.groupMessage.lastMessage;
    if (lastMessage == null || lastMessage.idFrom != currentUserId) {
      return const SizedBox.shrink();
    }

    final List<User> seenUsers =
        lastMessage.usersSeen
            .where((user) => user.id != currentUserId)
            .toList();

    if (seenUsers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child:
          seenUsers.length == 1
              ? CustomRoundAvatar(
                radius: 8,
                isActive: false,
                avatarUrl: seenUsers.first.photoUrl,
              )
              : Text(
                "${seenUsers.length}",
                style: TextStyle(
                  fontSize: 12,
                  color: context.theme.textColor.withOpacity(0.7),
                ),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getCurrentUserId(),
      builder: (context, currentUserIdSnapshot) {
        if (currentUserIdSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        if (currentUserIdSnapshot.hasError) {
          return Center(child: Text('Error: ${currentUserIdSnapshot.error}'));
        }

        final currentUserId = currentUserIdSnapshot.data!;
        List<User> others = CommonFunction.getOthers(
          item.groupMessage.users,
          currentUserId,
        );

        if (others.isEmpty) {
          others = [item.groupMessage.users.first];
        }
        final content = _getMessageContent(currentUserId);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 8,
          ),
          dense: true,
          onTap: onTap,
          onLongPress: () => onLongPress?.call(item),
          title: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: CustomRoundAvatar(
                  radius: avatarRadius,
                  isActive:
                      item.groupMessage.isGroup ? true : others.first.isActive,
                  avatarUrl:
                      item.groupMessage.isGroup
                          ? item.groupMessage.avatarGroupUrl
                          : others.first.photoUrl,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            item.groupMessage.isGroup
                                ? item.groupMessage.groupName ?? "Group"
                                : others.first.name,
                            style: TextStyle(
                              fontWeight:
                                  item.hasUnread
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                              fontSize: 18,
                              overflow: TextOverflow.ellipsis,
                              color: context.theme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: ContentText(
                                    content,
                                    color:
                                        item.hasUnread
                                            ? context.theme.textColor
                                            : context.theme.textColor
                                                .withOpacity(0.5),
                                    fontWeight:
                                        item.hasUnread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    fontSize: 16,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 4,
                                  left: 4,
                                  right: 4,
                                ),
                                child: Text(
                                  "Â·",
                                  style: TextStyle(
                                    color:
                                        item.hasUnread
                                            ? context.theme.textColor
                                            : context.theme.textColor
                                                .withOpacity(0.5),
                                    fontSize: 16,
                                    fontWeight:
                                        item.hasUnread
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ),
                              Text(
                                DateTimeFormat.dateTimeToString(
                                  item.vietnamTime,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      item.hasUnread
                                          ? context.theme.textColor
                                          : context.theme.textColor.withOpacity(
                                            0.5,
                                          ),
                                  fontWeight:
                                      item.hasUnread
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          trailing: Container(
            constraints: BoxConstraints(maxWidth: 40),
            child: _buildSeenIndicator(context, currentUserId),
          ),
        );
      },
    );
  }
}

