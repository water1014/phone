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
    this.wallpaperScale = 1,
    this.wallpaperPositionX = 0,
    this.wallpaperPositionY = 0,
    this.fontSize = 14,
    this.bubbleRadius = 19,
    this.chatPageColor = '#FAFAFA',
    this.chatHeaderColor = '#FAFAFA',
    this.chatComposerColor = '#FAFAFA',
    this.chatInputColor = '#FFFFFF',
    this.chatBorderColor = '#E7E7E7',
    this.myBubbleColor = '#333333',
    this.partnerBubbleColor = '#FFFFFF',
    this.myTextColor = '#FFFFFF',
    this.partnerTextColor = '#222222',
    this.myBubbleOpacity = 1,
    this.partnerBubbleOpacity = 1,
    this.myBubbleImagePath = '',
    this.partnerBubbleImagePath = '',
    this.chatInputRadius = 23,
    this.chatSpacing = 9,
    this.chatWallpaperShade = .38,
    this.chatThemeName = '雾白',
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
  final double wallpaperScale;
  final double wallpaperPositionX;
  final double wallpaperPositionY;
  final double fontSize;
  final double bubbleRadius;
  final String chatPageColor;
  final String chatHeaderColor;
  final String chatComposerColor;
  final String chatInputColor;
  final String chatBorderColor;
  final String myBubbleColor;
  final String partnerBubbleColor;
  final String myTextColor;
  final String partnerTextColor;
  final double myBubbleOpacity;
  final double partnerBubbleOpacity;
  final String myBubbleImagePath;
  final String partnerBubbleImagePath;
  final double chatInputRadius;
  final double chatSpacing;
  final double chatWallpaperShade;
  final String chatThemeName;
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
    double? wallpaperScale,
    double? wallpaperPositionX,
    double? wallpaperPositionY,
    double? fontSize,
    double? bubbleRadius,
    String? chatPageColor,
    String? chatHeaderColor,
    String? chatComposerColor,
    String? chatInputColor,
    String? chatBorderColor,
    String? myBubbleColor,
    String? partnerBubbleColor,
    String? myTextColor,
    String? partnerTextColor,
    double? myBubbleOpacity,
    double? partnerBubbleOpacity,
    String? myBubbleImagePath,
    String? partnerBubbleImagePath,
    double? chatInputRadius,
    double? chatSpacing,
    double? chatWallpaperShade,
    String? chatThemeName,
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
    wallpaperScale: wallpaperScale ?? this.wallpaperScale,
    wallpaperPositionX: wallpaperPositionX ?? this.wallpaperPositionX,
    wallpaperPositionY: wallpaperPositionY ?? this.wallpaperPositionY,
    fontSize: fontSize ?? this.fontSize,
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    chatPageColor: chatPageColor ?? this.chatPageColor,
    chatHeaderColor: chatHeaderColor ?? this.chatHeaderColor,
    chatComposerColor: chatComposerColor ?? this.chatComposerColor,
    chatInputColor: chatInputColor ?? this.chatInputColor,
    chatBorderColor: chatBorderColor ?? this.chatBorderColor,
    myBubbleColor: myBubbleColor ?? this.myBubbleColor,
    partnerBubbleColor: partnerBubbleColor ?? this.partnerBubbleColor,
    myTextColor: myTextColor ?? this.myTextColor,
    partnerTextColor: partnerTextColor ?? this.partnerTextColor,
    myBubbleOpacity: myBubbleOpacity ?? this.myBubbleOpacity,
    partnerBubbleOpacity: partnerBubbleOpacity ?? this.partnerBubbleOpacity,
    myBubbleImagePath: myBubbleImagePath ?? this.myBubbleImagePath,
    partnerBubbleImagePath: partnerBubbleImagePath ?? this.partnerBubbleImagePath,
    chatInputRadius: chatInputRadius ?? this.chatInputRadius,
    chatSpacing: chatSpacing ?? this.chatSpacing,
    chatWallpaperShade: chatWallpaperShade ?? this.chatWallpaperShade,
    chatThemeName: chatThemeName ?? this.chatThemeName,
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
      wallpaperScale: prefs.getDouble('chat.wallpaperScale') ?? 1,
      wallpaperPositionX: prefs.getDouble('chat.wallpaperPositionX') ?? 0,
      wallpaperPositionY: prefs.getDouble('chat.wallpaperPositionY') ?? 0,
      fontSize: prefs.getDouble('chat.fontSize') ?? 14,
      bubbleRadius: prefs.getDouble('chat.bubbleRadius') ?? 19,
      chatPageColor: prefs.getString('chat.beauty.pageColor') ?? '#FAFAFA',
      chatHeaderColor: prefs.getString('chat.beauty.headerColor') ?? '#FAFAFA',
      chatComposerColor: prefs.getString('chat.beauty.composerColor') ?? '#FAFAFA',
      chatInputColor: prefs.getString('chat.beauty.inputColor') ?? '#FFFFFF',
      chatBorderColor: prefs.getString('chat.beauty.borderColor') ?? '#E7E7E7',
      myBubbleColor: prefs.getString('chat.beauty.myBubbleColor') ?? '#333333',
      partnerBubbleColor: prefs.getString('chat.beauty.partnerBubbleColor') ?? '#FFFFFF',
      myTextColor: prefs.getString('chat.beauty.myTextColor') ?? '#FFFFFF',
      partnerTextColor: prefs.getString('chat.beauty.partnerTextColor') ?? '#222222',
      myBubbleOpacity: prefs.getDouble('chat.beauty.myBubbleOpacity') ?? 1,
      partnerBubbleOpacity: prefs.getDouble('chat.beauty.partnerBubbleOpacity') ?? 1,
      myBubbleImagePath: prefs.getString('chat.beauty.myBubbleImagePath') ?? '',
      partnerBubbleImagePath: prefs.getString('chat.beauty.partnerBubbleImagePath') ?? '',
      chatInputRadius: prefs.getDouble('chat.beauty.inputRadius') ?? 23,
      chatSpacing: prefs.getDouble('chat.beauty.spacing') ?? 9,
      chatWallpaperShade: prefs.getDouble('chat.beauty.wallpaperShade') ?? .38,
      chatThemeName: prefs.getString('chat.beauty.themeName') ?? '雾白',
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
      prefs.setDouble('chat.wallpaperScale', next.wallpaperScale),
      prefs.setDouble('chat.wallpaperPositionX', next.wallpaperPositionX),
      prefs.setDouble('chat.wallpaperPositionY', next.wallpaperPositionY),
      prefs.setDouble('chat.fontSize', next.fontSize),
      prefs.setDouble('chat.bubbleRadius', next.bubbleRadius),
      prefs.setString('chat.beauty.pageColor', next.chatPageColor),
      prefs.setString('chat.beauty.headerColor', next.chatHeaderColor),
      prefs.setString('chat.beauty.composerColor', next.chatComposerColor),
      prefs.setString('chat.beauty.inputColor', next.chatInputColor),
      prefs.setString('chat.beauty.borderColor', next.chatBorderColor),
      prefs.setString('chat.beauty.myBubbleColor', next.myBubbleColor),
      prefs.setString('chat.beauty.partnerBubbleColor', next.partnerBubbleColor),
      prefs.setString('chat.beauty.myTextColor', next.myTextColor),
      prefs.setString('chat.beauty.partnerTextColor', next.partnerTextColor),
      prefs.setDouble('chat.beauty.myBubbleOpacity', next.myBubbleOpacity),
      prefs.setDouble('chat.beauty.partnerBubbleOpacity', next.partnerBubbleOpacity),
      prefs.setString('chat.beauty.myBubbleImagePath', next.myBubbleImagePath),
      prefs.setString('chat.beauty.partnerBubbleImagePath', next.partnerBubbleImagePath),
      prefs.setDouble('chat.beauty.inputRadius', next.chatInputRadius),
      prefs.setDouble('chat.beauty.spacing', next.chatSpacing),
      prefs.setDouble('chat.beauty.wallpaperShade', next.chatWallpaperShade),
      prefs.setString('chat.beauty.themeName', next.chatThemeName),
      prefs.setStringList('chat.quickReplies', next.quickReplies),
    ]);
  }
}
