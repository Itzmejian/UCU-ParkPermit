import 'package:flutter_test/flutter_test.dart';
import 'package:ucu_parkpermit/main.dart';

void main() {
  testWidgets('Welcome screen is shown first', (WidgetTester tester) async {
    await tester.pumpWidget(const ParkPermitApp());
    expect(find.text('ParkPermit'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
  });
}