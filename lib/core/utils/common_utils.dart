import 'dart:convert';

import 'package:messenger_clone/features/chat/model/user.dart';
import 'package:crypto/crypto.dart';

class CommonFunction {
  static List<User> getOthers(List<User> users, String currentUserId) {
    return users.where((user) => user.id != currentUserId).toList();
  }

  static List<String> getOthersId(List<User> users, String currentUserId) {
    if (users.length == 1) {
      return [users[0].id];
    }
    return users
        .where((user) => user.id != currentUserId)
        .map((user) => user.id)
        .toList();
  }

  static List<String> getAllUserId(List<User> users) {
    return users.map((user) => user.id).toList();
  }

  static String generateGroupId(List<String> userIds) {
    userIds.sort();

    final combinedIds = userIds.join(',');

    final bytes = utf8.encode(combinedIds);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  static List<String> reactionsFromString(String? reactions) {
    if (reactions == null || reactions.isEmpty) {
      return [];
    }
    return reactions.split(',').map((reaction) => reaction.trim()).toList();
  }

  static String reactionsToString(List<String> reactions) {
    return reactions.join(',');
  }
}
