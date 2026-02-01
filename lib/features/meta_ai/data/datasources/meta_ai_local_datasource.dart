library;
import 'package:messenger_clone/features/meta_ai/data/meta_ai_message_hive.dart';
abstract class MetaAiLocalDataSource {
  Future<List<Map<String, dynamic>>> getLocalConversations();
  Future<void> saveConversations(List<Map<String, dynamic>> conversations);
  Future<void> saveMessages(
    String conversationId,
    List<Map<String, String>> messages,
  );
  Future<List<Map<String, String>>> getLocalMessages(String conversationId);
  Future<void> deleteLocalConversation(String conversationId);
  Future<void> clearAllData();
}
class MetaAiLocalDataSourceImpl implements MetaAiLocalDataSource {
  @override
  Future<List<Map<String, dynamic>>> getLocalConversations() async {
    return MetaAiServiceHive.getConversations();
  }

  @override
  Future<void> saveConversations(
    List<Map<String, dynamic>> conversations,
  ) async {
    await MetaAiServiceHive.saveConversations(conversations);
  }

  @override
  Future<void> saveMessages(
    String conversationId,
    List<Map<String, String>> messages,
  ) async {
    await MetaAiServiceHive.saveMessages(conversationId, messages);
  }

  @override
  Future<List<Map<String, String>>> getLocalMessages(
    String conversationId,
  ) async {
    return MetaAiServiceHive.getMessages(conversationId);
  }

  @override
  Future<void> deleteLocalConversation(String conversationId) async {
    await MetaAiServiceHive.deleteConversation(conversationId);
  }

  @override
  Future<void> clearAllData() async {
    await MetaAiServiceHive.clearAllBoxes();
  }
}
