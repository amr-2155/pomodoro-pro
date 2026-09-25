import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';
import 'timer_screen.dart';
import 'dhikr_screen.dart';
import 'projects_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const TimerScreen(),
    const DhikrScreen(),
    const ProjectsScreen(),
    const TasksScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) { HapticFeedback.selectionClick(); setState(() => _currentIndex = index); },
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.timer_outlined),
                  activeIcon: const Icon(Icons.timer),
                  label: l10n.timer,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.self_improvement_outlined),
                  activeIcon: const Icon(Icons.self_improvement),
                  label: l10n.dhikrCounter,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.folder_outlined),
                  activeIcon: const Icon(Icons.folder),
                  label: l10n.projects,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.checklist_outlined),
                  activeIcon: const Icon(Icons.checklist),
                  label: l10n.tasks,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.bar_chart_outlined),
                  activeIcon: const Icon(Icons.bar_chart),
                  label: l10n.stats,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.settings_outlined),
                  activeIcon: const Icon(Icons.settings),
                  label: l10n.settings,
                ),
              ],
            ),
          ),
        ),
      );
  }
}
