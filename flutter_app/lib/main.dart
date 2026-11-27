import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app/xiaowo_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Audio notifications are an enhancement, not a prerequisite for showing
  // the app. Some Android devices can delay or reject media-service startup.
  // Never leave the user on a blank launch screen because of that.
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.water1014.xiaowo.audio',
      androidNotificationChannelName: '小窝音乐播放',
      androidNotificationOngoing: true,
    ).timeout(const Duration(seconds: 8));
  } catch (error, stackTrace) {
    debugPrint('Audio background service initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const ProviderScope(child: XiaowoApp()));
}
