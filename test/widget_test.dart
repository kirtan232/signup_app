import 'package:flutter_test/flutter_test.dart';

import 'package:signup_app/main.dart';

void main() {
  testWidgets('App opens on the Welcome foyer', (WidgetTester tester) async {
    await tester.pumpWidget(const HauntedMansionApp());

    expect(find.text('Enter If You Dare'), findsOneWidget);
  });
}
