import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xiaowo/app/xiaowo_app.dart';

void main() {
  testWidgets('小窝启动并显示首页骨架', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: XiaowoApp()));
    expect(find.text('小窝'), findsOneWidget);
    expect(find.text('我们的日常'), findsOneWidget);
  });
}
