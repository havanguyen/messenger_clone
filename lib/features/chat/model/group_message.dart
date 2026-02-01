import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class GroupMessage {
  final bool isGroup;
  final String groupMessagesId;
  final MessageModel? lastMessage;
  final String? avatarGroupUrl;
  final List<User> users;
  final String? groupName;
  final String groupId;
  final String? createrId;

  GroupMessage({
    required this.groupMessagesId,
    this.lastMessage,
    this.users = const [],
    this.isGroup = false,
    this.avatarGroupUrl,
    this.groupName,
    required this.groupId,
    this.createrId,
  }) : assert(
         isGroup == false || groupName != null,
         'groupName must not be null if isGroup is true',
       ),
       assert(
         isGroup == false || createrId != null,
         'createrId must not be null if isGroup is true',
       );

  Map<String, dynamic> toJson() {
    return {
      'lastMessage': lastMessage?.toJson(),
      'users': users.map((e) => e.id).toList(),
      'isGroup': isGroup,
      'avatarGroupUrl': avatarGroupUrl,
      'groupName': groupName,
      'groupId': groupId,
      'createrId': createrId,
    };
  }

  GroupMessage copyWith({
    String? groupMessagesId,
    MessageModel? lastMessage,
    List<User>? users,
    bool? isGroup,
    String? avatarGroupUrl,
    String? groupName,
    String? groupId,
    String? createrId,
  }) {
    return GroupMessage(
      groupMessagesId: groupMessagesId ?? this.groupMessagesId,
      lastMessage: lastMessage ?? this.lastMessage,
      users: users ?? this.users,
      isGroup: isGroup ?? this.isGroup,
      avatarGroupUrl: avatarGroupUrl ?? this.avatarGroupUrl,
      groupName: groupName ?? this.groupName,
      groupId: groupId ?? this.groupId,
      createrId: createrId ?? this.createrId,
    );
  }

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      groupMessagesId: json['\$id'] as String,
      lastMessage:
          json['lastMessage'] != null
              ? MessageModel.fromMap(
                json['lastMessage'] as Map<String, dynamic>,
              )
              : null,
      users:
          (json['users'] as List<dynamic>?)?.map((e) {
            if (e is Map<String, dynamic>) {
              return User.fromMap(e);
            } else if (e is String) {
              return User.createMeUser(e);
            }
            return User.createMeUser('');
          }).toList() ??
          [],
      isGroup: json['isGroup'] as bool? ?? false,
      avatarGroupUrl: json['avatarGroupUrl'] as String?,
      groupName: json['groupName'] as String?,
      groupId: json['groupId'] as String,
      createrId: json['createrId'] as String?,
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMessage &&
          runtimeType == other.runtimeType &&
          groupMessagesId == other.groupMessagesId;

  @override
  int get hashCode => groupMessagesId.hashCode;
}
