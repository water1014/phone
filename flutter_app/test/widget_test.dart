import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xiaowo/app/xiaowo_app.dart';

void main() {
  testWidgets('首页可以进入聊天并发送消息', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(const ProviderScope(child: XiaowoApp()));
    expect(find.text('我们的日常'), findsOneWidget);
    await tester.tap(find.text('聊天'));
    await tester.pumpAndSettle();
    expect(find.text('宋祁'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '你好呀');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('你好呀'), findsOneWidget);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
