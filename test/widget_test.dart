import 'package:flutter_test/flutter_test.dart';
import 'package:quiver/main.dart';

void main() {
  testWidgets('home screen builds', (WidgetTester tester) async {
    await tester.pumpWidget(const QuiverApp());
    expect(find.text('QUIVER'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
