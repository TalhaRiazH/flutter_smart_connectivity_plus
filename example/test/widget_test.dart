import 'package:flutter_smart_connectivity_plus_example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('example loads', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const OfflineDemoApp());
    await tester.pump();
    expect(find.text('Smart Connectivity'), findsOneWidget);
  });
}
