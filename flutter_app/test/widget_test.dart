import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaowo/app/xiaowo_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete-frontend 首页可以进入聊天并发送消息', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(const ProviderScope(child: XiaowoApp()));
    await tester.pump();

    // 首页已按 feature/complete-frontend 改为单页 dashboard，
    // 不再显示旧版四页桌面的“小窝”标题。
    expect(find.text('宋祁 & 我'), findsOneWidget);
    expect(find.text('聊天'), findsWidgets);

    await tester.tap(find.text('聊天').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('宋祁'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '你好呀');
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // 消息会先本地显示；未配置 API 时应提示配置接口，不应导致测试失败。
    expect(find.text('你好呀'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
