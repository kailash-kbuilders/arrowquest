import 'package:flutter_test/flutter_test.dart';
import 'package:hue_rush/main.dart';

void main() {
  testWidgets('home screen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HueRushApp());
    expect(find.text('HUE RUSH'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
