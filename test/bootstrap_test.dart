import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_app/bootstrap.dart';

// The startup-recovery UI must always be reachable when the database fails to
// open; these tests pin its content and its callbacks so a refactor cannot
// silently turn a recoverable failure back into a dead end.
void main() {
  testWidgets('BootSplash shows a progress indicator', (tester) async {
    await tester.pumpWidget(const BootSplash());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('BootErrorScreen explains the failure and offers recovery',
      (tester) async {
    var retried = false;
    var wiped = false;

    await tester.pumpWidget(BootErrorScreen(
      error: 'type Null is not a subtype of type int',
      onRetry: () => retried = true,
      onResetData: () => wiped = true,
    ));

    expect(find.text('تعذّر فتح البيانات المحلية'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.text('تصفير البيانات المحلية'), findsOneWidget);

    await tester.tap(find.text('إعادة المحاولة'));
    expect(retried, isTrue);

    // The destructive action must be confirmed first.
    await tester.tap(find.text('تصفير البيانات المحلية'));
    await tester.pumpAndSettle();
    expect(find.text('تصفير البيانات المحلية؟'), findsOneWidget);
    expect(wiped, isFalse, reason: 'must not wipe without confirmation');

    await tester.tap(find.text('حذف الكل'));
    await tester.pumpAndSettle();
    expect(wiped, isTrue);
  });

  testWidgets('BootErrorScreen cancel keeps the data', (tester) async {
    var wiped = false;
    await tester.pumpWidget(BootErrorScreen(
      error: 'boom',
      onRetry: () {},
      onResetData: () => wiped = true,
    ));

    await tester.tap(find.text('تصفير البيانات المحلية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();
    expect(wiped, isFalse);
  });
}
