import 'package:flutter_test/flutter_test.dart';

import 'package:antigravity_control_center/main.dart';

void main() {
  testWidgets('App loads without error', (WidgetTester tester) async {
    await tester.pumpWidget(const AntigravityApp());
    expect(find.byType(AntigravityApp), findsOneWidget);
  });
}
