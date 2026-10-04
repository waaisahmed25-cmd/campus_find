import 'package:flutter_test/flutter_test.dart';
import 'package:campus_find/main.dart';

void main() {
  testWidgets('CampusFind app loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusFindApp());

    expect(find.text('CampusFind'), findsWidgets);
    expect(find.text('Lost & Found Campus App'), findsOneWidget);
  });
}
