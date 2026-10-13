import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_app/utils/input_formatters.dart';
import 'package:pomodoro_app/widgets/tas3ady_panel.dart';

// Regression anchor: number entry now uses the plain system keyboard —
// no readOnly guard, no keystroke-time formatters, no custom keypad sheet.
// Every keystroke must land immediately (typing AND deleting), on any
// device, any keyboard app and on web.
void main() {
  Future<void> pumpPanel(WidgetTester tester) async {
    // Silence platform-channel calls (haptics) inside the FakeAsync zone.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Tas3adyDhikrCalculator(isDark: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder fieldFinder(String hint) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == hint,
      );

  TextField field(WidgetTester tester, String hint) {
    expect(fieldFinder(hint), findsOneWidget);
    return tester.widget<TextField>(fieldFinder(hint));
  }

  Future<void> enterInto(WidgetTester tester, String hint, String v) async {
    await tester.enterText(fieldFinder(hint), v);
    await tester.pump();
  }

  testWidgets('number fields are plain editable (no readOnly guard)', (
    tester,
  ) async {
    await pumpPanel(tester);
    final speed = field(tester, 'مثال: 2.5');
    expect(speed.readOnly, isFalse);
    final reps = field(tester, 'مخصص');
    expect(reps.readOnly, isFalse);
    // No bottom-sheet keypad ever opens when tapping a field.
    await tester.tap(fieldFinder('مثال: 2.5'));
    await tester.pumpAndSettle();
    expect(find.text('تم'), findsNothing);
  });

  testWidgets('speed field types decimals and deletes freely', (tester) async {
    await pumpPanel(tester);
    await tester.tap(fieldFinder('مثال: 2.5'));
    await tester.pumpAndSettle();
    await enterInto(tester, 'مثال: 2.5', '0');
    expect(field(tester, 'مثال: 2.5').controller!.text, '0');
    await enterInto(tester, 'مثال: 2.5', '0.5');
    expect(field(tester, 'مثال: 2.5').controller!.text, '0.5');
    await enterInto(tester, 'مثال: 2.5', '');
    expect(field(tester, 'مثال: 2.5').controller!.text, '');
    await enterInto(tester, 'مثال: 2.5', '2.5');
    expect(field(tester, 'مثال: 2.5').controller!.text, '2.5');
  });

  testWidgets('custom reps and custom measure count accept typing and clear',
      (tester) async {
    await pumpPanel(tester);
    await enterInto(tester, 'مخصص', '250');
    expect(field(tester, 'مخصص').controller!.text, '250');
    await enterInto(tester, 'مخصص', '');
    expect(field(tester, 'مخصص').controller!.text, '');
    await enterInto(tester, 'عدد مخصص', '33');
    expect(field(tester, 'عدد مخصص').controller!.text, '33');
    await enterInto(tester, 'عدد مخصص', '');
    expect(field(tester, 'عدد مخصص').controller!.text, '');
  });

  testWidgets('minutes field accepts decimals in second mode tab', (
    tester,
  ) async {
    await pumpPanel(tester);
    await tester.tap(find.text('أقدر أذكر كام مرة؟'));
    await tester.pump();
    await enterInto(tester, 'مثال: 10', '10.5');
    expect(field(tester, 'مثال: 10').controller!.text, '10.5');
    await enterInto(tester, 'مثال: 10', '');
    expect(field(tester, 'مثال: 10').controller!.text, '');
  });

  test('parse helpers handle arabic-indic digits and both separators', () {
    expect(parseLocalizedInt('١٠٠'), 100);
    expect(parseLocalizedInt('250'), 250);
    expect(parseLocalizedDouble('2,5'), 2.5);
    expect(parseLocalizedDouble('٢.٥'), 2.5);
    expect(parseLocalizedInt('abc'), isNull);
  });
}
