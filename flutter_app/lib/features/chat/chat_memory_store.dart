import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'chat_conversation_store.dart';

class ChatMemoryRecord {
  const ChatMemoryRecord({
    required this.id,
    required this.content,
    required this.category,
    required this.sourceConversationId,
    required this.sourceCreatedAt,
    required this.sourceText,
    required this.createdAt,
    this.locked = false,
    this.origin = 'auto',
  });

  final String id;
  final String content;
  final String category;
  final String sourceConversationId;
  final DateTime sourceCreatedAt;
  final String sourceText;
  final DateTime createdAt;
  final bool locked;
  final String origin;

  ChatMemoryRecord copyWith({
    String? content,
    String? category,
    bool? locked,
  }) => ChatMemoryRecord(
    id: id,
    content: content ?? this.content,
    category: category ?? this.category,
    sourceConversationId: sourceConversationId,
    sourceCreatedAt: sourceCreatedAt,
    sourceText: sourceText,
    createdAt: createdAt,
    locked: locked ?? this.locked,
    origin: origin,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'category': category,
    'sourceConversationId': sourceConversationId,
    'sourceCreatedAt': sourceCreatedAt.toIso8601String(),
    'sourceText': sourceText,
    'createdAt': createdAt.toIso8601String(),
    'locked': locked,
    'origin': origin,
  };

  factory ChatMemoryRecord.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return ChatMemoryRecord(
      id: json['id'] as String? ?? 'memory_${now.microsecondsSinceEpoch}',
      content: json['content'] as String? ?? '',
      category: json['category'] as String? ?? '重要记忆',
      sourceConversationId: json['sourceConversationId'] as String? ?? '',
      sourceCreatedAt: DateTime.tryParse(json['sourceCreatedAt'] as String? ?? '') ?? now,
      sourceText: json['sourceText'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      locked: json['locked'] as bool? ?? false,
      origin: json['origin'] as String? ?? 'auto',
    );
  }
}

class ChatHistoryMatch {
  const ChatHistoryMatch({
    required this.conversationTitle,
    required this.createdAt,
    required this.mine,
    required this.text,
    required this.score,
  });

  final String conversationTitle;
  final DateTime createdAt;
  final bool mine;
  final String text;
  final int score;
}

abstract final class ChatMemoryStore {
  static const _storageKey = 'chat.longTermMemories.v1';

