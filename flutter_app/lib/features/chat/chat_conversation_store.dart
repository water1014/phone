import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'chat_message.dart';
import 'chat_message_store.dart';

class ChatConversationRecord {
  const ChatConversationRecord({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.summary = '',
  });

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String summary;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'summary': summary,
  };

  factory ChatConversationRecord.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ChatConversationRecord(
      id: json['id'] as String? ?? 'conversation',
      title: json['title'] as String? ?? '新聊天',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      summary: json['summary'] as String? ?? '',
    );
  }

  ChatConversationRecord copyWith({
    String? title,
    DateTime? updatedAt,
    String? summary,
  }) => ChatConversationRecord(
    id: id,
    title: title ?? this.title,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    summary: summary ?? this.summary,
  );
}

abstract final class ChatConversationStore {
  static const _indexKey = 'chat.conversations.v1';
  static const _activeKey = 'chat.activeConversation.v1';
  static const _contextLimitKey = 'chat.contextWindowTokens.v1';
  static String _messagesKey(String id) => 'chat.messages.v2.$id';

  static String _contextLimitKeyFor(String modelKey) =>
      '$_contextLimitKey.${Uri.encodeComponent(modelKey)}';

  static Future<int> loadContextLimit(String modelKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_contextLimitKeyFor(modelKey)) ?? 32768;
  }

  static Future<void> saveContextLimit(String modelKey, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_contextLimitKeyFor(modelKey), value);
  }

  static Future<List<ChatConversationRecord>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_indexKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatConversationRecord.fromJson)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (_) {
      return const [];
    }
  }

  static Future<ChatConversationRecord> ensureActive() async {
    final prefs = await SharedPreferences.getInstance();
    var conversations = await loadConversations();
    if (conversations.isEmpty) {
      final legacyMessages = await ChatMessageStore.load();
      final now = DateTime.now();
      final firstUserMessages = legacyMessages.where((m) => m.mine && m.text.trim().isNotEmpty).toList();
      final firstUserMessage = firstUserMessages.isEmpty ? null : firstUserMessages.first;
      final title = firstUserMessage == null
          ? '旧聊天记录'
          : _titleFrom(firstUserMessage.text);
      final initial = ChatConversationRecord(
        id: 'conversation_legacy',
        title: title,
        createdAt: legacyMessages.isEmpty ? now : legacyMessages.first.createdAt,
        updatedAt: legacyMessages.isEmpty ? now : legacyMessages.last.createdAt,
      );
      conversations = [initial];
      await prefs.setString(_messagesKey(initial.id), ChatMessageRecord.encodeList(legacyMessages));
      await _writeIndex(prefs, conversations);
      await prefs.setString(_activeKey, initial.id);
      return initial;
    }

    final activeId = prefs.getString(_activeKey);
    for (final conversation in conversations) {
      if (conversation.id == activeId) return conversation;
    }
    final active = conversations.first;
    await prefs.setString(_activeKey, active.id);
    return active;
  }

  static Future<List<ChatMessageRecord>> loadMessages(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return ChatMessageRecord.decodeList(prefs.getString(_messagesKey(id)));
  }

  static Future<void> saveMessages(String id, List<ChatMessageRecord> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_messagesKey(id), ChatMessageRecord.encodeList(messages));
    final conversations = await loadConversations();
    final index = conversations.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final current = conversations[index];
    var title = current.title;
    if (title == '新聊天') {
      final firstUserMessages = messages.where((item) => item.mine && item.text.trim().isNotEmpty).toList();
      final firstUserMessage = firstUserMessages.isEmpty ? null : firstUserMessages.first;
      if (firstUserMessage != null) title = _titleFrom(firstUserMessage.text);
    }
    conversations[index] = current.copyWith(title: title, updatedAt: DateTime.now());
    await _writeIndex(prefs, conversations);
  }

  static Future<ChatConversationRecord> create({String summary = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final id = 'conversation_${now.microsecondsSinceEpoch}';
    final record = ChatConversationRecord(
      id: id,
      title: '新聊天',
      createdAt: now,
      updatedAt: now,
      summary: summary,
    );
    final conversations = await loadConversations();
    conversations.insert(0, record);
    await _writeIndex(prefs, conversations);
    await prefs.setString(_activeKey, id);
    await prefs.setString(_messagesKey(id), '[]');
    return record;
  }

  static Future<void> switchTo(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey, id);
  }

  static String _titleFrom(String text) {
    final compact = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= 22) return compact;
    return '${compact.substring(0, 22)}…';
  }

  static Future<void> _writeIndex(
    SharedPreferences prefs,
    List<ChatConversationRecord> conversations,
  ) => prefs.setString(
    _indexKey,
    jsonEncode(conversations.map((item) => item.toJson()).toList()),
  );
}
