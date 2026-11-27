import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/home_page.dart';
import 'theme/app_theme.dart';

class XiaowoApp extends StatelessWidget {
  const XiaowoApp({super.key});

  static final _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
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
