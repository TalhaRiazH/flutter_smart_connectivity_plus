import 'package:flutter_smart_connectivity_plus_example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('example loads', (tester) async {
    await tester.pumpWidget(const OfflineDemoApp());
    await tester.pump();
    expect(find.text('Smart Connectivity'), findsOneWidget);
  });
}
