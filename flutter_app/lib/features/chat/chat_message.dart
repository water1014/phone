import 'dart:convert';

class ChatMessageRecord {
  const ChatMessageRecord({
    required this.text,
    required this.mine,
    required this.createdAt,
    this.reasoning,
    this.isSystem = false,
    this.isTyping = false,
    this.inputTokens,
    this.outputTokens,
    this.imagePath,
  });

  final String text;
  final bool mine;
  final DateTime createdAt;
  final String? reasoning;
  final bool isSystem;
  final bool isTyping;
  final int? inputTokens;
  final int? outputTokens;
  final String? imagePath;

  Map<String, dynamic> toJson() => {
    'text': text,
    'mine': mine,
    'createdAt': createdAt.toIso8601String(),
    'reasoning': reasoning,
    'isSystem': isSystem,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'imagePath': imagePath,
  };

  factory ChatMessageRecord.fromJson(Map<String, dynamic> json) =>
      ChatMessageRecord(
        text: json['text'] as String? ?? '',
        mine: json['mine'] as bool? ?? false,
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
        reasoning: json['reasoning'] as String?,
        isSystem: json['isSystem'] as bool? ?? false,
        inputTokens: json['inputTokens'] as int?,
        outputTokens: json['outputTokens'] as int?,
        imagePath: json['imagePath'] as String?,
      );

  static String encodeList(List<ChatMessageRecord> messages) =>
      jsonEncode(messages.map((message) => message.toJson()).toList());

  static List<ChatMessageRecord> decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ChatMessageRecord.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
