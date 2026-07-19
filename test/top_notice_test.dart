import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockalert/core/widgets/top_notice.dart';

void main() {
  testWidgets('top notice slides in and can be dismissed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => showTopNotice(
                context,
                title: 'Appointment approved',
                message: 'Your consultation is confirmed.',
                type: TopNoticeType.success,
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pumpAndSettle(const Duration(milliseconds: 350));

    expect(find.text('Appointment approved'), findsOneWidget);
    expect(find.text('Your consultation is confirmed.'), findsOneWidget);

    await tester.tap(find.byTooltip('Dismiss notification'));
    await tester.pumpAndSettle();

    expect(find.text('Appointment approved'), findsNothing);
  });

  test('technical database errors are converted to friendly copy', () {
    final message = friendlyNoticeMessage(
      Exception('DatabaseException: table bookings has no column requestedAt'),
    );

    expect(message, contains('local copy'));
    expect(message, isNot(contains('requestedAt')));
  });
}
