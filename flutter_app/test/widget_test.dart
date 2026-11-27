import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaowo/app/xiaowo_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('phone 原版桌面可以进入聊天并发送消息', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const ProviderScope(child: XiaowoApp()));

    // 验证当前 Flutter 桌面，而不是旧 Web 首页的标题。
    expect(find.text('小窝'), findsOneWidget);
    expect(find.text('聊天'), findsOneWidget);

    await tester.tap(find.text('聊天').first);
    await tester.pumpAndSettle();

    expect(find.text('宋祁'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '你好呀');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    // 消息会先本地显示；未配置 API 时应提示配置接口，不应导致测试失败。
    expect(find.text('你好呀'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
