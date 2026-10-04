import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_app/widgets/tas3ady_panel.dart';

// Regression: number fields must accept free typing and deletion.
// Keystroke-time input formatters used to reject intermediate states
// (e.g. a leading '0' in the speed field) and wedge the IME session on
// real Android keyboards, making fields appear completely dead — typing
// AND deleting did nothing. Validation now happens only at parse time,
// so every keystroke must land in the field.
void main() {
  Future<void> pumpPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: Tas3adyDhikrCalculator(isDark: false)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldFinder(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  Future<void> enterHint(
      WidgetTester tester, String hint, String value) async {
    expect(fieldFinder(hint), findsOneWidget);
    await tester.enterText(fieldFinder(hint), value);
    await tester.pump();
  }

  String textOf(WidgetTester tester, String hint) {
    expect(fieldFinder(hint), findsOneWidget);
    return tester.widget<TextField>(fieldFinder(hint)).controller!.text;
  }

  testWidgets('speed field accepts leading zero, decimals and deletion',
      (tester) async {
    await pumpPanel(tester);
    await enterHint(tester, 'مثال: 2.5', '0');
    expect(textOf(tester, 'مثال: 2.5'), '0');
    await enterHint(tester, 'مثال: 2.5', '0.5');
    expect(textOf(tester, 'مثال: 2.5'), '0.5');
    await enterHint(tester, 'مثال: 2.5', '');
    expect(textOf(tester, 'مثال: 2.5'), '');
    await enterHint(tester, 'مثال: 2.5', '.');
    expect(textOf(tester, 'مثال: 2.5'), '.');
    await enterHint(tester, 'مثال: 2.5', '2.5');
    expect(textOf(tester, 'مثال: 2.5'), '2.5');
  });

  testWidgets('custom reps and minutes accept typing and clear', (
    tester,
  ) async {
    await pumpPanel(tester);
    await enterHint(tester, 'مخصص', '250');
    expect(textOf(tester, 'مخصص'), '250');
    await enterHint(tester, 'مخصص', '');
    expect(textOf(tester, 'مخصص'), '');
    await tester.tap(find.text('أقدر أذكر كام مرة؟'));
    await tester.pump();
    await enterHint(tester, 'مثال: 10', '10');
    expect(textOf(tester, 'مثال: 10'), '10');
    await enterHint(tester, 'مثال: 10', '');
    expect(textOf(tester, 'مثال: 10'), '');
  });

  testWidgets('arabic-indic digits are preserved as typed', (tester) async {
    await pumpPanel(tester);
    await enterHint(tester, 'مخصص', '١٠٠');
    expect(textOf(tester, 'مخصص'), '١٠٠');
  });
}
