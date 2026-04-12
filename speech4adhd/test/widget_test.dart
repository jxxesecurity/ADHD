import 'package:flutter_test/flutter_test.dart';

import 'package:my_mic/app.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyMicApp());
    // HomeScreen schedules a 400ms greeting delay — elapse it before dispose.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('myMic'), findsOneWidget);
  });
}
