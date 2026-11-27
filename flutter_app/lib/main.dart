import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app/xiaowo_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.water1014.xiaowo.audio',
    androidNotificationChannelName: '小窝音乐播放',
    androidNotificationOngoing: true,
  );
  runApp(const ProviderScope(child: XiaowoApp()));
}
