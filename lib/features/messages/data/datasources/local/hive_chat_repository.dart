import 'package:hive_flutter/adapters.dart';
import 'package:messenger_clone/features/messages/domain/models/message_model.dart';

class HiveChatRepository {
  static final HiveChatRepository instance = HiveChatRepository._internal();
  static const String _boxName = 'messagesBox';
  late final Future<Box<List>> _box;

  factory HiveChatRepository() {
    return instance;
  }

  HiveChatRepository._internal() {
    _box = _initializeBox();
  }

  Future<Box<List>> _initializeBox() async {
    return await Hive.openBox<List>(_boxName);
  }

  Future<void> saveMessages(String groupId, List<MessageModel> messages) async {
    final box = await _box;
    await box.put(groupId, messages);
  }

  Future<List<MessageModel>?> getMessages(String groupId) async {
    final box = await _box;
    final result = box.get(groupId, defaultValue: [])?.cast<MessageModel>();
    return result;
  }

  Future<void> addMessage(String groupId, List<MessageModel> messages) async {
    final box = await _box;
    final existingMessages =
        box.get(groupId, defaultValue: [])?.cast<MessageModel>() ?? [];
    existingMessages.addAll(messages);
    box.put(groupId, existingMessages);
    return box.put(groupId, existingMessages);
  }

  Future<void> clearMessages(String groupId) async {
    final box = await _box;
    await box.delete(groupId);
  }

  Future<void> clearAllMessages() async {
    final box = await _box;
    await box.clear();
  }
}
