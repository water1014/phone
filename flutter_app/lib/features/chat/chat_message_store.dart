import 'package:shared_preferences/shared_preferences.dart';
import 'chat_message.dart';

abstract final class ChatMessageStore {
  static const _storageKey = 'chat.messages.v1';

  static Future<List<ChatMessageRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ChatMessageRecord.decodeList(prefs.getString(_storageKey));
  }

  static Future<void> save(List<ChatMessageRecord> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, ChatMessageRecord.encodeList(messages));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
