import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ChatPreferences {
  const ChatPreferences({
    this.showAvatar = false,
    this.showName = true,
    this.showTime = true,
    this.compact = true,
    this.enterSend = true,
    this.showReasoning = true,
    this.narratorEnabled = true,
    this.additionalSystemPrompt = '',
    this.worldbookEnabled = false,
    this.worldbookJson = '',
    this.bubbleStyle = 0,
    this.showBubbles = true,
    this.replyLayout = 0,
    this.partnerName = '宋祁',
    this.myName = '我',
    this.partnerAvatarPath,
    this.myAvatarPath,
    this.chatWallpaperPath,
    this.fontSize = 14,
    this.bubbleRadius = 19,
    this.quickReplies = const ['在吗', '抱抱', '晚安'],
  });

  final bool showAvatar;
  final bool showName;
  final bool showTime;
  final bool compact;
  final bool enterSend;
  final bool showReasoning;
  final bool narratorEnabled;
  final String additionalSystemPrompt;
  final bool worldbookEnabled;
  final String worldbookJson;
  final int bubbleStyle;
  final bool showBubbles;
  final int replyLayout;
  final String partnerName;
  final String myName;
  final String? partnerAvatarPath;
  final String? myAvatarPath;
  final String? chatWallpaperPath;
  final double fontSize;
  final double bubbleRadius;
  final List<String> quickReplies;

  ChatPreferences copyWith({
    bool? showAvatar,
    bool? showName,
    bool? showTime,
    bool? compact,
    bool? enterSend,
    bool? showReasoning,
    bool? narratorEnabled,
    String? additionalSystemPrompt,
    bool? worldbookEnabled,
    String? worldbookJson,
    int? bubbleStyle,
    bool? showBubbles,
    int? replyLayout,
    String? partnerName,
    String? myName,
    String? partnerAvatarPath,
    String? myAvatarPath,
    String? chatWallpaperPath,
    double? fontSize,
    double? bubbleRadius,
    List<String>? quickReplies,
  }) => ChatPreferences(
    showAvatar: showAvatar ?? this.showAvatar,
    showName: showName ?? this.showName,
    showTime: showTime ?? this.showTime,
    compact: compact ?? this.compact,
    enterSend: enterSend ?? this.enterSend,
    showReasoning: showReasoning ?? this.showReasoning,
    narratorEnabled: narratorEnabled ?? this.narratorEnabled,
    additionalSystemPrompt: additionalSystemPrompt ?? this.additionalSystemPrompt,
    worldbookEnabled: worldbookEnabled ?? this.worldbookEnabled,
    worldbookJson: worldbookJson ?? this.worldbookJson,
    bubbleStyle: bubbleStyle ?? this.bubbleStyle,
    showBubbles: showBubbles ?? this.showBubbles,
    replyLayout: replyLayout ?? this.replyLayout,
    partnerName: partnerName ?? this.partnerName,
    myName: myName ?? this.myName,
    partnerAvatarPath: partnerAvatarPath ?? this.partnerAvatarPath,
    myAvatarPath: myAvatarPath ?? this.myAvatarPath,
    chatWallpaperPath: chatWallpaperPath ?? this.chatWallpaperPath,
    fontSize: fontSize ?? this.fontSize,
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    quickReplies: quickReplies ?? this.quickReplies,
  );
}

abstract final class ChatPreferenceStore {
  static final ValueNotifier<ChatPreferences> value =
      ValueNotifier(const ChatPreferences());

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final avatarSettingMigrated = prefs.getBool('chat.avatarSettingMigrated.v1') ?? false;
    final showAvatar = avatarSettingMigrated ? (prefs.getBool('chat.showAvatar') ?? false) : false;
    if (!avatarSettingMigrated) {
      await prefs.setBool('chat.showAvatar', false);
      await prefs.setBool('chat.avatarSettingMigrated.v1', true);
    }
    value.value = ChatPreferences(
      showAvatar: showAvatar,
      showName: prefs.getBool('chat.showName') ?? true,
      showTime: prefs.getBool('chat.showTime') ?? true,
      compact: prefs.getBool('chat.compact') ?? true,
      enterSend: prefs.getBool('chat.enterSend') ?? true,
      showReasoning: prefs.getBool('chat.showReasoning') ?? true,
      narratorEnabled: prefs.getBool('chat.narratorEnabled') ?? true,
      additionalSystemPrompt: prefs.getString('chat.additionalSystemPrompt') ?? '',
      worldbookEnabled: prefs.getBool('chat.worldbookEnabled') ?? false,
      worldbookJson: prefs.getString('chat.worldbookJson') ?? '',
      bubbleStyle: (prefs.getInt('chat.bubbleStyle') ?? 0).clamp(0, 1),
      showBubbles: prefs.getBool('chat.showBubbles') ?? true,
      replyLayout: (prefs.getInt('chat.replyLayout') ?? 0).clamp(0, 1),
      partnerName: prefs.getString('chat.partnerName') ?? '宋祁',
      myName: prefs.getString('chat.myName') ?? '我',
      partnerAvatarPath: prefs.getString('chat.partnerAvatarPath'),
      myAvatarPath: prefs.getString('chat.myAvatarPath'),
      chatWallpaperPath: prefs.getString('chat.wallpaperPath'),
      fontSize: prefs.getDouble('chat.fontSize') ?? 14,
      bubbleRadius: prefs.getDouble('chat.bubbleRadius') ?? 19,
      quickReplies: prefs.getStringList('chat.quickReplies') ?? const ['在吗', '抱抱', '晚安'],
    );
  }

  static Future<void> update(ChatPreferences next) async {
    value.value = next;
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool('chat.showAvatar', next.showAvatar),
      prefs.setBool('chat.showName', next.showName),
      prefs.setBool('chat.showTime', next.showTime),
      prefs.setBool('chat.compact', next.compact),
      prefs.setBool('chat.enterSend', next.enterSend),
      prefs.setBool('chat.showReasoning', next.showReasoning),
      prefs.setBool('chat.narratorEnabled', next.narratorEnabled),
      prefs.setString('chat.additionalSystemPrompt', next.additionalSystemPrompt),
      prefs.setBool('chat.worldbookEnabled', next.worldbookEnabled),
      prefs.setString('chat.worldbookJson', next.worldbookJson),
      prefs.setInt('chat.bubbleStyle', next.bubbleStyle),
      prefs.setBool('chat.showBubbles', next.showBubbles),
      prefs.setInt('chat.replyLayout', next.replyLayout),
      prefs.setString('chat.partnerName', next.partnerName),
      prefs.setString('chat.myName', next.myName),
      if (next.partnerAvatarPath != null) prefs.setString('chat.partnerAvatarPath', next.partnerAvatarPath!) else prefs.remove('chat.partnerAvatarPath'),
      if (next.myAvatarPath != null) prefs.setString('chat.myAvatarPath', next.myAvatarPath!) else prefs.remove('chat.myAvatarPath'),
      if (next.chatWallpaperPath != null && next.chatWallpaperPath!.isNotEmpty) prefs.setString('chat.wallpaperPath', next.chatWallpaperPath!) else prefs.remove('chat.wallpaperPath'),
      prefs.setDouble('chat.fontSize', next.fontSize),
      prefs.setDouble('chat.bubbleRadius', next.bubbleRadius),
      prefs.setStringList('chat.quickReplies', next.quickReplies),
    ]);
  }
}
