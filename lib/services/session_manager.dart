import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../services/database_service.dart';
import '../utils/debug_logger.dart';

/// Central authority for session completion state.
///
/// Persists completion data to Hive so it survives process death.
/// The CompletionOverlay widget listens to this and shows the card.
/// All completion paths MUST go through this manager.
class SessionManager extends ChangeNotifier {
  static const String _kCompletionPending = 'smCompletionPending';
  static const String _kCompletionDataJson = 'smCompletionDataJson';

  bool _completionPending = false;
  Map<String, dynamic>? _completionData;

  bool get completionPending => _completionPending;
  Map<String, dynamic>? get completionData => _completionData;

  /// The session ID of the last completed session (idempotency guard).
  String? _lastCompletedSessionId;

  SessionManager() {
    _restoreFromDisk();
  }

  // ─── Persistence ────────────────────────────────────────────

  void _restoreFromDisk() {
    _completionPending =
        DatabaseService.getSetting(_kCompletionPending, defaultValue: false) == true;
    final raw = DatabaseService.getSetting(_kCompletionDataJson);
    if (raw is String && raw.isNotEmpty) {
      try {
        _completionData = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        // Corrupt/truncated payload (e.g. crash mid-write): never leave the
        // app stuck with a pending completion that has no data to show.
        _completionData = null;
        _completionPending = false;
        DatabaseService.setSetting(_kCompletionPending, false);
        DatabaseService.setSetting(_kCompletionDataJson, '');
      }
    }
    _lastCompletedSessionId = _completionData?['sessionId'] as String?;
    DebugLogger.log('SM-RESTORE', 'pending=$_completionPending, data=$_completionData');
  }

  void _persist() {
    DatabaseService.setSetting(_kCompletionPending, _completionPending);
    DatabaseService.setSetting(
      _kCompletionDataJson,
      _completionData != null ? jsonEncode(_completionData!) : '',
    );
  }

  // ─── Public API ─────────────────────────────────────────────

  /// Mark a session as completed. Called by TimerService._completeSession().
  ///
  /// [sessionId] must be unique per session. If the same sessionId is
  /// passed twice, the second call is a no-op (idempotent).
  void markCompleted({
    required String sessionId,
    required String completedMode,
    required int sessionCount,
    required bool isMilestone,
    required String completionQuote,
    required String completionQuoteSource,
    required int durationMinutes,
    String? projectId,
    String? projectName,
  }) {
    if (sessionId == _lastCompletedSessionId && _completionPending) {
      DebugLogger.log('SM-COMPLETE', 'DUPLICATE ignored: sessionId=$sessionId');
      print('COMPLETE|SM markCompleted DUPLICATE ignored sessionId=$sessionId');
      return;
    }
    _completionData = {
      'sessionId': sessionId,
      'completedMode': completedMode,
      'sessionCount': sessionCount,
      'isMilestone': isMilestone,
      'completionQuote': completionQuote,
      'completionQuoteSource': completionQuoteSource,
      'durationMinutes': durationMinutes,
      'projectId': projectId,
      'projectName': projectName,
    };
    _completionPending = true;
    _lastCompletedSessionId = sessionId;
    _persist();
    DebugLogger.log('SM-COMPLETE', 'SET: sessionId=$sessionId, project=$projectName');
    print('COMPLETE|SM markCompleted SET sessionId=$sessionId '
        'mode=$completedMode project=$projectName');
    notifyListeners();
  }

  /// Consume the completion event (card was shown and dismissed).
  void consume() {
    DebugLogger.log('SM-CONSUME', 'clearing completion state');
    _completionPending = false;
    _completionData = null;
    _lastCompletedSessionId = null;
    _persist();
    notifyListeners();
  }

  /// Whether the given session was already completed (idempotency).
  bool isSessionCompleted(String sessionId) {
    return sessionId == _lastCompletedSessionId;
  }
}
