import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class ChatPreferences {
  const ChatPreferences({
    this.showAvatar = true,
    this.showName = true,
    this.showTime = true,
    this.compact = true,
    this.enterSend = true,
    this.showReasoning = true,
    this.bubbleStyle = 0,
    this.partnerName = '宋祁',
    this.myName = '我',
    this.fontSize = 14,
  });

  final bool showAvatar;
  final bool showName;
  final bool showTime;
  final bool compact;
  final bool enterSend;
  final bool showReasoning;
  final int bubbleStyle;
  final String partnerName;
  final String myName;
  final double fontSize;

  ChatPreferences copyWith({
    bool? showAvatar,
    bool? showName,
    bool? showTime,
    bool? compact,
    bool? enterSend,
    bool? showReasoning,
    int? bubbleStyle,
    String? partnerName,
    String? myName,
    double? fontSize,
  }) => ChatPreferences(
    showAvatar: showAvatar ?? this.showAvatar,
    showName: showName ?? this.showName,
    showTime: showTime ?? this.showTime,
    compact: compact ?? this.compact,
    enterSend: enterSend ?? this.enterSend,
    showReasoning: showReasoning ?? this.showReasoning,
    bubbleStyle: bubbleStyle ?? this.bubbleStyle,
    partnerName: partnerName ?? this.partnerName,
    myName: myName ?? this.myName,
    fontSize: fontSize ?? this.fontSize,
  );
}

abstract final class ChatPreferenceStore {
  static final ValueNotifier<ChatPreferences> value =
      ValueNotifier(const ChatPreferences());

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    value.value = ChatPreferences(
      showAvatar: prefs.getBool('chat.showAvatar') ?? true,
      showName: prefs.getBool('chat.showName') ?? true,
      showTime: prefs.getBool('chat.showTime') ?? true,
      compact: prefs.getBool('chat.compact') ?? true,
      enterSend: prefs.getBool('chat.enterSend') ?? true,
      showReasoning: prefs.getBool('chat.showReasoning') ?? true,
      bubbleStyle: (prefs.getInt('chat.bubbleStyle') ?? 0).clamp(0, 1),
      partnerName: prefs.getString('chat.partnerName') ?? '宋祁',
      myName: prefs.getString('chat.myName') ?? '我',
      fontSize: prefs.getDouble('chat.fontSize') ?? 14,
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
      prefs.setInt('chat.bubbleStyle', next.bubbleStyle),
      prefs.setString('chat.partnerName', next.partnerName),
      prefs.setString('chat.myName', next.myName),
      prefs.setDouble('chat.fontSize', next.fontSize),
    ]);
  }
}
