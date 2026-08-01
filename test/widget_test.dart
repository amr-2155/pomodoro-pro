import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro_app/app.dart';
import 'package:pomodoro_app/services/timer_service.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => TimerService(),
        child: const PomodoroApp(),
      ),
    );
    expect(find.text('Timer'), findsOneWidget);
  });
}