  static Future<List<ChatMemoryRecord>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatMemoryRecord.fromJson)
          .where((item) => item.content.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _save(List<ChatMemoryRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  static String? _memoryCandidate(String text) {
    final value = text.trim();
    if (value.length < 5 || value.length > 1200) return null;
    final explicit = RegExp(
      r'^(?:请)?(?:帮我)?(?:记住|记一下|记下来|记得)：?\s*',
    );
    if (explicit.hasMatch(value)) {
      final cleaned = value.replaceFirst(explicit, '').trim();
      return cleaned.isEmpty ? value : cleaned;
    }
    final durableSignals = RegExp(
      r'(我喜欢|我不喜欢|我讨厌|我希望|我习惯|我偏好|以后不要|以后别|以后记得|请不要忘记|我的生日|我的名字|我的职业|我们的约定|我们约定|我们第一次|对我来说很重要)',
    );
    if (durableSignals.hasMatch(value)) return value;
    return null;
  }

  static String _categoryFor(String text) {
    if (RegExp(r'(喜欢|不喜欢|讨厌|偏好|习惯|希望)').hasMatch(text)) return '偏好习惯';
    if (RegExp(r'(生日|名字|职业|住在|家人|朋友)').hasMatch(text)) return '个人信息';
    if (RegExp(r'(约定|第一次|纪念|重要|那天|回忆)').hasMatch(text)) return '共同回忆';
    if (RegExp(r'(以后|记住|不要|别)').hasMatch(text)) return '重要约定';
    return '重要记忆';
  }

  static const _backfillKey = 'chat.longTermMemories.backfilled.v1';

  static Future<void> backfillFromArchive() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_backfillKey) == true) return;
    final records = await load();
    final knownSources = records
        .map((item) => '${item.sourceConversationId}:${item.sourceCreatedAt.microsecondsSinceEpoch}')
        .toSet();
    final conversations = await ChatConversationStore.loadConversations();
    for (final conversation in conversations) {
      final messages = await ChatConversationStore.loadMessages(conversation.id);
      for (final message in messages) {
        if (!message.mine || message.isSystem || message.isTyping) continue;
        final candidate = _memoryCandidate(message.text);
        if (candidate == null) continue;
        final sourceKey = '${conversation.id}:${message.createdAt.microsecondsSinceEpoch}';
        if (knownSources.contains(sourceKey)) continue;
        if (records.any((item) => item.sourceConversationId == conversation.id && item.content == candidate)) {
          knownSources.add(sourceKey);
          continue;
        }
        records.insert(0, ChatMemoryRecord(
          id: 'memory_${message.createdAt.microsecondsSinceEpoch}',
          content: candidate,
          category: _categoryFor(candidate),
          sourceConversationId: conversation.id,
          sourceCreatedAt: message.createdAt,
          sourceText: message.text,
          createdAt: DateTime.now(),
        ));
        knownSources.add(sourceKey);
      }
    }
    await _save(records);
    await prefs.setBool(_backfillKey, true);
  }

  static Future<void> captureUserMessage({
    required String text,
    required String conversationId,
    required DateTime createdAt,
  }) async {
    final candidate = _memoryCandidate(text);
    if (candidate == null) return;
    final records = await load();
    final sourceKey = '$conversationId:${createdAt.microsecondsSinceEpoch}';
    if (records.any((item) => '${item.sourceConversationId}:${item.sourceCreatedAt.microsecondsSinceEpoch}' == sourceKey)) {
      return;
    }
    if (records.any((item) => item.content == candidate && item.sourceConversationId == conversationId)) {
      return;
    }
    records.insert(0, ChatMemoryRecord(
      id: 'memory_${createdAt.microsecondsSinceEpoch}',
      content: candidate,
      category: _categoryFor(candidate),
      sourceConversationId: conversationId,
      sourceCreatedAt: createdAt,
      sourceText: text,
      createdAt: DateTime.now(),
    ));
    await _save(records);
  }

  static Future<void> addManual({
    required String content,
    String category = '重要记忆',
  }) async {
    final value = content.trim();
    if (value.isEmpty) return;
    final records = await load();
    records.insert(0, ChatMemoryRecord(
      id: 'memory_${DateTime.now().microsecondsSinceEpoch}',
      content: value,
      category: category,
      sourceConversationId: '',
      sourceCreatedAt: DateTime.now(),
      sourceText: value,
      createdAt: DateTime.now(),
      origin: 'manual',
    ));
    await _save(records);
  }

  static Future<void> update(ChatMemoryRecord updated) async {
    final records = await load();
    final index = records.indexWhere((item) => item.id == updated.id);
    if (index < 0) return;
    records[index] = updated;
    await _save(records);
  }

  static Future<void> delete(String id) async {
    final records = await load();
    records.removeWhere((item) => item.id == id && !item.locked);
    await _save(records);
  }

  static List<String> _queryTerms(String query) {
    final terms = <String>{};
    for (final match in RegExp(r'[a-zA-Z0-9_]{2,}|[\u4e00-\u9fff]{2,}').allMatches(query.toLowerCase())) {
      final value = match.group(0)!;
      if (value.length <= 5) {
        terms.add(value);
      } else {
        for (var size = 2; size <= 5; size++) {
          for (var i = 0; i + size <= value.length; i++) {
            terms.add(value.substring(i, i + size));
          }
        }
      }
    }
    return terms.toList();
  }

  static int _score(String source, List<String> terms, String query) {
    final value = source.toLowerCase();
    var score = value.contains(query.toLowerCase()) && query.trim().length >= 2 ? 8 : 0;
    for (final term in terms) {
      if (value.contains(term)) score += term.length >= 4 ? 3 : 1;
    }
    return score;
  }

  static Future<List<ChatMemoryRecord>> searchMemories(String query, {int limit = 4}) async {
    if (query.trim().length < 2) return const [];
    final terms = _queryTerms(query);
    final records = await load();
    final ranked = records
        .map((item) => (item: item, score: _score(item.content, terms, query)))
        .where((entry) => entry.score > 0)
        .toList()
      ..sort((a, b) {
        final score = b.score.compareTo(a.score);
        return score != 0 ? score : b.item.createdAt.compareTo(a.item.createdAt);
      });
    return ranked.take(limit).map((entry) => entry.item).toList();
  }

  static Future<List<ChatHistoryMatch>> searchOriginalMessages({
    required String query,
    required String activeConversationId,
    required Set<String> recentMessageKeys,
    int limit = 4,
  }) async {
    if (query.trim().length < 2) return const [];
    final terms = _queryTerms(query);
    final conversations = await ChatConversationStore.loadConversations();
    final matches = <ChatHistoryMatch>[];
    for (final conversation in conversations) {
      final messages = await ChatConversationStore.loadMessages(conversation.id);
      for (final message in messages) {
        if (message.isSystem || message.isTyping || message.text.trim().isEmpty) continue;
        final key = '${message.createdAt.microsecondsSinceEpoch}:${message.mine}:${message.text}';
        if (conversation.id == activeConversationId && recentMessageKeys.contains(key)) continue;
        final score = _score(message.text, terms, query);
        if (score < 3) continue;
        matches.add(ChatHistoryMatch(
          conversationTitle: conversation.title,
          createdAt: message.createdAt,
          mine: message.mine,
          text: message.text,
          score: score,
        ));
      }
    }
    matches.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score != 0 ? score : b.createdAt.compareTo(a.createdAt);
    });
    return matches.take(limit).toList();
  }
}
