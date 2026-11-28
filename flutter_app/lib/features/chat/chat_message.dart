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
    this.stickerUrl,
    this.audioPath,
    this.audioDurationMs,
    this.attachmentPath,
    this.attachmentName,
    this.attachmentSize,
    this.alternateReplies = const [],
    this.selectedAlternative = 0,
    this.replyToText,
    this.replyToMine,
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
  final String? stickerUrl;
  final String? audioPath;
  final int? audioDurationMs;
  final String? attachmentPath;
  final String? attachmentName;
  final int? attachmentSize;
  final List<String> alternateReplies;
  final int selectedAlternative;
  final String? replyToText;
  final bool? replyToMine;

  Map<String, dynamic> toJson() => {
    'text': text,
    'mine': mine,
    'createdAt': createdAt.toIso8601String(),
    'reasoning': reasoning,
    'isSystem': isSystem,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'imagePath': imagePath,
    'stickerUrl': stickerUrl,
    'audioPath': audioPath,
    'audioDurationMs': audioDurationMs,
    'attachmentPath': attachmentPath,
    'attachmentName': attachmentName,
    'attachmentSize': attachmentSize,
    'alternateReplies': alternateReplies,
    'selectedAlternative': selectedAlternative,
    'replyToText': replyToText,
    'replyToMine': replyToMine,
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
        stickerUrl: json['stickerUrl'] as String?,
        audioPath: json['audioPath'] as String?,
        audioDurationMs: json['audioDurationMs'] as int?,
        attachmentPath: json['attachmentPath'] as String?,
        attachmentName: json['attachmentName'] as String?,
        attachmentSize: json['attachmentSize'] as int?,
        alternateReplies: (json['alternateReplies'] as List<dynamic>?)?.whereType<String>().toList() ?? const [],
        selectedAlternative: json['selectedAlternative'] as int? ?? 0,
        replyToText: json['replyToText'] as String?,
        replyToMine: json['replyToMine'] as bool?,
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
