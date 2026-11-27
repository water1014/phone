import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_page.dart';
import '../features/chat/chat_page.dart';
import '../features/chat/chat_settings_page.dart';
import '../features/chat/chat_connection_settings_page.dart';
import 'theme/app_theme.dart';

class XiaowoApp extends StatelessWidget {
  const XiaowoApp({super.key});

  static final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatPage(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const ChatSettingsPage(),
            routes: [
              GoRoute(
                path: 'connection',
                builder: (context, state) => const ChatConnectionSettingsPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: '小窝',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      );
}
