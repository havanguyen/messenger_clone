/// Chat domain entities - Re-export from data models
///
/// In this codebase, we keep the existing models as-is since they are
/// already well-structured and used with Hive for local storage.
/// The entities layer serves as a clean interface.
library;

export 'package:messenger_clone/features/chat/model/user.dart';
export 'package:messenger_clone/features/chat/model/group_message.dart';
export 'package:messenger_clone/features/chat/model/chat_item.dart';
