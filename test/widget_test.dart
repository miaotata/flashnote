import 'package:flutter_test/flutter_test.dart';

import 'package:flashnote/app.dart';

void main() {
  testWidgets('App renders main tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashNoteApp());
    await tester.pumpAndSettle();

    // 验证三个 Tab 存在
    expect(find.text('记录'), findsOneWidget);
    expect(find.text('看板'), findsOneWidget);
    expect(find.text('聚合'), findsOneWidget);
  });
}
