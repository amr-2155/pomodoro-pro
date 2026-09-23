import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'utils/app_keys.dart';
import 'utils/constants.dart';
import 'widgets/completion_overlay.dart';

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DatabaseService.darkModeNotifier,
      builder: (context, darkMode, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: DatabaseService.localeNotifier,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Pomodoro Pro',
              debugShowCheckedModeBanner: false,
              navigatorKey: appNavigatorKey,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.lightTheme(),
              darkTheme: AppTheme.darkTheme(),
              themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
              builder: (context, child) {
                return Directionality(
                  textDirection: locale.languageCode == 'ar'
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: CompletionOverlay(child: child!),
                );
              },
              home: const HomeScreen(),
            );
          },
        );
      },
    );
  }
}
