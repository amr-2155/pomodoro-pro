import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/session_manager.dart';
import '../services/audio_service.dart';
import '../services/timer_service.dart';
import '../widgets/completion_celebration.dart';
import '../widgets/project_completion_overlay.dart';
import '../services/database_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/app_keys.dart';

/// Global overlay that shows the completion card on top of ANY screen.
/// Listens to SessionManager — independent of TimerScreen lifecycle.
/// Rendered above the Navigator so it also covers pushed routes.
class CompletionOverlay extends StatefulWidget {
  final Widget child;

  const CompletionOverlay({super.key, required this.child});

  @override
  State<CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<CompletionOverlay> {
  void _onDismiss() {
    print('COMPLETE|Overlay _onDismiss tapped');
    AudioService.stopCompletionLoop();
    context.read<TimerService>().stopCompletionLoop();
    context.read<SessionManager>().consume();

    // After the completion card is dismissed, check whether a project
    // weekly-goal was reached by this session and show its overlay.
    final timer = context.read<TimerService>();
    final pid = timer.pendingCompletionProjectId;
    if (pid != null) {
      final project = DatabaseService.getProject(pid);
      timer.consumeCompletion();
      final navContext = appNavigatorKey.currentContext;
      if (mounted && navContext != null && project != null) {
        ProjectCompletionOverlay.show(
          navContext,
          projectName: project.name,
          goalMinutes: project.weeklyGoalMinutes,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sm = context.watch<SessionManager>();
    final data = sm.completionData;
    if (sm.completionPending && data != null) {
      print('COMPLETE|Overlay build showing card session=${data['sessionId']}');
    }

    return Stack(
      children: [
        widget.child,
        if (sm.completionPending && data != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
        if (sm.completionPending && data != null)
          CompletionCelebration(
            sessionCount: (data['sessionCount'] as int?) ?? 0,
            isMilestone: (data['isMilestone'] as bool?) ?? false,
            quote: (data['completionQuote'] as String?) ?? '',
            quoteSource: (data['completionQuoteSource'] as String?) ?? '',
            modeLabel: _modeLabel(context, data['completedMode'] as String?),
            durationMinutes: (data['durationMinutes'] as int?) ?? 0,
            projectName: data['projectName'] as String?,
            sessionId: data['sessionId'] as String?,
            onDismiss: _onDismiss,
          ),
      ],
    );
  }

  String _modeLabel(BuildContext context, String? modeName) {
    final l10n = AppLocalizations.of(context);
    return switch (modeName) {
      'focus' => l10n.focus,
      'shortBreak' => l10n.shortBreak,
      'longBreak' => l10n.longBreak,
      'stopwatch' => l10n.stopwatch,
      _ => l10n.focus,
    };
  }
}