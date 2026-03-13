import 'package:flutter_test/flutter_test.dart';

import 'package:sms_spike/main.dart';

void main() {
  testWidgets('renders Smart Auth spike home', (WidgetTester tester) async {
    await tester.pumpWidget(const SmsSpikeApp());

    expect(find.text('Smart Auth SMS Spike'), findsOneWidget);
    expect(find.text('Get App Signature'), findsOneWidget);
  });
}
