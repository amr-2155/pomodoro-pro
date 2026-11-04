import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/background_task_service.dart';
import 'services/database_service.dart';
import 'services/goals_service.dart';
import 'services/notification_service.dart';
import 'services/pwa_service.dart';
import 'services/session_manager.dart';
import 'services/tasbeeh_service.dart';
import 'services/timer_service.dart';
import 'utils/constants.dart';
import 'utils/debug_logger.dart';

/// Runs the one-time async startup and renders a *recoverable* error screen
/// when the local database cannot be opened.
///
/// Previously `main()` awaited `DatabaseService.init()` before `runApp`, so a
/// single unreadable box (corrupt record, failed migration, blocked IndexedDB)
/// left the user staring at a blank window with no way out short of clearing
/// site data. Now the app always renders: either the real app, or a screen
/// offering "retry" and a clearly-labelled local-data reset.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

enum _BootPhase { loading, ready, error }

class _AppBootstrapState extends State<AppBootstrap> {
  _BootPhase _phase = _BootPhase.loading;
  Object? _error;
  // Built exactly once so the providers (and the TimerService session they
  // own) are never recreated by a later rebuild.
  Widget? _app;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  /// Runs startup, then lands on either the app or the recovery screen.
  /// Never calls `setState` before the first frame, so it is safe to invoke
  /// from [initState].
  Future<void> _boot({bool wipe = false}) async {
    try {
      if (wipe) {
        DebugLogger.log('BOOT', 'user requested local-data wipe');
        await DatabaseService.wipeLocalStorage();
      }
      await _startUp();
      if (!mounted) return;
      setState(() {
        _app = _buildApp();
        _phase = _BootPhase.ready;
      });
    } catch (error) {
      DebugLogger.log('BOOT', 'startup failed: $error');
      if (!mounted) return;
      setState(() {
        _error = error;
        _phase = _BootPhase.error;
      });
    }
  }

  void _retry() {
    setState(() {
      _phase = _BootPhase.loading;
      _error = null;
    });
    _boot();
  }

  void _resetLocalData() {
    setState(() {
      _phase = _BootPhase.loading;
      _error = null;
    });
    _boot(wipe: true);
  }

  /// Only the database is allowed to abort startup; every optional subsystem
  /// is best-effort so it can never block the app from opening.
  Future<void> _startUp() async {
    await DatabaseService.init();
    try {
      await NotificationService.init();
      await NotificationService.requestPermission();
    } catch (_) {}
    try {
      await BackgroundTaskService.init();
    } catch (_) {}
    try {
      PwaService.init();
    } catch (_) {}
  }

  Widget _buildApp() {
    final sessionManager = SessionManager();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoalsService()),
        ChangeNotifierProvider.value(value: sessionManager),
        ChangeNotifierProvider(create: (_) => TimerService(sessionManager)),
        ChangeNotifierProvider(create: (_) => TasbeehService()),
      ],
      child: const PomodoroApp(),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _BootPhase.loading:
        return const BootSplash();
      case _BootPhase.error:
        return BootErrorScreen(
          error: _error ?? 'Unknown startup error',
          onRetry: _retry,
          onResetData: _resetLocalData,
        );
      case _BootPhase.ready:
        return _app!;
    }
  }
}

/// Branded loading screen shown for the (usually brief) startup window.
/// Matches the web splash background so there is no visible flash.
class BootSplash extends StatelessWidget {
  const BootSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: Color(0xFF0A0B18),
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
      ),
    );
  }
}

/// Last-resort recovery screen: explains the failure in Arabic and English,
/// offers a retry, and (behind a confirmation) the option to wipe all local
/// data — the only way out when the stored data itself is unreadable.
class BootErrorScreen extends StatelessWidget {
  BootErrorScreen({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onResetData,
  });

  final Object error;
  final VoidCallback onRetry;
  final VoidCallback onResetData;

  /// The dialog must be opened from a context *below* this widget's own
  /// [MaterialApp] (the `build` context sits above it and has no
  /// MaterialLocalizations), so we route it through the navigator.
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: AppTheme.darkTheme(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFF0A0B18),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.storage_rounded,
                          size: 56, color: AppColors.error),
                      const SizedBox(height: 16),
                      const Text(
                        'تعذّر فتح البيانات المحلية',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'حدث خطأ أثناء تشغيل قاعدة بيانات التطبيق. '
                        'يمكنك المحاولة مرة أخرى، وإن استمر الخطأ فيمكنك '
                        'تصفير البيانات المحلية (سيتم حذف الجلسات والمهام '
                        'والمشاريع والإعدادات من هذا الجهاز).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Color(0xFF8E93C4),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('إعادة المحاولة'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () {
                          final navContext = _navigatorKey.currentContext;
                          if (navContext != null) _confirmReset(navContext);
                        },
                        icon: const Icon(Icons.delete_forever_rounded, size: 18),
                        label: const Text('تصفير البيانات المحلية'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        iconColor: const Color(0xFF8E93C4),
                        collapsedIconColor: const Color(0xFF8E93C4),
                        title: const Text(
                          'تفاصيل تقنية',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8E93C4),
                          ),
                        ),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$error',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF8E93C4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text(
          'تصفير البيانات المحلية؟',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'سيتم حذف كل الجلسات والمهام والمشاريع والاقتباسات والإعدادات '
          'من هذا الجهاز نهائيًا. لا يمكن التراجع.',
          style: TextStyle(color: Color(0xFF8E93C4), height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
    if (confirmed == true) onResetData();
  }
}
