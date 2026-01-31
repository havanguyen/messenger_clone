import 'package:hive_flutter/adapters.dart';
import 'package:messenger_clone/common/constants/database_constants.dart';
import 'package:messenger_clone/common/services/common_function.dart';
import 'package:messenger_clone/common/services/date_time_format.dart';
import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:messenger_clone/features/messages/enum/message_status.dart';
import 'package:uuid/uuid.dart';

part 'message_model.g.dart';

@HiveType(typeId: 0)
class MessageModel extends HiveObject {
  @HiveField(0)
  String id;
  late final String idFrom;
  @HiveField(1)
  DateTime createdAt;
  @HiveField(2)
  final String content;
  @HiveField(3)
  final String type;
  @HiveField(4)
  final String groupMessagesId;
  @HiveField(5)
  List<String> reactions;
  @HiveField(6)
  MessageStatus? status;
  @HiveField(7)
  List<User> usersSeen;
  @HiveField(8)
  final User sender;

  MessageModel({
    String? id,
    required this.sender,
    required this.content,
    required this.type,
    required this.groupMessagesId,
    DateTime? createdAt,
    this.reactions = const [],
    this.status,
    this.usersSeen = const [],
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().toUtc(),
       idFrom = sender.id;

  Map<String, dynamic> toJson() {
    return {
      'sender': idFrom,
      DatabaseConstants.content: content,
      DatabaseConstants.type: type,
      DatabaseConstants.groupMessagesId: groupMessagesId,
      'reactions': CommonFunction.reactionsToString(reactions),
      'usersSeen': usersSeen.map((e) => e.id).toList(),
    };
  }

  void addReaction(String reaction) {
    reactions.add(reaction);
  }

  void addUserSeen(User user) {
    if (!isSeenBy(user.id)) {
      usersSeen.add(user);
    }
  }

  bool isSeenBy(String userId) {
    return usersSeen.any((element) => element.id == userId);
  }

  bool isContains(String id) {
    return usersSeen.any((element) => element.id == id);
  }

  DateTime get vietnamTime {
    final utcTime = createdAt.toUtc();
    return utcTime.add(const Duration(hours: 7));
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    // Determine ID field (Supabase uses 'id', Appwrite uses '$id')
    final id = map['id'] ?? map['\$id'] ?? '';
    final createdAt = map['createdAt'] ?? map['\$createdAt'];

    MessageModel result = MessageModel(
      sender: User.fromMap(
        map['sender'] is Map ? map['sender'] : {'id': map['sender']},
      ), // Supabase might return ID or object
      content: map[DatabaseConstants.content] as String? ?? '',
      type: map[DatabaseConstants.type] as String? ?? 'text',
      groupMessagesId: map[DatabaseConstants.groupMessagesId] as String? ?? '',
      reactions: CommonFunction.reactionsFromString(map['reactions']),
      id: id as String,
      usersSeen:
          (map['usersSeen'] as List<dynamic>?)
              ?.map((e) => User.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

    result.createdAt = DateTimeFormat.parseToDateTime(createdAt);
    return result;
  }

  factory MessageModel.fromJson(Map<String, dynamic> map) {
    return MessageModel.fromMap(map);
  }

  //copyWith
  MessageModel copyWith({
    String? id,
    User? sender,
    DateTime? createdAt,
    String? content,
    String? type,
    String? groupMessagesId,
    List<String>? reactions,
    MessageStatus? status,
    List<User>? usersSeen,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      content: content ?? this.content,
      type: type ?? this.type,
      groupMessagesId: groupMessagesId ?? this.groupMessagesId,
      reactions: reactions ?? this.reactions,
      status: status ?? this.status,
      usersSeen: usersSeen ?? this.usersSeen,
    );
  }
}
