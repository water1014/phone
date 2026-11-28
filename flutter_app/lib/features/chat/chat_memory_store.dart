import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'chat_conversation_store.dart';
import 'chat_message.dart';

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
    this.pending = false,
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
  final bool pending;

  ChatMemoryRecord copyWith({
    String? content,
    String? category,
    bool? locked,
    bool? pending,
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
    pending: pending ?? this.pending,
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
    'pending': pending,
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
      pending: json['pending'] as bool? ?? false,
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

  static bool _isExplicitMemoryRequest(String text) => RegExp(
    r'^(?:请)?(?:帮我)?(?:记住|记一下|记下来|记得)：?\s*',
  ).hasMatch(text.trim());

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
          pending: !_isExplicitMemoryRequest(message.text),
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
      pending: !_isExplicitMemoryRequest(text),
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
        .where((item) => !item.pending)
        .map((item) {
          // Search both the editable memory and its untouched source message.
          // This lets a short memory remain discoverable through the wording
          // that originally appeared in the conversation archive.
          final searchableText = '${item.content}\\n${item.sourceText}';
          final baseScore = _score(searchableText, terms, query);
          return (
            item: item,
            score: baseScore + (item.locked && baseScore > 0 ? 5 : 0),
          );
        })
        .where((entry) => entry.score > 0)
        .toList()
      ..sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
        return b.item.createdAt.compareTo(a.item.createdAt);
      });
    return ranked.take(limit).map((entry) => entry.item).toList();
  }

  static const _originalIndexKey = 'chat.originalMessageIndex.v1';
  static const _originalIndexBuiltKey = 'chat.originalMessageIndex.built.v1';

  static Set<String> _indexTerms(String text) {
    final terms = <String>{};
    final tokens = RegExp(r'[a-zA-Z0-9_]+|[\\u4e00-\\u9fff]+');
    for (final match in tokens.allMatches(text.toLowerCase())) {
      final token = match.group(0)!;
      if (RegExp(r'^[a-z0-9_]+
    return {
      'title': title,
      'messageCount': messages.length,
      'postings': postings,
    };
  }

  /// Builds a lightweight inverted index once for existing archives.
  /// The index stores term-to-position mappings only, never a second copy
  /// of message text. Original messages remain in ChatConversationStore.
  static Future<void> ensureOriginalMessageIndex() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_originalIndexBuiltKey) == true) return;
    final conversations = await ChatConversationStore.loadConversations();
    final index = <String, dynamic>{};
    for (final conversation in conversations) {
      final messages = await ChatConversationStore.loadMessages(conversation.id);
      index[conversation.id] = _buildConversationIndex(conversation.title, messages);
    }
    await prefs.setString(_originalIndexKey, jsonEncode(index));
    await prefs.setBool(_originalIndexBuiltKey, true);
  }

  /// Refreshes only the conversation that was just persisted.
  static Future<void> updateOriginalMessageIndex({
    required String conversationId,
    required String title,
    required List<ChatMessageRecord> messages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await ensureOriginalMessageIndex();
    final raw = prefs.getString(_originalIndexKey);
    Map<String, dynamic> index;
    try {
      index = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      index = <String, dynamic>{};
    }
    index[conversationId] = _buildConversationIndex(title, messages);
    await prefs.setString(_originalIndexKey, jsonEncode(index));
  }

  static Future<List<ChatHistoryMatch>> searchOriginalMessages({
    required String query,
    required String activeConversationId,
    required Set<String> recentMessageKeys,
    int limit = 4,
  }) async {
    if (query.trim().length < 2) return const [];
    await ensureOriginalMessageIndex();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_originalIndexKey);
    if (raw == null || raw.isEmpty) return const [];
    Map<String, dynamic> index;
    try {
      index = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const [];
    }

    final terms = _queryTerms(query);
    final candidateTerms = _indexTerms(query);
    final conversations = await ChatConversationStore.loadConversations();
    final matches = <ChatHistoryMatch>[];
    for (final conversation in conversations) {
      final indexed = index[conversation.id];
      if (indexed is! Map) continue;
      final rawPostings = indexed['postings'];
      if (rawPostings is! Map) continue;
      final candidatePositions = <int>{};
      for (final term in candidateTerms) {
        final positions = rawPostings[term];
        if (positions is List) {
          candidatePositions.addAll(positions.whereType<num>().map((value) => value.toInt()));
        }
      }
      if (candidatePositions.isEmpty) continue;

      final messages = await ChatConversationStore.loadMessages(conversation.id);
      for (final position in candidatePositions) {
        if (position < 0 || position >= messages.length) continue;
        final message = messages[position];
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
).hasMatch(token)) {
        terms.add(token);
        if (token.length > 10) {
          terms.add(token.substring(0, 3));
        }
      } else {
        for (var i = 0; i + 1 < token.length; i++) {
          terms.add(token.substring(i, i + 2));
        }
      }
    }
    return terms;
  }

  static Map<String, dynamic> _buildConversationIndex(
    String title,
    List<ChatMessageRecord> messages,
  ) {
    final postings = <String, List<int>>{};
    for (var index = 0; index < messages.length; index++) {
      final message = messages[index];
      if (message.isSystem || message.isTyping || message.text.trim().isEmpty) continue;
      for (final term in _indexTerms(message.text)) {
        (postings[term] ??= <int>[]).add(index);
      }
    }
    return {
      'title': title,
      'messageCount': messages.length,
      'postings': postings,
    };
  }

  /// Builds a lightweight inverted index once for existing archives.
  /// The index stores term-to-position mappings only, never a second copy
  /// of message text. Original messages remain in ChatConversationStore.
  static Future<void> ensureOriginalMessageIndex() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_originalIndexBuiltKey) == true) return;
    final conversations = await ChatConversationStore.loadConversations();
    final index = <String, dynamic>{};
    for (final conversation in conversations) {
      final messages = await ChatConversationStore.loadMessages(conversation.id);
      index[conversation.id] = _buildConversationIndex(conversation.title, messages);
    }
    await prefs.setString(_originalIndexKey, jsonEncode(index));
    await prefs.setBool(_originalIndexBuiltKey, true);
  }

  /// Refreshes only the conversation that was just persisted.
  static Future<void> updateOriginalMessageIndex({
    required String conversationId,
    required String title,
    required List<ChatMessageRecord> messages,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await ensureOriginalMessageIndex();
    final raw = prefs.getString(_originalIndexKey);
    Map<String, dynamic> index;
    try {
      index = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      index = <String, dynamic>{};
    }
    index[conversationId] = _buildConversationIndex(title, messages);
    await prefs.setString(_originalIndexKey, jsonEncode(index));
  }

  static Future<List<ChatHistoryMatch>> searchOriginalMessages({
    required String query,
    required String activeConversationId,
    required Set<String> recentMessageKeys,
    int limit = 4,
  }) async {
    if (query.trim().length < 2) return const [];
    await ensureOriginalMessageIndex();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_originalIndexKey);
    if (raw == null || raw.isEmpty) return const [];
    Map<String, dynamic> index;
    try {
      index = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return const [];
    }

    final terms = _queryTerms(query);
    final conversations = await ChatConversationStore.loadConversations();
    final matches = <ChatHistoryMatch>[];
    for (final conversation in conversations) {
      final indexed = index[conversation.id];
      if (indexed is! Map) continue;
      final rawPostings = indexed['postings'];
      if (rawPostings is! Map) continue;
      final candidatePositions = <int>{};
      for (final term in terms) {
        final positions = rawPostings[term];
        if (positions is List) {
          candidatePositions.addAll(positions.whereType<num>().map((value) => value.toInt()));
        }
      }
      if (candidatePositions.isEmpty) continue;

      final messages = await ChatConversationStore.loadMessages(conversation.id);
      for (final position in candidatePositions) {
        if (position < 0 || position >= messages.length) continue;
        final message = messages[position];
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
