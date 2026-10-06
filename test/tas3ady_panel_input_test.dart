import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_app/utils/input_formatters.dart';
import 'package:pomodoro_app/widgets/tas3ady_panel.dart';

// Number entry goes ONLY through the built-in keypad (fields are
// readOnly, zero IME involvement), so every test below drives the UI
// the same way a finger does: tap field -> tap keys -> read controller.
void main() {
  Future<void> pumpPanel(WidgetTester tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {});
    // Phone-like viewport so the bottom sheet fully fits on screen.
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
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

  String textOf(WidgetTester tester, String hint) {
    expect(fieldFinder(hint), findsOneWidget);
    return tester.widget<TextField>(fieldFinder(hint)).controller!.text;
  }

  Future<void> openKeypad(WidgetTester tester, String hint) async {
    await tester.tap(fieldFinder(hint));
    await tester.pumpAndSettle();
    expect(find.text('تم'), findsOneWidget);
  }

  Future<void> pressKey(WidgetTester tester, String key) async {
    final finder = find.text(key);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> closeKeypad(WidgetTester tester) async {
    await tester.tap(find.text('تم'));
    await tester.pumpAndSettle();
    expect(find.text('تم'), findsNothing);
  }

  testWidgets('keypad writes digits, decimal, backspace and clear',
      (tester) async {
    await pumpPanel(tester);
    await openKeypad(tester, 'مثال: 2.5');
    // Initial value is '3': clear first for a deterministic script.
    await pressKey(tester, 'مسح');
    expect(textOf(tester, 'مثال: 2.5'), '');
    await pressKey(tester, '0');
    expect(textOf(tester, 'مثال: 2.5'), '0');
    await pressKey(tester, '.');
    await pressKey(tester, '5');
    expect(textOf(tester, 'مثال: 2.5'), '0.5');
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(textOf(tester, 'مثال: 2.5'), '0.');
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();
    expect(textOf(tester, 'مثال: 2.5'), '0');
    await closeKeypad(tester);
  });

  testWidgets('custom reps keypad types multi-digit values', (tester) async {
    await pumpPanel(tester);
    await openKeypad(tester, 'مخصص');
    await pressKey(tester, '2');
    await pressKey(tester, '5');
    await pressKey(tester, '0');
    expect(textOf(tester, 'مخصص'), '250');
    await closeKeypad(tester);
  });

  testWidgets('minutes keypad works in second mode tab', (tester) async {
    await pumpPanel(tester);
    await tester.tap(find.text('أقدر أذكر كام مرة؟'));
    await tester.pump();
    await openKeypad(tester, 'مثال: 10');
    await pressKey(tester, '1');
    await pressKey(tester, '0');
    expect(textOf(tester, 'مثال: 10'), '10');
    await closeKeypad(tester);
  });

  test('parse helpers accept arabic-indic digits and both separators', () {
    expect(parseLocalizedInt('١٠٠'), 100);
    expect(parseLocalizedInt('250'), 250);
    expect(parseLocalizedDouble('2,5'), 2.5);
    expect(parseLocalizedDouble('٢.٥'), 2.5);
    expect(parseLocalizedInt('abc'), isNull);
  });
}
